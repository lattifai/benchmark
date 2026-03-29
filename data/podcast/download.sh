#!/usr/bin/env bash
# Download podcast benchmark dataset using lai youtube download
# Source: RESEARCH.md — Final Selection (8 episodes)
#
# Usage:
#   ./download.sh                          # download all to script directory
#   ./download.sh media                    # download only media files
#   ./download.sh caption                  # download only captions
#   ./download.sh transcript               # download only external transcripts
#   ./download.sh meta                     # download only metadata
#   ./download.sh ground_truth             # generate ground truth SRTs from transcripts
#   ./download.sh "" /path/to/output       # download all to custom directory
#   ./download.sh media /path/to/output    # download only media to custom directory
set -euo pipefail

ONLY="${1:-}"
BASE_DIR="${2:-$(cd "$(dirname "$0")" && pwd)}"

# --- Ground truth generation mode ---
if [ "$ONLY" = "ground_truth" ]; then
    count=0
    for transcript in "$BASE_DIR"/*/*/*.transcript.md; do
        [ -f "$transcript" ] || continue

        dir="$(dirname "$transcript")"
        vid="$(basename "$transcript" .transcript.md)"
        episode="$(echo "$dir" | sed "s|$BASE_DIR/||")"
        en_srt="$dir/${vid}.en.srt"
        output="$dir/${vid}.ground_truth.srt"

        echo "=== $episode ==="

        cmd=(lai caption convert "$transcript" "$output" input_format=markdown include_speaker_in_text=true)
        if [ -f "$en_srt" ]; then
            cmd+=(reference="$en_srt")
            echo "  ref: $(basename "$en_srt")"
        else
            echo "  ref: (none, using interpolated timestamps)"
        fi

        echo 'y' | "${cmd[@]}" 2>&1 | grep -E "Parsed|Aligned|Converted" | sed 's/^/  /'
        count=$((count + 1))
        echo ""
    done
    echo "✅ Ground truth generated: $count episodes."
    exit 0
fi

# --- Download mode ---
ONLY_ARG=""
if [ -n "$ONLY" ]; then
    ONLY_ARG="only=$ONLY"
fi

download() {
    local url="$1"
    local dir="$2"
    lai youtube download "$url" $ONLY_ARG \
        media.output_dir="$BASE_DIR/$dir" media.force_overwrite=true --direct -Y
}

# --- No Priors ---

# 1. 2026 AI Forecast (40m)
download "https://www.youtube.com/watch?v=TOsNrV3bXtQ" "no-priors/2026-ai-forecast"

# 2. Jensen Huang: Reasoning, Robotics (1h16m)
download "https://www.youtube.com/watch?v=k-xtmISBCNE" "no-priors/jensen-huang"

# --- MLST ---

# 3. Blaise Agüera y Arcas: Intelligence (55m)
download "https://www.youtube.com/watch?v=M2iX6HQOoLg" "mlst/blaise-aguera-y-arcas"

# 4. Max Bennett: Brain Predictions (3h17m)
download "https://www.youtube.com/watch?v=RvYSsi6rd4g" "mlst/max-bennett"

# --- Latent Space ---

# 5. Jeff Dean: Gemini 3 Deep Think (1h23m)
download "https://www.youtube.com/watch?v=F_1oDPWxpFQ" "latent-space/jeff-dean"

# --- Dwarkesh ---

# 6. Dario Amodei: "End of the exponential" (2h22m)
download "https://www.youtube.com/watch?v=n1E9IZfvGMA" "dwarkesh/dario-amodei"

# 7. Dylan Patel: AI compute bottleneck (2h30m)
download "https://www.youtube.com/watch?v=mDG_Hx3BSUE" "dwarkesh/dylan-patel"

# --- Lex Fridman ---

# 8. State of AI 2026 | #490 (4h25m)
download "https://www.youtube.com/watch?v=EV7WhVT270Q" "lex-fridman/state-of-ai-2026"

# --- 硅谷101 ---

# 9. E230 英伟达的巅峰与软肋 (1h06m)
download "https://www.youtube.com/watch?v=OpwVpEc6noc" "valley101podcast/nvidia-peak-and-weakness"

# --- @xiaojunpodcast ---

# 10. Saining Xie 7-hour marathon interview (6h44m)
download "https://www.youtube.com/watch?v=rIwgZWzUKm8" "xiaojunpodcast/xie-saining-marathon"

# --- @罗永浩的十字路口 ---

# 11. 杨笠×罗永浩 (3h42m)
download "https://www.youtube.com/watch?v=DpGkfVxw9ps" "罗永浩的十字路口/yangli-x-luoyonghao"

echo "✅ All 11 episodes downloaded${ONLY:+ (only=$ONLY)}."
