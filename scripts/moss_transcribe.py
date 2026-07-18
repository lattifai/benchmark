#!/usr/bin/env python3
"""Transcribe audio via a MOSS-Transcribe-Diarize vLLM server and convert to JSON/ASS.

MOSS canonical output format (single stream of segments):
    [start_time][Sxx]transcribed speech[end_time]

Example:
    [0.48][S01]Welcome everyone[1.66][12.26][S02]The pipeline is ready[13.81]

Produces (same conventions as vibevoice_json2ass.py):
    <prefix>.txt   raw transcript text returned by the server
    <prefix>.json  [{"Start": 0.48, "End": 1.66, "Speaker": "S01", "Content": "..."}]
    <prefix>.ass   ASS subtitles with Speaker label in the Name field
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import pysubs2
import requests

SEGMENT_PATTERN = re.compile(
    r"\[(\d+(?:\.\d+)?)\]\[(S\d+)\](.*?)\[(\d+(?:\.\d+)?)\]",
    re.DOTALL,
)


def parse_transcript(text: str) -> list[dict]:
    """Parse MOSS `[start][Sxx]text[end]` stream into segment dicts."""
    segments = []
    for m in SEGMENT_PATTERN.finditer(text):
        start, speaker, content, end = m.groups()
        content = content.strip()
        if not content:
            continue
        segments.append(
            {
                "Start": float(start),
                "End": float(end),
                "Speaker": speaker,
                "Content": content,
            }
        )
    return segments


def _speaker_display(label: str) -> str:
    """Map MOSS `S01` labels to the `Speaker N` convention (as in vibevoice).

    A space before the number keeps eval.py's speaker-name normalizer from
    collapsing `S01`/`S02`/... into a single `S` speaker.
    """
    if label and re.fullmatch(r"S\d+", label):
        return f"Speaker {int(label[1:])}"
    return label or ""


def segments_to_ass(segments: list[dict], ass_path: Path) -> None:
    subs = pysubs2.SSAFile()
    for seg in segments:
        subs.events.append(
            pysubs2.SSAEvent(
                start=int(seg["Start"] * 1000),
                end=int(seg["End"] * 1000),
                text=seg["Content"],
                name=_speaker_display(seg.get("Speaker") or ""),
            )
        )
    subs.save(str(ass_path))


def transcribe(api_base: str, model: str, audio_path: Path, temperature: float = 0.0) -> str:
    url = f"{api_base.rstrip('/')}/audio/transcriptions"
    with open(audio_path, "rb") as f:
        resp = requests.post(
            url,
            data={"model": model, "response_format": "json", "temperature": str(temperature)},
            files={"file": (audio_path.name, f)},
            timeout=7200,
        )
    resp.raise_for_status()
    return resp.json()["text"]


def main():
    parser = argparse.ArgumentParser(description="MOSS-Transcribe-Diarize client + parser")
    parser.add_argument("audio", nargs="?", help="Audio file to transcribe")
    parser.add_argument("--api-base", default="http://localhost:8000/v1", help="OpenAI-compatible API base URL")
    parser.add_argument("--model", default="MOSS-Transcribe-Diarize", help="Model name as served")
    parser.add_argument("--temperature", type=float, default=0.0)
    parser.add_argument("--from-text", help="Skip API call; parse an existing raw transcript file")
    parser.add_argument("-o", "--output-prefix", required=True, help="Output prefix (writes .txt/.json/.ass)")
    args = parser.parse_args()

    prefix = Path(args.output_prefix)

    if args.from_text:
        raw = Path(args.from_text).read_text()
    else:
        if not args.audio:
            print("Error: audio file or --from-text required", file=sys.stderr)
            sys.exit(1)
        raw = transcribe(args.api_base, args.model, Path(args.audio), args.temperature)
        prefix.with_suffix(".txt").write_text(raw)
        print(f"Raw transcript -> {prefix.with_suffix('.txt')}")

    segments = parse_transcript(raw)
    if not segments:
        print("Error: no segments parsed from transcript", file=sys.stderr)
        sys.exit(1)

    prefix.with_suffix(".json").write_text(json.dumps(segments, ensure_ascii=False, indent=2))
    segments_to_ass(segments, prefix.with_suffix(".ass"))
    print(f"Parsed {len(segments)} segments -> {prefix.with_suffix('.json')}, {prefix.with_suffix('.ass')}")


if __name__ == "__main__":
    main()
