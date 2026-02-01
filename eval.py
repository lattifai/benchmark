"""Evaluation metrics for caption alignment quality: DER, JER, WER, and SCA."""

import json
import re
from pathlib import Path
from typing import List, Optional, Union

import jiwer
import pysubs2
from lattifai.alignment.tokenizer import tokenize_multilingual_text
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
    return " ".join(tokens).lower()


# Pattern to match [event] markers (e.g., [Laughter], [Breathes in], [Applause])
EVENT_PATTERN = re.compile(r"\[[\w\s]+\]")


def is_event_only(text: str) -> bool:
    """Check if text contains only event markers (no actual speech)."""
    cleaned = EVENT_PATTERN.sub("", text).strip()
    return len(cleaned) == 0


def remove_events(text: str) -> str:
    """Remove [event] markers from text."""
    return EVENT_PATTERN.sub("", text).strip()


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
        text = fullwidth_to_halfwidth(event.text)  # Normalize fullwidth chars
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


def evaluate_alignment(
    reference_file: Union[str, Path],
    hypothesis_file: Union[str, Path],
    metrics: List[str] = ["der", "jer", "wer", "sca", "scer"],
    collar: float = 0.0,
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
    parser.add_argument("--collar", "-c", type=float, default=0.0, help="Collar size in seconds")
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
