"""Evaluation metrics for caption alignment quality: DER, JER, WER, and SCA."""

import json
import re
from pathlib import Path
from typing import List, Optional, Union

import jiwer
import pysubs2
from lattifai.alignment.tokenizer import _is_punctuation, tokenize_multilingual_text
from pyannote.core import Annotation, Segment
from pyannote.metrics.diarization import DiarizationErrorRate, JaccardErrorRate
from whisper_normalizer.basic import BasicTextNormalizer
from whisper_normalizer.english import EnglishTextNormalizer

from speaker_count_metrics import SpeakerCountAccuracy, SpeakerCountingErrorRate

english_normalizer = EnglishTextNormalizer()
basic_normalizer = BasicTextNormalizer()


def normalize_multilingual(text: str) -> str:
    """Normalize multilingual text by tokenizing and joining with spaces."""
    tokens = tokenize_multilingual_text(text, keep_spaces=False)
    tokens = [t for t in tokens if not _is_punctuation(t)]
    return " ".join(tokens).lower()


# Pattern to match [event] markers (e.g., [Laughter], [Breathes in], [Applause], [♪ Music ♪], [笑声])
# Matches any content within square brackets
EVENT_PATTERN = re.compile(r"\[[^\]]+\]")
# Pattern to match incomplete event markers (e.g., "[speaking In" without closing bracket)
# This happens when YouTube captions split event markers across lines
INCOMPLETE_EVENT_START = re.compile(r"\[[^\]]*$")
# Pattern to match trailing part of split event markers (e.g., "Italian ]" or "Italian]")
# Matches: word(s) followed by optional space and closing bracket at end of string
INCOMPLETE_EVENT_END = re.compile(r"^\w+\s*\]$")


def decode_html_entities(text: str) -> str:
    """Decode common HTML entities in text."""
    import html

    return html.unescape(text)


def is_event_only(text: str) -> bool:
    """Check if text contains only event markers (no actual speech)."""
    cleaned = remove_events(text)
    return len(cleaned) == 0


def remove_events(text: str) -> str:
    """Remove [event] markers from text, including incomplete ones.

    Handles:
    - Complete markers: [Laughter], [APPLAUSE], [speaking In Italian]
    - Split start: [speaking In (no closing bracket)
    - Split end: Italian ] or Italian] (trailing part of split marker)
    """
    # Remove complete event markers [...]
    text = EVENT_PATTERN.sub("", text)
    # Remove incomplete event markers at start [... (no closing bracket)
    text = INCOMPLETE_EVENT_START.sub("", text)
    # Remove incomplete event markers at end (e.g., "Italian ]")
    text = INCOMPLETE_EVENT_END.sub("", text)
    return text.strip()


def normalize_unicode(text: str) -> str:
    """Normalize unicode characters: fullwidth to halfwidth, smart quotes to ASCII, etc."""
    # Quote/apostrophe variants -> ASCII
    QUOTE_MAP = {
        "'": "'",  # U+2018 LEFT SINGLE QUOTATION MARK
        "'": "'",  # U+2019 RIGHT SINGLE QUOTATION MARK
        "‚": "'",  # U+201A SINGLE LOW-9 QUOTATION MARK
        "‛": "'",  # U+201B SINGLE HIGH-REVERSED-9 QUOTATION MARK
        """: '"',  # U+201C LEFT DOUBLE QUOTATION MARK
        """: '"',  # U+201D RIGHT DOUBLE QUOTATION MARK
        "„": '"',  # U+201E DOUBLE LOW-9 QUOTATION MARK
        "‟": '"',  # U+201F DOUBLE HIGH-REVERSED-9 QUOTATION MARK
        "′": "'",  # U+2032 PRIME
        "″": '"',  # U+2033 DOUBLE PRIME
    }

    result = []
    for char in text:
        # Check quote map first
        if char in QUOTE_MAP:
            result.append(QUOTE_MAP[char])
            continue

        code = ord(char)
        # Fullwidth ASCII variants (FF01-FF5E) -> ASCII (0021-007E)
        if 0xFF01 <= code <= 0xFF5E:
            result.append(chr(code - 0xFEE0))
        # Fullwidth space
        elif code == 0x3000:
            result.append(" ")
        else:
            result.append(char)
    return "".join(result)


# Alias for backward compatibility
fullwidth_to_halfwidth = normalize_unicode


def detect_language_from_path(file_path: Union[str, Path]) -> Optional[str]:
    """Detect language from dataset id in file path using datasets.json."""
    file_path = Path(file_path)
    project_dir = Path(__file__).parent
    datasets_json = project_dir / "data" / "datasets.json"

    if not datasets_json.exists():
        return None

    try:
        with open(datasets_json) as f:
            data = json.load(f)

        # Extract dataset id from path (e.g., .../OpenAI-Introducing-GPT-4o/...)
        for ds in data.get("datasets", []):
            ds_id = ds.get("id", "")
            if ds_id and ds_id in str(file_path):
                lang = ds.get("language", "en")
                # Normalize: zh-CN, zh-TW -> zh
                if lang.startswith("zh"):
                    return "zh"
                elif lang.startswith("ja"):
                    return "ja"
                return lang[:2] if len(lang) >= 2 else lang
    except (json.JSONDecodeError, KeyError):
        pass

    return None


def expand_contractions(text: str) -> str:
    """Expand English contractions to full forms for consistent comparison."""
    import re

    # Order matters: longer patterns first to avoid partial matches
    CONTRACTIONS = [
        # Negative contractions
        (r"\bwon't\b", "will not"),
        (r"\bcan't\b", "cannot"),
        (r"\bshan't\b", "shall not"),
        (r"\bn't\b", " not"),  # don't, doesn't, didn't, hasn't, haven't, etc.
        # Common contractions
        (r"\blet's\b", "let us"),
        (r"\b(\w+)'re\b", r"\1 are"),  # we're, you're, they're
        (r"\b(\w+)'ve\b", r"\1 have"),  # we've, you've, they've, I've
        (r"\b(\w+)'ll\b", r"\1 will"),  # I'll, we'll, you'll, he'll, she'll, they'll
        (r"\b(\w+)'d\b", r"\1 would"),  # I'd, we'd, you'd, he'd, she'd, they'd
        (r"\bI'm\b", "I am"),
        (r"\b(\w+)'s\b", r"\1 is"),  # he's, she's, it's, that's, what's (default to 'is')
    ]

    result = text
    for pattern, replacement in CONTRACTIONS:
        result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)
    return result


def get_speakers(annotation: Annotation) -> set:
    """Extract unique speaker labels from annotation."""
    return set(annotation.labels())


def caption_to_annotation(caption: pysubs2.SSAFile, uri: str = "default", skip_events: bool = False) -> Annotation:
    """Convert caption to pyannote Annotation for diarization metrics.

    Args:
        caption: Caption file to convert
        uri: URI identifier for the annotation
        skip_events: If True, skip entries that contain only [event] markers
    """
    annotation = Annotation(uri=uri)

    speaker = None
    for event in caption.events:
        # Skip event-only entries if requested
        if skip_events and is_event_only(event.text):
            continue

        segment = Segment(event.start / 1000.0, event.end / 1000.0)
        if event.name:
            # Normalize speaker name: fullwidth to halfwidth, strip punctuation
            name = fullwidth_to_halfwidth(event.name)
            name = name.rstrip(":").lstrip(">").strip()
            speaker = name

        annotation[segment] = speaker

    return annotation


def caption_to_text(
    caption: pysubs2.SSAFile,
    skip_events: bool = False,
    language: str = "en",
) -> str:
    """Convert caption to text string for WER calculation.

    Args:
        caption: Caption file to convert
        skip_events: If True, remove [event] markers and skip event-only entries
        language: Language code (en for English, others use multilingual tokenizer)
    """
    texts = []
    for event in caption.events:
        text = decode_html_entities(event.text)  # Decode &gt; &lt; &amp; etc.
        text = fullwidth_to_halfwidth(text)  # Normalize fullwidth chars
        text = text.replace("\\N", " ")  # ASS newline -> space
        text = text.replace("\\n", " ")  # SRT newline -> space
        text = text.replace("...", " ").strip()
        if skip_events:
            # Skip event-only entries
            if is_event_only(text):
                continue
            # Remove [event] markers from text
            text = remove_events(text)
        if text:
            text = expand_contractions(text)
            if language == "en":
                normalized = english_normalizer(text).replace("chatgpt", "chat gpt")
            else:
                # Use multilingual tokenizer for Chinese and other languages
                normalized = normalize_multilingual(text)
            texts.append(normalized)
    return " ".join(texts)


def _print_der_errors(der_metric, ref_ann, hyp_ann, reference, hypothesis, hypothesis_file, collar, skip_events):
    """Print detailed DER error segments and write debug TextGrid.

    Replicates pyannote's exact DER pipeline:
      DiarizationErrorRate.compute_components → uemify → rename → optimal_mapping
      IdentificationErrorRate.compute_components → uemify(returns_timeline) → matcher_ loop
    Per-segment errors are recorded from this loop, guaranteeing matching totals.
    """
    import sys
    import warnings

    from tgt import Interval, IntervalTier, TextGrid, write_to_file

    # === Replicate DiarizationErrorRate.compute_components exactly ===
    # Step 1: uemify with collar (removes ±collar/2 around ref boundaries)
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        collared_ref, collared_hyp, extruded_uem = der_metric.uemify(
            ref_ann, hyp_ann, uem=None, collar=collar,
            skip_overlap=der_metric.skip_overlap, returns_uem=True,
        )

    # Step 2: Rename labels exactly like pyannote does internally
    ref_renamed = collared_ref.rename_labels(generator="string")
    hyp_renamed = collared_hyp.rename_labels(generator="int")

    # Step 3: Optimal mapping on renamed collared annotations
    internal_mapping = der_metric.optimal_mapping(ref_renamed, hyp_renamed)
    mapped_renamed = hyp_renamed.rename_labels(mapping=internal_mapping)

    # Step 4: Get projected annotations + common timeline
    # (IdentificationErrorRate.compute_components with collar=0)
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        R, H, common_timeline = der_metric.uemify(
            ref_renamed, mapped_renamed, uem=extruded_uem,
            collar=0.0, skip_overlap=False, returns_timeline=True,
        )

    # Build reverse label map: renamed ("A","B") → original ref labels
    ref_label_map = {}
    for (_, _, orig), (_, _, renamed) in zip(
        collared_ref.itertracks(yield_label=True),
        ref_renamed.itertracks(yield_label=True),
    ):
        if renamed not in ref_label_map:
            ref_label_map[renamed] = orig

    # Human-readable mapping for display (hyp_original → ref_original)
    display_mapping = {}
    hyp_label_map = {}
    for (_, _, orig), (_, _, renamed) in zip(
        collared_hyp.itertracks(yield_label=True),
        hyp_renamed.itertracks(yield_label=True),
    ):
        if renamed not in hyp_label_map:
            hyp_label_map[renamed] = orig
    for hyp_int, ref_str in internal_mapping.items():
        hyp_orig = hyp_label_map.get(hyp_int, str(hyp_int))
        ref_orig = ref_label_map.get(ref_str, str(ref_str))
        display_mapping[hyp_orig] = ref_orig

    # Step 5: Iterate over common timeline — exact same loop as pyannote
    error_segments = []
    fa_dur = miss_dur = conf_dur = 0.0

    for segment in common_timeline:
        dur = segment.duration
        r_labels = R.get_labels(segment, unique=False)
        h_labels = H.get_labels(segment, unique=False)
        counts, _ = der_metric.matcher_(r_labels, h_labels)

        fa = counts["false alarm"] * dur
        miss = counts["missed detection"] * dur
        conf = counts["confusion"] * dur

        if fa > 1e-6 or miss > 1e-6 or conf > 1e-6:
            # Map renamed labels back to originals for display
            r_orig = tuple(sorted(ref_label_map.get(l, str(l)) for l in r_labels))
            h_orig = tuple(sorted(ref_label_map.get(l, str(l)) for l in h_labels))
            error_segments.append((segment.start, segment.end, r_orig, h_orig, fa, miss, conf))
            fa_dur += fa
            miss_dur += miss
            conf_dur += conf

    # Merge adjacent error segments with same labels
    merged = []
    for start, end, rl, hl, fa, miss, conf in error_segments:
        if (merged and merged[-1][2] == rl and merged[-1][3] == hl
                and abs(merged[-1][1] - start) < 0.01):
            m = merged[-1]
            merged[-1] = (m[0], end, rl, hl, m[4] + fa, m[5] + miss, m[6] + conf)
        else:
            merged.append([start, end, rl, hl, fa, miss, conf])

    if not merged:
        print("\nDER Error Details: no errors found", file=sys.stderr)
        return

    # Build hyp text lookup for context
    hyp_text_map = []
    for event in hypothesis.events:
        if skip_events and is_event_only(event.text):
            continue
        hyp_text_map.append((event.start / 1000.0, event.end / 1000.0, event.name or "", event.text))

    def _find_hyp_text(start, end):
        texts = []
        for hs, he, name, text in hyp_text_map:
            if hs < end and he > start:
                texts.append(f"{name} {text}" if name else text)
        return " | ".join(texts) if texts else ""

    # Print errors — durations match DER components by construction
    print(f"\n=== DER Error Segments (collar={collar}s) ===", file=sys.stderr)
    print(f"Speaker mapping: {display_mapping}", file=sys.stderr)
    print(
        f"\n{'Time':>20}  {'Type':<5}  {'Ref':<20}  {'Hyp':<20}  {'Dur':>6}  Text",
        file=sys.stderr,
    )
    print("-" * 100, file=sys.stderr)

    for start, end, rl, hl, fa, miss, conf in merged:
        dur = end - start
        ref_str = ",".join(rl) if rl else "-"
        hyp_str = ",".join(hl) if hl else "-"

        if miss > 1e-6 and fa < 1e-6 and conf < 1e-6:
            etype = "MISS"
        elif fa > 1e-6 and miss < 1e-6 and conf < 1e-6:
            etype = "FA"
        elif conf > 1e-6 and fa < 1e-6 and miss < 1e-6:
            etype = "CONF"
        else:
            etype = "MIX"

        text = _find_hyp_text(start, end)
        print(
            f"[{start:7.2f}-{end:7.2f}]  {etype:<5}  {ref_str:<20}  {hyp_str:<20}  {dur:5.2f}s  {text[:60]}",
            file=sys.stderr,
        )

    total_err = fa_dur + miss_dur + conf_dur
    print(f"\nDER Error Summary: FA={fa_dur:.2f}s  MISS={miss_dur:.2f}s  CONF={conf_dur:.2f}s  total={total_err:.2f}s", file=sys.stderr)
    print(f"Error count: {len(merged)} segments\n", file=sys.stderr)

    # === Write debug TextGrid ===
    # Raw annotations for visual context; error tier from pyannote's pipeline
    mapped_hyp = hyp_ann.rename_labels(mapping=display_mapping)
    raw_boundaries = set()
    for seg in ref_ann.itersegments():
        raw_boundaries.add(seg.start)
        raw_boundaries.add(seg.end)
    for seg in mapped_hyp.itersegments():
        raw_boundaries.add(seg.start)
        raw_boundaries.add(seg.end)
    duration = max(raw_boundaries) if raw_boundaries else 0.0

    tg = TextGrid()

    def _ann_to_tiers(ann, prefix, target_tg):
        by_speaker = {}
        for seg, track, label in ann.itertracks(yield_label=True):
            by_speaker.setdefault(label or "unknown", []).append(Interval(seg.start, seg.end, label or ""))
        for spk in sorted(by_speaker):
            target_tg.add_tier(IntervalTier(start_time=0, end_time=duration, name=f"{prefix}_{spk}", objects=by_speaker[spk]))

    _ann_to_tiers(ref_ann, "ref", tg)

    def _caption_to_tiers(caption, prefix, target_tg):
        layers = []
        for event in caption.events:
            if skip_events and is_event_only(event.text):
                continue
            iv = Interval(event.start / 1000.0, event.end / 1000.0, event.text)
            placed = False
            for layer in layers:
                if not layer or layer[-1].end_time <= iv.start_time:
                    layer.append(iv)
                    placed = True
                    break
            if not placed:
                layers.append([iv])
        for i, layer in enumerate(layers):
            name = prefix if i == 0 else f"{prefix}_{i + 1}"
            target_tg.add_tier(IntervalTier(start_time=0, end_time=duration, name=name, objects=layer))

    _caption_to_tiers(reference, "ref_text", tg)
    _ann_to_tiers(mapped_hyp, "hyp", tg)
    _caption_to_tiers(hypothesis, "hyp_text", tg)

    # Error tier
    err_ivs = []
    for start, end, rl, hl, fa, miss, conf in merged:
        dur = end - start
        ref_str = ",".join(rl) if rl else "-"
        hyp_str = ",".join(hl) if hl else "-"
        if miss > 1e-6 and fa < 1e-6 and conf < 1e-6:
            label = f"MISS {dur:.2f}s ref={ref_str}"
        elif fa > 1e-6 and miss < 1e-6 and conf < 1e-6:
            label = f"FA {dur:.2f}s hyp={hyp_str}"
        elif conf > 1e-6 and fa < 1e-6 and miss < 1e-6:
            label = f"CONF {dur:.2f}s ref={ref_str} hyp={hyp_str}"
        else:
            label = f"MIX {dur:.2f}s fa={fa:.2f} miss={miss:.2f} conf={conf:.2f}"
        err_ivs.append(Interval(start, end, label))
    tg.add_tier(IntervalTier(start_time=0, end_time=duration, name="error", objects=err_ivs))

    collar_str = f"{collar:.2f}".replace(".", "_")
    out_path = Path(hypothesis_file).with_suffix(f".der_collar{collar_str}.TextGrid")
    write_to_file(tg, str(out_path), format="long")
    print(f"DER debug TextGrid: {out_path}", file=sys.stderr)

    # Per-error-type TextGrids (FA / MISS / CONF)
    type_groups = {"FA": [], "MISS": [], "CONF": []}
    for item in merged:
        start, end, rl, hl, fa, miss, conf = item
        if miss > 1e-6 and fa < 1e-6 and conf < 1e-6:
            type_groups["MISS"].append(item)
        elif fa > 1e-6 and miss < 1e-6 and conf < 1e-6:
            type_groups["FA"].append(item)
        elif conf > 1e-6 and fa < 1e-6 and miss < 1e-6:
            type_groups["CONF"].append(item)
        else:
            type_groups["FA"].append(item)
            type_groups["MISS"].append(item)
            type_groups["CONF"].append(item)

    for etype, items in type_groups.items():
        if not items:
            continue
        etg = TextGrid()
        for tier in tg.tiers:
            if tier.name.startswith(("ref", "hyp")):
                etg.add_tier(tier)
        eivs = []
        for start, end, rl, hl, fa, miss, conf in items:
            dur = end - start
            ref_str = ",".join(rl) if rl else "-"
            hyp_str = ",".join(hl) if hl else "-"
            if etype == "FA":
                label = f"FA {dur:.2f}s hyp={hyp_str}"
            elif etype == "MISS":
                label = f"MISS {dur:.2f}s ref={ref_str}"
            else:
                label = f"CONF {dur:.2f}s ref={ref_str} hyp={hyp_str}"
            eivs.append(Interval(start, end, label))
        etg.add_tier(IntervalTier(start_time=0, end_time=duration, name=etype, objects=eivs))
        epath = Path(hypothesis_file).with_suffix(f".der_collar{collar_str}_{etype}.TextGrid")
        write_to_file(etg, str(epath), format="long")
        print(f"DER {etype} TextGrid: {epath}", file=sys.stderr)


def evaluate_alignment(
    reference_file: Union[str, Path],
    hypothesis_file: Union[str, Path],
    metrics: List[str] = ["der", "jer", "wer", "sca", "scer"],
    collar: float = 0.2,
    skip_overlap: bool = False,
    skip_events: bool = False,
    language: str = "en",
    verbose: bool = False,
) -> dict:
    """Evaluate alignment quality using specified metrics.

    Args:
        reference_file: Path to reference caption file
        hypothesis_file: Path to hypothesis caption file
        metrics: List of metrics to compute (der, jer, wer, sca, scer)
        collar: Collar size in seconds for diarization metrics
        skip_overlap: Skip overlapping speech regions for DER
        skip_events: Skip [event] markers (e.g., [Laughter], [Applause])
        language: Language code (en for English, zh for Chinese, etc.)

    Returns:
        Dictionary mapping metric names to values
    """
    reference = pysubs2.load(reference_file)
    hypothesis = pysubs2.load(hypothesis_file)

    ref_ann = caption_to_annotation(reference, skip_events=skip_events)
    hyp_ann = caption_to_annotation(hypothesis, skip_events=skip_events)
    ref_text = caption_to_text(reference, skip_events=skip_events, language=language)
    hyp_text = caption_to_text(hypothesis, skip_events=skip_events, language=language)

    if False:
        with open(hypothesis_file[:-4] + ".txt", "w") as f:
            words = hyp_text.split()
            for word in words:
                f.write(word + "\n")

    # Perform detailed text alignment analysis
    if verbose:  # Enable for debugging alignment issues
        from kaldialign import align as kaldi_align

        # Normalize function for verbose output (same as WER calculation)
        def normalize_for_compare(text: str) -> str:
            text = normalize_unicode(text)
            text = expand_contractions(text)
            if language == "en":
                return english_normalizer(text).replace("chatgpt", "chat gpt")
            else:
                return normalize_multilingual(text)

        # Filter out event-only entries for verbose analysis if skip_events is True
        if skip_events:
            ref_events = [e for e in reference.events if not is_event_only(e.text)]
            hyp_events = [e for e in hypothesis.events if not is_event_only(e.text)]
            ref_sentences = [normalize_for_compare(remove_events(event.text)) for event in ref_events]
            hyp_sentences = [normalize_for_compare(remove_events(event.text)) for event in hyp_events]
        else:
            ref_events = reference.events
            hyp_events = hypothesis.events
            ref_sentences = [normalize_for_compare(event.text) for event in ref_events]
            hyp_sentences = [normalize_for_compare(event.text) for event in hyp_events]
        ref_timelines = [(event.start / 1000.0, event.end / 1000.0) for event in ref_events]
        hyp_timelines = [(event.start / 1000.0, event.end / 1000.0) for event in hyp_events]

        sent_symbol = "❅"
        eps_symbol = "-"
        alignments = kaldi_align(
            sent_symbol.join(ref_sentences), sent_symbol.join(hyp_sentences), eps_symbol, sclite_mode=True
        )

        idx = 0
        rstart, hstart = 0, 0
        rend, hend = 0, 0
        for k, ali in enumerate(alignments):
            ref_sym, hyp_sym = ali
            if ref_sym == sent_symbol:
                rend += 1
            if hyp_sym == sent_symbol:
                hend += 1

            if ref_sym == sent_symbol and hyp_sym == sent_symbol:
                isdiff = any(_ali[0].lower() != _ali[1].lower() for _ali in alignments[idx:k])
                if isdiff:
                    # fmt: off
                    print(f"[{ref_timelines[rstart][0]:.2f}, {ref_timelines[rend - 1][1]:.2f}] REF: {''.join(_ali[0] for _ali in alignments[idx:k])}")  # noqa: E501
                    print(f"[{hyp_timelines[hstart][0]:.2f}, {hyp_timelines[hend - 1][1]:.2f}] HYP: {''.join(_ali[1] for _ali in alignments[idx:k])}\n")  # noqa: E501
                    # fmt: on

                idx = k + 1
                rstart = rend
                hstart = hend
    results = {}

    # Collect speaker info for SCA/SCER analysis
    ref_speakers = get_speakers(ref_ann)
    hyp_speakers = get_speakers(hyp_ann)

    for metric in metrics:
        metric_lower = metric.lower()
        if metric_lower == "der":
            der_metric = DiarizationErrorRate(collar=collar, skip_overlap=skip_overlap)
            results["der"] = der_metric(ref_ann, hyp_ann, detailed=True, uem=None)
            if verbose:
                _print_der_errors(der_metric, ref_ann, hyp_ann, reference, hypothesis, hypothesis_file, collar, skip_events)
        elif metric_lower == "jer":
            jer_metric = JaccardErrorRate(collar=collar)
            results["jer"] = jer_metric(ref_ann, hyp_ann)
        elif metric_lower == "wer":
            results["wer"] = jiwer.wer(ref_text, hyp_text)
        elif metric_lower == "sca":
            sca_metric = SpeakerCountAccuracy()
            results["sca"] = sca_metric(ref_ann, hyp_ann)
        elif metric_lower == "scer":
            scer_metric = SpeakerCountingErrorRate()
            results["scer"] = scer_metric(ref_ann, hyp_ann)
        else:
            raise ValueError(f"Unknown metric: {metric}. Supported: der, jer, wer, sca, scer")

    # Add speaker diff info
    results["_ref_speakers"] = ref_speakers
    results["_hyp_speakers"] = hyp_speakers

    return results


def main():
    """CLI for evaluation metrics."""
    import argparse
    import json
    import sys

    parser = argparse.ArgumentParser(
        description="Evaluate caption alignment quality",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python eval.py -r ref.ass -hyp hyp.ass
  python eval.py -r ref.ass -hyp hyp.ass -m wer
  python eval.py -r ref.ass -hyp hyp.ass -m der jer sca -c 0.25
  python eval.py -r ref.ass -hyp hyp.ass -f json
        """,
    )

    parser.add_argument("--reference", "-r", required=True, help="Reference caption file")
    parser.add_argument("--hypothesis", "-hyp", required=True, help="Hypothesis caption file")
    parser.add_argument("--model-name", "--model_name", "-n", default="", help="Model name to display in results")
    parser.add_argument(
        "--metrics",
        "-m",
        nargs="+",
        default=["der", "jer", "wer", "sca", "scer"],
        choices=["der", "jer", "wer", "sca", "scer"],
        help="Metrics to compute",
    )
    parser.add_argument("--collar", "-c", type=float, default=0.2, help="Collar size in seconds (default: 200ms)")
    parser.add_argument("--skip-overlap", action="store_true", help="Skip overlapping speech for DER")
    parser.add_argument(
        "--skip-events", action="store_true", help="Skip [event] markers (e.g., [Laughter], [Applause])"
    )
    parser.add_argument(
        "--language",
        "-l",
        default="auto",
        help="Language code (en, zh, ja) or 'auto' to detect from datasets.json. Default: auto",
    )
    parser.add_argument("--format", "-f", choices=["text", "json"], default="text", help="Output format")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    if not Path(args.reference).exists():
        print(f"Error: Reference file not found: {args.reference}", file=sys.stderr)
        sys.exit(1)

    if not Path(args.hypothesis).exists():
        print(f"Error: Hypothesis file not found: {args.hypothesis}", file=sys.stderr)
        sys.exit(1)

    # Auto-detect language from dataset id in path
    language = args.language
    if language == "auto":
        detected = detect_language_from_path(args.reference) or detect_language_from_path(args.hypothesis)
        language = detected if detected else "en"
        if args.verbose:
            print(f"Auto-detected language: {language}", file=sys.stderr)

    if args.verbose:
        print(f"Reference: {args.reference}", file=sys.stderr)
        print(f"Hypothesis: {args.hypothesis}", file=sys.stderr)
        print(f"Metrics: {', '.join(args.metrics)}", file=sys.stderr)
        print(f"Language: {language}", file=sys.stderr)
        print(f"Collar: {args.collar}s\n", file=sys.stderr)

    results = evaluate_alignment(
        reference_file=args.reference,
        hypothesis_file=args.hypothesis,
        metrics=args.metrics,
        collar=args.collar,
        skip_overlap=args.skip_overlap,
        skip_events=args.skip_events,
        language=language,
        verbose=args.verbose,
    )

    # Extract speaker info first (before any output)
    ref_speakers = results.pop("_ref_speakers", set())
    hyp_speakers = results.pop("_hyp_speakers", set())

    if args.format == "json":
        print(json.dumps(results, indent=2))
    else:
        # Extract detailed DER if present
        for metric, value in results.items():
            if not isinstance(value, float):
                assert metric == "der", f"Detailed output only supported for DER, got: {metric}"

                model_display = args.model_name if args.model_name else "-"
                print("\nDetailed DER Components:")

                # Build header and values with custom order
                sorted_items = sorted(value.items(), key=lambda x: x[0])

                # Define the desired column order
                column_order = [
                    "diarization error rate",
                    "false alarm",
                    "missed detection",
                    "confusion",
                    "correct",
                    "total",
                ]

                # Reorder items according to column_order
                ordered_items = []
                value_dict = dict(sorted_items)
                for key in column_order:
                    if key in value_dict:
                        ordered_items.append((key, value_dict[key]))

                header = ["Model"] + [
                    "DER" if key == "diarization error rate" else f"{key} (s)" for key, _ in ordered_items
                ]
                values = [model_display] + [f"{val:.4f}" for _, val in ordered_items]

                # Print table
                print("Metric Details:")
                print("| " + " | ".join(header) + " |")
                print("|" + "|".join(["--------"] * len(header)) + "|")
                print("| " + " | ".join(values) + " |")
                print()

                value = value["diarization error rate"]
                results[metric] = value

        # Display in markdown-friendly format
        metric_names = ["Model"]
        metric_values = [args.model_name if args.model_name else "-"]
        for metric, value in results.items():
            arrow = "↓" if metric.lower() in ["der", "jer", "wer", "scer"] else "↑"
            metric_names.append(f"{metric.upper()} {arrow}")
            metric_values.append(f"{value:.4f} ({value * 100:5.2f}%)")

        print("| " + " | ".join(metric_names) + " |")
        print("|" + "|".join(["--------"] * len(metric_names)) + "|")
        print("| " + " | ".join(metric_values) + " |")

        # Show speaker diff if SCA != 1 or SCER != 0
        sca_val = results.get("sca", 1.0)
        scer_val = results.get("scer", 0.0)
        if sca_val != 1.0 or scer_val != 0.0:
            # Filter out None values
            ref_speakers = {s for s in ref_speakers if s is not None}
            hyp_speakers = {s for s in hyp_speakers if s is not None}
            missing = ref_speakers - hyp_speakers
            extra = hyp_speakers - ref_speakers
            if missing or extra:
                print("\nSpeaker Diff:")
                if missing:
                    print(f"  Missing: {', '.join(sorted(missing))}")
                if extra:
                    print(f"  Extra:   {', '.join(sorted(extra))}")


if __name__ == "__main__":
    main()
