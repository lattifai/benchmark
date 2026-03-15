#!/bin/bash
# Generate ground truth SRT files for the podcast benchmark dataset.
#
# For each episode that has a transcript.md, converts it to SRT format.
# If an en.srt (YouTube subtitle) exists, uses it as timestamp reference
# via text matching for precise timing alignment.
#
# Usage:
#   ./scripts/generate_podcast_ground_truth.sh           # process all episodes
#   ./scripts/generate_podcast_ground_truth.sh dwarkesh   # process only dwarkesh episodes

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PODCAST_DIR="$(cd "$SCRIPT_DIR/../data/podcast" && pwd)"

FILTER="${1:-}"

count=0
skipped=0

for transcript in "$PODCAST_DIR"/*/*/*.transcript.md; do
    [ -f "$transcript" ] || continue

    dir="$(dirname "$transcript")"
    vid="$(basename "$transcript" .transcript.md)"
    episode="$(echo "$dir" | sed "s|$PODCAST_DIR/||")"

    # Apply filter if specified
    if [ -n "$FILTER" ] && [[ "$episode" != *"$FILTER"* ]]; then
        continue
    fi

    en_srt="$dir/${vid}.en.srt"
    output="$dir/${vid}.ground_truth.srt"

    echo "=== $episode ==="

    # Build command
    cmd=(lai caption convert "$transcript" "$output" include_speaker_in_text=true)
    if [ -f "$en_srt" ]; then
        cmd+=(reference="$en_srt")
        echo "  ref: $(basename "$en_srt")"
    else
        echo "  ref: (none, using interpolated timestamps)"
    fi

    # Run conversion (auto-confirm nemo_run dry-run prompt)
    echo 'y' | "${cmd[@]}" 2>&1 | grep -E "Parsed|Aligned|Converted" | sed 's/^/  /'

    count=$((count + 1))
    echo ""
done

echo "Done: $count episodes processed."
