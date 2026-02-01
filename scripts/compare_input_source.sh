#!/bin/bash
# Compare transcription results between YouTube URL and local audio file
# Usage: ./scripts/compare_input_source.sh --id <dataset_id> [--model <model>]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATASETS_JSON="$PROJECT_DIR/data/datasets.json"
DATA_ROOT="$PROJECT_DIR/data"

# Load .env file if exists
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

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

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Get dataset info
get_dataset_info() {
    local id="$1"
    local field="$2"
    python3 -c "
import json
with open('$DATASETS_JSON') as f:
    data = json.load(f)
for ds in data['datasets']:
    if ds['id'] == '$id':
        print(ds.get('$field', ''))
        break
"
}

# Check if dataset exists
dataset_exists() {
    local id="$1"
    python3 -c "
import json, sys
with open('$DATASETS_JSON') as f:
    data = json.load(f)
ids = [ds['id'] for ds in data['datasets']]
sys.exit(0 if '$id' in ids else 1)
"
}

usage() {
    echo "Compare transcription results: YouTube URL vs Local Audio"
    echo ""
    echo "Usage: $0 --id <dataset_id> [options]"
    echo ""
    echo "Options:"
    echo "  --id <dataset_id>   Dataset to test (required)"
    echo "  --model <model>     Gemini model (default: gemini-2.5-pro)"
    echo "  --skip-transcribe   Skip transcription, only run eval on existing files"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Requirements:"
    echo "  - GEMINI_API_KEY must be set"
    echo "  - Dataset must have video_url in datasets.json"
    echo "  - Dataset must have audio.mp3 in data/<dataset_id>/"
    echo ""
    echo "Example:"
    echo "  $0 --id OpenAI-Introducing-GPT-4o"
    echo "  $0 --id OpenAI-Introducing-GPT-4o --model gemini-3-flash-preview"
}

# Parse arguments
DATASET_ID=""
MODEL="gemini-2.5-pro"
SKIP_TRANSCRIBE="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --id)
            DATASET_ID="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --skip-transcribe)
            SKIP_TRANSCRIBE="true"
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

# Get language
LANG_CODE="en"
DATASET_LANG=$(get_dataset_info "$DATASET_ID" "language")
if [[ "$DATASET_LANG" == zh* ]]; then
    LANG_CODE="zh"
elif [[ "$DATASET_LANG" == ja* ]]; then
    LANG_CODE="ja"
fi

print_header "Comparing Input Sources: $DATASET_ID"
print_info "Model: $MODEL"
print_info "Language: $LANG_CODE"
print_info "URL: $VIDEO_URL"
print_info "Local: $AUDIO_FILE"
echo ""

# Output files
URL_MD="$COMPARE_DIR/${MODEL}_url.md"
LOCAL_MD="$COMPARE_DIR/${MODEL}_local.md"
URL_ASS="$COMPARE_DIR/${MODEL}_url.ass"
LOCAL_ASS="$COMPARE_DIR/${MODEL}_local.ass"

# ============================================================================
# Step 1: Transcribe with both input sources
# ============================================================================
if [ "$SKIP_TRANSCRIBE" != "true" ]; then
    print_header "Step 1: Transcription"

    # Transcribe from URL
    print_step "Transcribing from YouTube URL..."
    lai transcribe run -Y "$VIDEO_URL" "$URL_MD" \
        transcription.model_name="$MODEL"

    # Transcribe from local file
    print_step "Transcribing from local audio..."
    lai transcribe run -Y "$AUDIO_FILE" "$LOCAL_MD" \
        transcription.model_name="$MODEL"
else
    print_header "Step 1: Skipping Transcription (using existing files)"
    if [ ! -f "$URL_MD" ] || [ ! -f "$LOCAL_MD" ]; then
        print_error "Missing transcription files. Run without --skip-transcribe first."
        exit 1
    fi
fi

# ============================================================================
# Step 2: Convert to ASS
# ============================================================================
print_header "Step 2: Convert to ASS"

print_step "Converting URL transcript..."
lai caption convert -Y "$URL_MD" "$URL_ASS" 2>/dev/null

print_step "Converting local transcript..."
lai caption convert -Y "$LOCAL_MD" "$LOCAL_ASS" 2>/dev/null

# ============================================================================
# Step 3: Evaluate both
# ============================================================================
print_header "Step 3: Evaluation Results"

cd "$PROJECT_DIR"

echo -e "${CYAN}━━━ Ground Truth (baseline) ━━━${NC}"
python eval.py -r "$GROUND_TRUTH" -hyp "$GROUND_TRUTH" \
    --metrics der jer wer sca scer --collar 0.0 \
    --model-name "Ground Truth" --language "$LANG_CODE"

echo ""
echo -e "${CYAN}━━━ YouTube URL Input ━━━${NC}"
python eval.py -r "$GROUND_TRUTH" -hyp "$URL_ASS" \
    --metrics der jer wer sca scer --collar 0.0 \
    --model-name "$MODEL (URL)" --language "$LANG_CODE"

echo ""
echo -e "${CYAN}━━━ Local Audio Input ━━━${NC}"
python eval.py -r "$GROUND_TRUTH" -hyp "$LOCAL_ASS" \
    --metrics der jer wer sca scer --collar 0.0 \
    --model-name "$MODEL (Local)" --language "$LANG_CODE"

# ============================================================================
# Step 4: Text Diff Analysis
# ============================================================================
print_header "Step 4: Text Comparison"

# Extract plain text for comparison
URL_TXT="$COMPARE_DIR/${MODEL}_url.txt"
LOCAL_TXT="$COMPARE_DIR/${MODEL}_local.txt"

python3 -c "
import pysubs2

def extract_text(ass_file, output_file):
    subs = pysubs2.load(ass_file)
    with open(output_file, 'w') as f:
        for event in subs.events:
            text = event.text.replace('\\\\N', ' ').strip()
            if text:
                f.write(text + '\\n')

extract_text('$URL_ASS', '$URL_TXT')
extract_text('$LOCAL_ASS', '$LOCAL_TXT')
"

# Word count comparison
URL_WORDS=$(wc -w < "$URL_TXT" | tr -d ' ')
LOCAL_WORDS=$(wc -w < "$LOCAL_TXT" | tr -d ' ')

print_info "Word count (URL):   $URL_WORDS"
print_info "Word count (Local): $LOCAL_WORDS"
print_info "Difference: $((LOCAL_WORDS - URL_WORDS)) words"

# Show first few differences
echo ""
print_step "First 10 differing lines:"
diff --side-by-side --width=120 "$URL_TXT" "$LOCAL_TXT" 2>/dev/null | grep -E '^.+\|.+$' | head -10 || echo "  (No differences found)"

print_header "Comparison Complete"
print_info "Files saved to: $COMPARE_DIR"
