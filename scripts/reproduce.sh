#!/bin/bash
# Reproduce LattifAI Benchmark Results
# Usage: ./scripts/reproduce.sh [all|eval|align]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data/introducing-gpt4o"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ============================================================================
# STEP 1: Run Evaluation Only (no API key needed)
# ============================================================================
run_eval() {
    print_header "Running Evaluation Metrics"
    cd "$PROJECT_DIR"

    print_step "Ground Truth (baseline)"
    python eval.py -r "$DATA_DIR/ground_truth.ass" -hyp "$DATA_DIR/ground_truth.ass" \
        --metrics der jer wer sca scer --collar 0.0 --model-name "Ground Truth"

    echo ""
    print_step "Gemini 2.5 Pro"
    python eval.py -r "$DATA_DIR/ground_truth.ass" -hyp "$DATA_DIR/gemini_2.5_pro.ass" \
        --metrics der jer wer sca scer --collar 0.0 --model-name "Gemini 2.5 Pro"

    print_step "Gemini 2.5 Pro + LattifAI"
    python eval.py -r "$DATA_DIR/ground_truth.ass" -hyp "$DATA_DIR/gemini_2.5_pro_lattifai.ass" \
        --metrics der jer wer sca scer --collar 0.0 --model-name "Gemini 2.5 Pro + LattifAI"

    echo ""
    print_step "Gemini 3 Pro Preview"
    python eval.py -r "$DATA_DIR/ground_truth.ass" -hyp "$DATA_DIR/gemini_3_pro.ass" \
        --metrics der jer wer sca scer --collar 0.0 --model-name "Gemini 3 Pro Preview"

    print_step "Gemini 3 Pro Preview + LattifAI"
    python eval.py -r "$DATA_DIR/ground_truth.ass" -hyp "$DATA_DIR/gemini_3_pro_lattifai.ass" \
        --metrics der jer wer sca scer --collar 0.0 --model-name "Gemini 3 Pro Preview + LattifAI"

    echo ""
    print_step "Gemini 3 Flash Preview"
    python eval.py -r "$DATA_DIR/ground_truth.ass" -hyp "$DATA_DIR/gemini_3_flash.ass" \
        --metrics der jer wer sca scer --collar 0.0 --model-name "Gemini 3 Flash Preview"

    print_step "Gemini 3 Flash Preview + LattifAI"
    python eval.py -r "$DATA_DIR/ground_truth.ass" -hyp "$DATA_DIR/gemini_3_flash_lattifai.ass" \
        --metrics der jer wer sca scer --collar 0.0 --model-name "Gemini 3 Flash Preview + LattifAI"

    print_header "Evaluation Complete"
}

# ============================================================================
# STEP 2: Generate Alignments (requires GEMINI_API_KEY)
# ============================================================================
run_alignment() {
    print_header "Generating Alignments with LattifAI"

    if [ -z "$GEMINI_API_KEY" ]; then
        print_warning "GEMINI_API_KEY not set. Please export GEMINI_API_KEY first."
        echo "  export GEMINI_API_KEY='your-api-key'"
        exit 1
    fi

    VIDEO_URL="https://www.youtube.com/watch?v=DQacCB9tDaw"

    # Convert Gemini markdown to ASS (no API needed)
    print_step "Converting Gemini transcripts to ASS format..."
    lai caption convert -Y "$DATA_DIR/gemini_2.5_pro.md" "$DATA_DIR/gemini_2.5_pro.ass" include_speaker_in_text=false
    lai caption convert -Y "$DATA_DIR/gemini_3_pro.md" "$DATA_DIR/gemini_3_pro.ass" include_speaker_in_text=false
    lai caption convert -Y "$DATA_DIR/gemini_3_flash.md" "$DATA_DIR/gemini_3_flash.ass" include_speaker_in_text=false

    # Gemini 2.5 Pro + LattifAI
    print_step "Aligning Gemini 2.5 Pro transcript..."
    lai alignment youtube -Y \
        "$VIDEO_URL" \
        media.output_dir=~/Downloads/lattifai_benchmark \
        client.profile=true \
        caption.include_speaker_in_text=false \
        caption.split_sentence=true \
        caption.input_path="$DATA_DIR/gemini_2.5_pro.md" \
        caption.output_path="$DATA_DIR/gemini_2.5_pro_lattifai.ass" \
        transcription.model_name=gemini-2.5-pro \
        transcription.gemini_api_key="$GEMINI_API_KEY"

    # Gemini 3 Pro + LattifAI
    print_step "Aligning Gemini 3 Pro Preview transcript..."
    lai alignment youtube -Y \
        "$VIDEO_URL" \
        media.output_dir=~/Downloads/lattifai_benchmark \
        client.profile=true \
        caption.include_speaker_in_text=false \
        caption.split_sentence=true \
        caption.input_path="$DATA_DIR/gemini_3_pro.md" \
        caption.output_path="$DATA_DIR/gemini_3_pro_lattifai.ass" \
        transcription.model_name=gemini-3-pro-preview \
        transcription.gemini_api_key="$GEMINI_API_KEY"

    # Gemini 3 Flash + LattifAI
    print_step "Aligning Gemini 3 Flash Preview transcript..."
    lai alignment youtube -Y \
        "$VIDEO_URL" \
        media.output_dir=~/Downloads/lattifai_benchmark \
        client.profile=true \
        caption.include_speaker_in_text=false \
        caption.split_sentence=true \
        caption.input_path="$DATA_DIR/gemini_3_flash.md" \
        caption.output_path="$DATA_DIR/gemini_3_flash_lattifai.ass" \
        transcription.model_name=gemini-3-flash-preview \
        transcription.gemini_api_key="$GEMINI_API_KEY"

    print_header "Alignment Complete"
}

# ============================================================================
# Main
# ============================================================================
usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  eval     Run evaluation metrics only (default)"
    echo "  align    Generate alignments (requires GEMINI_API_KEY)"
    echo "  all      Run both alignment and evaluation"
    echo ""
    echo "Examples:"
    echo "  $0 eval                    # Evaluate existing files"
    echo "  GEMINI_API_KEY=xxx $0 all  # Full reproduction"
}

case "${1:-eval}" in
    eval)
        run_eval
        ;;
    align)
        run_alignment
        ;;
    all)
        run_alignment
        run_eval
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
