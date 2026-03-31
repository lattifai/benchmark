#!/usr/bin/env python3
"""Convert VibeVoice JSON output to ASS format.

VibeVoice JSON schema:
    [
      {"Start": 0.0, "End": 1.27, "Content": "[Human Sounds]"},
      {"Start": 1.27, "End": 30.98, "Speaker": 0, "Content": "Hello world"},
      ...
    ]

Converts to ASS with:
    - Speaker field -> ASS Name (e.g. "Speaker 0")
    - No Speaker field (events like [Music]) -> empty Name, text preserved
    - Timestamps converted from seconds to ASS milliseconds
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import pysubs2


def convert_json_to_ass(json_path: str, ass_path: str | None = None) -> str:
    """Convert a VibeVoice JSON file to ASS with speaker names.

    Args:
        json_path: Path to input JSON file.
        ass_path: Path to output ASS file. Defaults to same stem + .ass.

    Returns:
        Path to the written ASS file.
    """
    json_path = Path(json_path)
    if ass_path is None:
        ass_path = json_path.with_suffix(".ass")
    else:
        ass_path = Path(ass_path)

    with open(json_path) as f:
        segments = json.load(f)

    subs = pysubs2.SSAFile()

    for seg in segments:
        start_ms = int(seg["Start"] * 1000)
        end_ms = int(seg["End"] * 1000)
        content = seg.get("Content", "")
        speaker = seg.get("Speaker")

        event = pysubs2.SSAEvent(
            start=start_ms,
            end=end_ms,
            text=content,
            name=f"Speaker {speaker}" if speaker is not None else "",
        )
        subs.events.append(event)

    subs.save(str(ass_path))
    return str(ass_path)


def main():
    parser = argparse.ArgumentParser(
        description="Convert VibeVoice JSON to ASS with speaker diarization",
    )
    parser.add_argument("input", nargs="+", help="Input JSON file(s)")
    parser.add_argument(
        "-o",
        "--output",
        help="Output ASS file (only valid with single input)",
    )
    args = parser.parse_args()

    if args.output and len(args.input) > 1:
        print("Error: -o/--output only valid with a single input file", file=sys.stderr)
        sys.exit(1)

    for json_file in args.input:
        if not Path(json_file).exists():
            print(f"Error: {json_file} not found", file=sys.stderr)
            sys.exit(1)

        out = convert_json_to_ass(json_file, args.output)
        print(f"{json_file} -> {out}")


if __name__ == "__main__":
    main()
