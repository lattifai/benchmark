#!/bin/bash
# Compare transcription results between YouTube URL and local audio file
# Usage: ./scripts/compare_URL_Local.sh --id <dataset_id> [--models <model1,model2>]

set -e

# Load common functions
source "$(dirname "$0")/common.sh"

usage() {
    echo "Compare transcription results: YouTube URL vs Local Audio"
    echo ""
    echo "Usage: $0 --id <dataset_id> [options]"
    echo ""
    echo "Options:"
    echo "  --id <dataset_id>   Dataset to test (required)"
    echo "  --models <list>     Comma-separated models (default: gemini-3-flash-preview)"
    echo "  --prompt <file>     Custom prompt file for transcription"
    echo "  --skip-transcribe   Skip transcription, only run eval on existing files"
    echo "  --skip-events       Skip [event] markers in eval (default: true)"
    echo "  --no-skip-events    Include [event] markers in eval"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Requirements:"
    echo "  - GEMINI_API_KEY must be set (unless --skip-transcribe)"
    echo "  - Dataset must have video_url in datasets.json"
    echo "  - Dataset must have audio.mp3 in data/<dataset_id>/"
    echo ""
    echo "Example:"
    echo "  $0 --id OpenAI-Introducing-GPT-4o"
    echo "  $0 --id OpenAI-Introducing-GPT-4o --models gemini-3-flash-preview,gemini-2.5-pro"
}

# Parse arguments
DATASET_ID=""
MODELS="gemini-3-flash-preview"
PROMPT_FILE="prompts/Gemini_dotey.md"
SKIP_TRANSCRIBE="false"
SKIP_EVENTS="true"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --id)
            DATASET_ID="$2"
            shift 2
            ;;
        --models)
            MODELS="$2"
            shift 2
            ;;
        --prompt)
            PROMPT_FILE="$2"
            shift 2
            ;;
        --skip-transcribe)
            SKIP_TRANSCRIBE="true"
            shift
            ;;
        --skip-events)
            SKIP_EVENTS="true"
            shift
            ;;
        --no-skip-events)
            SKIP_EVENTS="false"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate
if [ -z "$DATASET_ID" ]; then
    print_error "Dataset ID is required"
    usage
    exit 1
fi

if ! dataset_exists "$DATASET_ID"; then
    print_error "Dataset not found: $DATASET_ID"
    exit 1
fi

if [ -z "$GEMINI_API_KEY" ] && [ "$SKIP_TRANSCRIBE" != "true" ]; then
    print_error "GEMINI_API_KEY not set"
    exit 1
fi

# Setup paths
SRC_DIR="$DATA_ROOT/$DATASET_ID"
COMPARE_DIR="$PROJECT_DIR/data/_compare/$DATASET_ID"
mkdir -p "$COMPARE_DIR"

# Check prerequisites
VIDEO_URL=$(get_dataset_info "$DATASET_ID" "video_url")
AUDIO_FILE="$SRC_DIR/audio.mp3"
GROUND_TRUTH="$SRC_DIR/ground_truth.ass"

if [ -z "$VIDEO_URL" ]; then
    print_error "Dataset has no video_url: $DATASET_ID"
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    print_error "audio.mp3 not found: $AUDIO_FILE"
    exit 1
fi

if [ ! -f "$GROUND_TRUTH" ]; then
    print_error "ground_truth.ass not found: $GROUND_TRUTH"
    exit 1
fi

LANG_CODE=$(get_language_code "$DATASET_ID")

print_header "Comparing Input Sources: $DATASET_ID"
print_info "Models: $MODELS"
if [ -n "$PROMPT_FILE" ]; then
    print_info "Prompt: $PROMPT_FILE"
fi
print_info "Language: $LANG_CODE"
print_info "Skip events: $SKIP_EVENTS"
print_info "URL: $VIDEO_URL"
print_info "Local: $AUDIO_FILE"

# Build prompt args
PROMPT_ARGS=""
if [ -n "$PROMPT_FILE" ]; then
    PROMPT_ARGS="transcription.prompt=\"$PROMPT_FILE\""
fi

# ============================================================================
# Step 1: Transcribe with both input sources (for each model)
# ============================================================================
if [ "$SKIP_TRANSCRIBE" != "true" ]; then
    print_header "Step 1: Transcription"

    for MODEL in ${MODELS//,/ }; do
        URL_MD="$COMPARE_DIR/${MODEL}_url.md"
        LOCAL_MD="$COMPARE_DIR/${MODEL}_local.md"

        if [ -f "$URL_MD" ]; then
            print_step "[$MODEL] Skipping URL (already exists)"
        else
            print_step "[$MODEL] Transcribing from YouTube URL..."
            lai transcribe run -Y "$VIDEO_URL" "$URL_MD" \
                transcription.model_name="$MODEL" \
                $PROMPT_ARGS
        fi

        if [ -f "$LOCAL_MD" ]; then
            print_step "[$MODEL] Skipping local (already exists)"
        else
            print_step "[$MODEL] Transcribing from local audio..."
            lai transcribe run -Y "$AUDIO_FILE" "$LOCAL_MD" \
                transcription.model_name="$MODEL" \
                $PROMPT_ARGS
        fi
    done
else
    print_header "Step 1: Skipping Transcription (using existing files)"
fi

# ============================================================================
# Step 2: Convert to ASS
# ============================================================================
print_header "Step 2: Convert to ASS"

for MODEL in ${MODELS//,/ }; do
    URL_MD="$COMPARE_DIR/${MODEL}_url.md"
    LOCAL_MD="$COMPARE_DIR/${MODEL}_local.md"
    URL_ASS="$COMPARE_DIR/${MODEL}_url.ass"
    LOCAL_ASS="$COMPARE_DIR/${MODEL}_local.ass"

    if [ -f "$URL_MD" ]; then
        print_step "[$MODEL] Converting URL transcript..."
        lai caption convert -Y "$URL_MD" "$URL_ASS" 2>/dev/null || print_warning "Failed to convert $URL_MD"
    fi

    if [ -f "$LOCAL_MD" ]; then
        print_step "[$MODEL] Converting local transcript..."
        lai caption convert -Y "$LOCAL_MD" "$LOCAL_ASS" 2>/dev/null || print_warning "Failed to convert $LOCAL_MD"
    fi
done

# ============================================================================
# Step 3: Evaluate and collect results
# ============================================================================
print_header "Step 3: Evaluation"

RESULTS_FILE=$(mktemp)

for MODEL in ${MODELS//,/ }; do
    URL_ASS="$COMPARE_DIR/${MODEL}_url.ass"
    LOCAL_ASS="$COMPARE_DIR/${MODEL}_local.ass"

    # Evaluate URL input
    if [ -f "$URL_ASS" ]; then
        print_step "Evaluating: $MODEL (URL)"
        result=$(run_eval_json "$GROUND_TRUTH" "$URL_ASS" "$LANG_CODE" "$SKIP_EVENTS")
        echo "{\"model\": \"$MODEL (URL)\", \"metrics\": $result}" >> "$RESULTS_FILE"
    fi

    # Evaluate Local input
    if [ -f "$LOCAL_ASS" ]; then
        print_step "Evaluating: $MODEL (Local)"
        result=$(run_eval_json "$GROUND_TRUTH" "$LOCAL_ASS" "$LANG_CODE" "$SKIP_EVENTS")
        echo "{\"model\": \"$MODEL (Local)\", \"metrics\": $result}" >> "$RESULTS_FILE"
    fi
done

# ============================================================================
# Step 4: Output summary table
# ============================================================================
print_header "Summary Table"

print_summary_table "$RESULTS_FILE"
rm -f "$RESULTS_FILE"

print_header "Comparison Complete"
print_info "Files saved to: $COMPARE_DIR"
