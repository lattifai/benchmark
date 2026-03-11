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


def _compute_overlap_stats(ref_ann, hyp_ann):
    """Compute overlap detection statistics between reference and hypothesis."""
    ref_tl = ref_ann.get_timeline()
    hyp_tl = hyp_ann.get_timeline()
    ref_ovl = ref_ann.get_overlap()
    hyp_ovl = hyp_ann.get_overlap()

    ref_total = ref_tl.duration()
    ref_ovl_dur = ref_ovl.duration()
    hyp_ovl_dur = hyp_ovl.duration()

    # Overlap detection precision/recall via timeline intersection
    intersection = ref_ovl.crop(hyp_ovl)
    inter_dur = intersection.duration()

    precision = inter_dur / hyp_ovl_dur if hyp_ovl_dur > 0 else 0.0
    recall = inter_dur / ref_ovl_dur if ref_ovl_dur > 0 else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0.0

    return {
        "ref_total_duration": ref_total,
        "ref_overlap_duration": ref_ovl_dur,
        "ref_overlap_pct": ref_ovl_dur / ref_total * 100 if ref_total > 0 else 0,
        "hyp_overlap_duration": hyp_ovl_dur,
        "hyp_overlap_pct": hyp_ovl_dur / hyp_tl.duration() * 100 if hyp_tl.duration() > 0 else 0,
        "overlap_precision": precision,
        "overlap_recall": recall,
        "overlap_f1": f1,
    }


def _compute_overlap_der(ref_ann, hyp_ann, collar):
    """Compute DER separately for overlap and non-overlap regions."""
    ref_ovl = ref_ann.get_overlap()
    if ref_ovl.duration() == 0:
        return {"overlap_der": None, "non_overlap_der": None}

    # Overlap-only DER
    ovl_der = DiarizationErrorRate(collar=collar)
    ovl_ref = ref_ann.crop(ref_ovl)
    ovl_hyp = hyp_ann.crop(ref_ovl)
    overlap_der_val = ovl_der(ovl_ref, ovl_hyp)

    # Non-overlap DER
    non_ovl_tl = ref_ann.get_timeline().extrude(ref_ovl)
    non_ovl_der = DiarizationErrorRate(collar=collar)
    non_ovl_ref = ref_ann.crop(non_ovl_tl)
    non_ovl_hyp = hyp_ann.crop(non_ovl_tl)
    non_overlap_der_val = non_ovl_der(non_ovl_ref, non_ovl_hyp)

    return {"overlap_der": overlap_der_val, "non_overlap_der": non_overlap_der_val}


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


def _normalize_speaker_name(name: str) -> str:
    """Normalize speaker name for fuzzy matching.

    Strips numbering suffixes like "(1)", "(2)", trailing digits after space.
    Does NOT strip digits from ID-style names like "SPEAKER_01".
    Returns lowercase canonical form.
    """
    import re

    n = name.strip()
    # Remove parenthesized numbering: "GPT-4o (1)" -> "GPT-4o"
    n = re.sub(r"\s*\(\d+\)\s*$", "", n)
    # Remove trailing digits only if preceded by a letter (not underscore/digit)
    # "ChatGPT0" -> "ChatGPT", but "SPEAKER_01" stays "SPEAKER_01"
    # "Astra User2" -> "Astra User", but "SPEAKER_02" stays
    n = re.sub(r"(?<=[a-zA-Z])\d+$", "", n)
    n = n.strip()
    return n.lower()


def merge_speaker_aliases(ref_ann: Annotation, hyp_ann: Annotation) -> tuple:
    """Merge speaker aliases within each annotation before DER computation.

    Within each side (ref or hyp), speakers whose normalized names match
    (case-insensitive, stripped numbering suffixes like "(1)", trailing digits)
    are merged into one canonical label.

    Examples:
      "GPT-4o (1)" + "GPT-4o (2)" -> "GPT-4o"
      "ChatGPT0" + "ChatGPT" -> "ChatGPT"
      "Astra User1" + "Astra User2" -> "Astra User1"

    No cross-side merging is done — that's left to pyannote's optimal_mapping.

    Returns (merged_ref, merged_hyp, ref_merge_map, hyp_merge_map).
    """

    def _build_merge_map(labels):
        norm_to_canonical = {}
        merge_map = {}
        # Replace None labels (single unnamed speaker) with "SPEAKER"
        clean_labels = [x if x is not None else "SPEAKER" for x in labels]
        for label in sorted(set(clean_labels)):
            norm = _normalize_speaker_name(label)
            if norm in norm_to_canonical:
                merge_map[label] = norm_to_canonical[norm]
            else:
                norm_to_canonical[norm] = label
                merge_map[label] = label
        # Map None to the same target as its replacement
        if None in labels:
            merge_map[None] = merge_map.get("SPEAKER", "SPEAKER")
        return merge_map

    ref_map = _build_merge_map(ref_ann.labels())
    hyp_map = _build_merge_map(hyp_ann.labels())

    # Cross-side first-name matching: if HYP has "Mark" and REF has "Mark Chen",
    # rename HYP's "Mark" to "Mark Chen" so optimal_mapping can match them.
    # Only matches single-word names that are the first word of a multi-word name.
    ref_canonical = set(ref_map.values())
    hyp_canonical = set(hyp_map.values())
    for hyp_label in list(hyp_canonical):
        if hyp_label in ref_canonical:
            continue  # Already an exact match
        hyp_words = hyp_label.split()
        if len(hyp_words) != 1:
            continue  # Only match single-word HYP names
        for ref_label in ref_canonical:
            ref_words = ref_label.split()
            if len(ref_words) > 1 and ref_words[0].lower() == hyp_words[0].lower():
                # "Mark" matches "Mark Chen" — rename in hyp_map
                for k, v in hyp_map.items():
                    if v == hyp_label:
                        hyp_map[k] = ref_label
                break

    merged_ref = ref_ann.rename_labels(mapping=ref_map)
    merged_hyp = hyp_ann.rename_labels(mapping=hyp_map)

    return merged_ref, merged_hyp, ref_map, hyp_map


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


def _fmt_ts(seconds: float) -> str:
    """Format seconds to caption timestamp HH:MM:SS.mmm"""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = seconds % 60
    return f"{h:02d}:{m:02d}:{s:06.3f}"


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
            ref_ann,
            hyp_ann,
            uem=None,
            collar=collar,
            skip_overlap=der_metric.skip_overlap,
            returns_uem=True,
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
            ref_renamed,
            mapped_renamed,
            uem=extruded_uem,
            collar=0.0,
            skip_overlap=False,
            returns_timeline=True,
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
    # Build reverse map: H label space (ref_renamed strings) → original hyp labels
    # H labels are in ref_renamed space because of optimal_mapping (hyp_int → ref_str)
    h_to_hyp_orig = {}
    for hyp_int, ref_str in internal_mapping.items():
        h_to_hyp_orig[ref_str] = hyp_label_map.get(hyp_int, str(hyp_int))

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
            r_orig = tuple(sorted(ref_label_map.get(s, str(s)) for s in r_labels))
            h_orig = tuple(sorted(h_to_hyp_orig.get(s, hyp_label_map.get(s, str(s))) for s in h_labels))
            error_segments.append((segment.start, segment.end, r_orig, h_orig, fa, miss, conf))
            fa_dur += fa
            miss_dur += miss
            conf_dur += conf

    # Merge adjacent error segments with same labels
    merged = []
    for start, end, rl, hl, fa, miss, conf in error_segments:
        if merged and merged[-1][2] == rl and merged[-1][3] == hl and abs(merged[-1][1] - start) < 0.01:
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
        f"\n{'Time':>20}  {'Caption Time':>27}  {'Type':<5}  {'Ref':<20}  {'Hyp':<20}  {'Dur':>6}  Text",
        file=sys.stderr,
    )
    print("-" * 130, file=sys.stderr)

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
            f"[{start:7.2f}-{end:7.2f}]  {_fmt_ts(start)}-{_fmt_ts(end)}  {etype:<5}  {ref_str:<20}  {hyp_str:<20}  {dur:5.2f}s  {text[:60]}",
            file=sys.stderr,
        )

    total_err = fa_dur + miss_dur + conf_dur
    print(
        f"\nDER Error Summary: FA={fa_dur:.2f}s  MISS={miss_dur:.2f}s  CONF={conf_dur:.2f}s  total={total_err:.2f}s",
        file=sys.stderr,
    )
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
            intervals = by_speaker[spk]
            # Split overlapping intervals into layers
            layers = []
            for iv in intervals:
                placed = False
                for layer in layers:
                    if not layer or layer[-1].end_time <= iv.start_time:
                        layer.append(iv)
                        placed = True
                        break
                if not placed:
                    layers.append([iv])
            for i, layer in enumerate(layers):
                name = f"{prefix}_{spk}" if i == 0 else f"{prefix}_{spk}_{i + 1}"
                target_tg.add_tier(IntervalTier(start_time=0, end_time=duration, name=name, objects=layer))

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

    # Overlap tiers: mark overlap regions in ref and hyp
    ref_ovl = ref_ann.get_overlap()
    hyp_ovl = hyp_ann.get_overlap()
    ref_ovl_ivs = [Interval(seg.start, seg.end, "overlap") for seg in ref_ovl]
    hyp_ovl_ivs = [Interval(seg.start, seg.end, "overlap") for seg in hyp_ovl]
    if ref_ovl_ivs:
        tg.add_tier(IntervalTier(start_time=0, end_time=duration, name="ref_overlap", objects=ref_ovl_ivs))
    if hyp_ovl_ivs:
        tg.add_tier(IntervalTier(start_time=0, end_time=duration, name="hyp_overlap", objects=hyp_ovl_ivs))

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

    # Merge speaker aliases (e.g., "GPT-4o (1)"+"GPT-4o (2)" -> "GPT-4o",
    # "Mark" matched to "Mark Chen" via substring)
    ref_ann, hyp_ann, ref_merge_map, hyp_merge_map = merge_speaker_aliases(ref_ann, hyp_ann)
    # Log non-trivial merges
    ref_merges = {k: v for k, v in ref_merge_map.items() if k != v}
    hyp_merges = {k: v for k, v in hyp_merge_map.items() if k != v}
    if ref_merges or hyp_merges:
        import sys

        if ref_merges:
            print(f"Ref speaker merges: {ref_merges}", file=sys.stderr)
        if hyp_merges:
            print(f"Hyp speaker merges: {hyp_merges}", file=sys.stderr)

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
                _print_der_errors(
                    der_metric, ref_ann, hyp_ann, reference, hypothesis, hypothesis_file, collar, skip_events
                )
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
        elif metric_lower == "ovl":
            ovl_der = _compute_overlap_der(ref_ann, hyp_ann, collar)
            results["overlap_der"] = ovl_der["overlap_der"]
            results["non_overlap_der"] = ovl_der["non_overlap_der"]
        else:
            raise ValueError(f"Unknown metric: {metric}. Supported: der, jer, wer, sca, scer, ovl")

    # Compute overlap stats (always available, displayed on demand)
    results["_overlap_stats"] = _compute_overlap_stats(ref_ann, hyp_ann)

    # Add speaker diff info
    results["_ref_speakers"] = ref_speakers
    results["_hyp_speakers"] = hyp_speakers

    return results


def _print_aligned_table(headers: List[str], rows: List[List[str]]):
    """Print a markdown table with column-width-aligned output."""
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))
    print("| " + " | ".join(h.ljust(widths[i]) for i, h in enumerate(headers)) + " |")
    print("|" + "|".join("-" * (w + 2) for w in widths) + "|")
    for row in rows:
        print("| " + " | ".join(cell.ljust(widths[i]) for i, cell in enumerate(row)) + " |")


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
  python eval.py -r ref.ass -hyp hyp1.ass hyp2.ass hyp3.ass
  python eval.py -r ref.ass -hyp hyp.ass -m wer
  python eval.py -r ref.ass -hyp hyp.ass -m der jer sca -c 0.25
  python eval.py -r ref.ass -hyp hyp.ass -f json
        """,
    )

    parser.add_argument("--reference", "-r", required=True, help="Reference caption file")
    parser.add_argument("--hypothesis", "-hyp", required=True, nargs="+", help="Hypothesis caption file(s)")
    parser.add_argument(
        "--model-name",
        "--model_name",
        "-n",
        nargs="*",
        default=[],
        help="Model name(s) for display (auto-derived from filename if omitted)",
    )
    parser.add_argument(
        "--metrics",
        "-m",
        nargs="+",
        default=["der", "jer", "wer", "sca", "scer"],
        choices=["der", "jer", "wer", "sca", "scer", "ovl"],
        help="Metrics to compute (ovl = overlap-region DER breakdown)",
    )
    parser.add_argument("--overlap-stats", action="store_true", help="Show overlap detection statistics")
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

    for hyp_file in args.hypothesis:
        if not Path(hyp_file).exists():
            print(f"Error: Hypothesis file not found: {hyp_file}", file=sys.stderr)
            sys.exit(1)

    # Build model names: use provided names, fill remaining with filename stems
    model_names = list(args.model_name)
    for i in range(len(model_names), len(args.hypothesis)):
        model_names.append(Path(args.hypothesis[i]).stem)

    # Auto-detect language from dataset id in path
    language = args.language
    if language == "auto":
        detected = detect_language_from_path(args.reference) or detect_language_from_path(args.hypothesis[0])
        language = detected if detected else "en"
        if args.verbose:
            print(f"Auto-detected language: {language}", file=sys.stderr)

    # Evaluate all hypotheses
    all_entries = []
    for hyp_file, model_name in zip(args.hypothesis, model_names):
        if args.verbose:
            print(f"\n--- {model_name} ---", file=sys.stderr)
            print(f"Reference: {args.reference}", file=sys.stderr)
            print(f"Hypothesis: {hyp_file}", file=sys.stderr)
            print(
                f"Metrics: {', '.join(args.metrics)}  Language: {language}  Collar: {args.collar}s\n", file=sys.stderr
            )

        results = evaluate_alignment(
            reference_file=args.reference,
            hypothesis_file=hyp_file,
            metrics=args.metrics,
            collar=args.collar,
            skip_overlap=args.skip_overlap,
            skip_events=args.skip_events,
            language=language,
            verbose=args.verbose,
        )

        all_entries.append(
            {
                "model_name": model_name,
                "results": results,
                "ref_speakers": results.pop("_ref_speakers", set()),
                "hyp_speakers": results.pop("_hyp_speakers", set()),
                "overlap_stats": results.pop("_overlap_stats", None),
            }
        )

    if args.format == "json":
        if len(all_entries) == 1:
            output = dict(all_entries[0]["results"])
            s = all_entries[0]["overlap_stats"]
            if s and (args.overlap_stats or args.verbose):
                output["overlap_stats"] = s
            print(json.dumps(output, indent=2))
        else:
            output = []
            for e in all_entries:
                item = {"model": e["model_name"], **dict(e["results"])}
                if e["overlap_stats"] and (args.overlap_stats or args.verbose):
                    item["overlap_stats"] = e["overlap_stats"]
                output.append(item)
            print(json.dumps(output, indent=2))
        return

    # --- Text format: consolidated tables ---

    # 1) Detailed DER components table
    if "der" in args.metrics:
        der_col_order = ["diarization error rate", "false alarm", "missed detection", "confusion", "correct", "total"]
        der_headers = [
            "Model",
            "DER",
            "false alarm (s)",
            "missed detection (s)",
            "confusion (s)",
            "correct (s)",
            "total (s)",
        ]
        der_rows = []
        for e in all_entries:
            der_val = e["results"].get("der")
            if isinstance(der_val, dict):
                row = [e["model_name"]]
                for key in der_col_order:
                    row.append(f"{der_val[key]:.4f}" if key in der_val else "-")
                der_rows.append(row)
                e["results"]["der"] = der_val.get("diarization error rate", 0.0)
        if der_rows:
            print("\nDetailed DER Components:")
            print("Metric Details:")
            _print_aligned_table(der_headers, der_rows)
            print()

    # 2) Summary metrics table
    down_metrics = {"der", "jer", "wer", "scer", "overlap_der", "non_overlap_der"}
    metric_keys = []
    for m in args.metrics:
        if m == "ovl":
            for extra in ["overlap_der", "non_overlap_der"]:
                if any(e["results"].get(extra) is not None for e in all_entries):
                    metric_keys.append(extra)
        elif any(e["results"].get(m) is not None for e in all_entries):
            metric_keys.append(m)

    headers = ["Model"] + [f"{m.upper()} {'↓' if m in down_metrics else '↑'}" for m in metric_keys]
    rows = []
    for e in all_entries:
        row = [e["model_name"]]
        for m in metric_keys:
            val = e["results"].get(m)
            row.append(f"{val:.4f} ({val * 100:5.2f}%)" if val is not None else "-")
        rows.append(row)
    _print_aligned_table(headers, rows)

    # 3) Overlap analysis & speaker diff
    for e in all_entries:
        s = e["overlap_stats"]
        if s and (args.overlap_stats or args.verbose):
            print(f"\nOverlap Analysis ({e['model_name']}):")
            print(
                f"  Reference:  {s['ref_overlap_duration']:.2f}s"
                f" ({s['ref_overlap_pct']:.1f}% of {s['ref_total_duration']:.1f}s)"
            )
            print(f"  Hypothesis: {s['hyp_overlap_duration']:.2f}s ({s['hyp_overlap_pct']:.1f}%)")
            print(
                f"  Detection P/R/F1: {s['overlap_precision']:.4f} / {s['overlap_recall']:.4f} / {s['overlap_f1']:.4f}"
            )

        sca_val = e["results"].get("sca", 1.0)
        scer_val = e["results"].get("scer", 0.0)
        if sca_val != 1.0 or scer_val != 0.0:
            ref_spk = {sp for sp in e["ref_speakers"] if sp is not None}
            hyp_spk = {sp for sp in e["hyp_speakers"] if sp is not None}
            missing = ref_spk - hyp_spk
            extra = hyp_spk - ref_spk
            if missing or extra:
                print(f"\nSpeaker Diff ({e['model_name']}):")
                if missing:
                    print(f"  Missing: {', '.join(sorted(missing))}")
                if extra:
                    print(f"  Extra:   {', '.join(sorted(extra))}")


if __name__ == "__main__":
    main()
