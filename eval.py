"""Evaluation metrics for caption alignment quality: DER, JER, WER, and SCA."""

import re
from pathlib import Path
from typing import List, Union

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
            event.name = event.name.rstrip(":").lstrip(">").strip()
            speaker = event.name

        annotation[segment] = event.name or speaker

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
        text = event.text.replace("...", " ").strip()
        if skip_events:
            # Skip event-only entries
            if is_event_only(text):
                continue
            # Remove [event] markers from text
            text = remove_events(text)
        if text:
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

        # Filter out event-only entries for verbose analysis if skip_events is True
        if skip_events:
            ref_events = [e for e in reference.events if not is_event_only(e.text)]
            hyp_events = [e for e in hypothesis.events if not is_event_only(e.text)]
            ref_sentences = [remove_events(event.text) for event in ref_events]
            hyp_sentences = [remove_events(event.text) for event in hyp_events]
        else:
            ref_events = reference.events
            hyp_events = hypothesis.events
            ref_sentences = [event.text for event in ref_events]
            hyp_sentences = [event.text for event in hyp_events]
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
        "--language", "-l", default="en", help="Language code (en, zh, etc.). Non-English uses basic normalizer"
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

    if args.verbose:
        print(f"Reference: {args.reference}", file=sys.stderr)
        print(f"Hypothesis: {args.hypothesis}", file=sys.stderr)
        print(f"Metrics: {', '.join(args.metrics)}", file=sys.stderr)
        print(f"Collar: {args.collar}s\n", file=sys.stderr)

    results = evaluate_alignment(
        reference_file=args.reference,
        hypothesis_file=args.hypothesis,
        metrics=args.metrics,
        collar=args.collar,
        skip_overlap=args.skip_overlap,
        skip_events=args.skip_events,
        language=args.language,
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
