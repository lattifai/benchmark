#!/bin/bash
# Reproduce LattifAI Benchmark Results
# Usage: ./scripts/reproduce.sh [command] [--id <dataset_id>]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATASETS_JSON="$PROJECT_DIR/data/datasets.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Get dataset IDs from datasets.json
get_all_dataset_ids() {
    python3 -c "
import json
with open('$DATASETS_JSON') as f:
    data = json.load(f)
for ds in data['datasets']:
    print(ds['id'])
"
}

# Check if dataset ID exists
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

# ============================================================================
# STEP 1: Run Evaluation Only (no API key needed)
# ============================================================================
run_eval_for_dataset() {
    local dataset_id="$1"
    local DATA_DIR="$OUTPUT_DIR/$dataset_id"

    if [ ! -d "$DATA_DIR" ]; then
        print_warning "Dataset directory not found: $DATA_DIR"
        return 1
    fi

    local dataset_name
    dataset_name=$(get_dataset_info "$dataset_id" "name")
    print_header "Evaluating: $dataset_name ($dataset_id)"

    cd "$PROJECT_DIR"

    # Check for ground_truth.ass
    if [ ! -f "$DATA_DIR/ground_truth.ass" ]; then
        print_warning "ground_truth.ass not found in $DATA_DIR"
        return 1
    fi

    print_step "Ground Truth (baseline)"
    python eval.py -r "$DATA_DIR/ground_truth.ass" -hyp "$DATA_DIR/ground_truth.ass" \
        --metrics der jer wer sca scer --collar 0.0 --model-name "Ground Truth"

    # Evaluate all model outputs if they exist
    for model_file in "$DATA_DIR"/*.ass; do
        [ -f "$model_file" ] || continue
        local filename
        filename=$(basename "$model_file")
        [ "$filename" = "ground_truth.ass" ] && continue

        local model_name="${filename%.ass}"
        echo ""
        print_step "$model_name"
        python eval.py -r "$DATA_DIR/ground_truth.ass" -hyp "$model_file" \
            --metrics der jer wer sca scer --collar 0.0 --model-name "$model_name"
    done
}

run_eval() {
    local dataset_id="$1"

    if [ -n "$dataset_id" ]; then
        run_eval_for_dataset "$dataset_id"
    else
        # Run for all datasets
        while IFS= read -r id; do
            run_eval_for_dataset "$id"
        done < <(get_all_dataset_ids)
    fi

    print_header "Evaluation Complete"
}

# ============================================================================
# STEP 2: Transcribe Audio (requires GEMINI_API_KEY)
# ============================================================================
get_all_models() {
    python3 -c "
import json
with open('$DATASETS_JSON') as f:
    data = json.load(f)
for model in data.get('models', []):
    print(model)
"
}

run_transcribe_for_dataset() {
    local dataset_id="$1"
    local use_local="$2"
    local prompt_file="$3"
    local DATA_DIR="$OUTPUT_DIR/$dataset_id"

    # Create directory if not exists
    mkdir -p "$DATA_DIR"

    local dataset_name
    dataset_name=$(get_dataset_info "$dataset_id" "name")
    print_header "Transcribing: $dataset_name ($dataset_id)"

    # Determine input source (default: URL)
    local input_source
    if [ "$use_local" = "true" ]; then
        input_source="$DATA_DIR/audio.mp3"
        if [ ! -f "$input_source" ]; then
            print_warning "audio.mp3 not found in $DATA_DIR"
            return 1
        fi
        print_step "Using local file: $input_source"
    else
        input_source=$(get_dataset_info "$dataset_id" "video_url")
        if [ -z "$input_source" ]; then
            print_warning "video_url not found for $dataset_id"
            return 1
        fi
        print_step "Using URL: $input_source"
    fi

    # Build prompt argument (supports file path or direct text)
    local prompt_arg=""
    if [ -n "$prompt_file" ]; then
        prompt_arg="transcription.prompt=\"$prompt_file\""
        print_step "Using prompt: $prompt_file"
    fi

    # Transcribe with each model
    while IFS= read -r model; do
        local output_file="$DATA_DIR/${model}.md"
        print_step "Transcribing with $model..."
        if [ -n "$prompt_arg" ]; then
            lai transcribe run -Y "$input_source" "$output_file" \
                transcription.model="$model" \
                $prompt_arg
        else
            lai transcribe run -Y "$input_source" "$output_file" \
                transcription.model="$model"
        fi
    done < <(get_all_models)
}

run_transcribe() {
    local dataset_id="$1"
    local use_local="$2"
    local prompt_file="$3"

    if [ -z "$GEMINI_API_KEY" ]; then
        print_warning "GEMINI_API_KEY not set. Please export GEMINI_API_KEY first."
        echo "  export GEMINI_API_KEY='your-api-key'"
        exit 1
    fi

    if [ -n "$dataset_id" ]; then
        run_transcribe_for_dataset "$dataset_id" "$use_local" "$prompt_file"
    else
        # Run for all datasets
        while IFS= read -r id; do
            run_transcribe_for_dataset "$id" "$use_local" "$prompt_file"
        done < <(get_all_dataset_ids)
    fi

    print_header "Transcription Complete"
}

# ============================================================================
# STEP 3: Generate Alignments (requires LATTIFAI_API_KEY)
# ============================================================================
run_alignment_for_dataset() {
    local dataset_id="$1"
    local DATA_DIR="$OUTPUT_DIR/$dataset_id"

    if [ ! -d "$DATA_DIR" ]; then
        print_warning "Dataset directory not found: $DATA_DIR"
        return 1
    fi

    local dataset_name
    dataset_name=$(get_dataset_info "$dataset_id" "name")
    print_header "Aligning: $dataset_name ($dataset_id)"

    # Check for audio file
    local audio_file="$DATA_DIR/audio.mp3"
    if [ ! -f "$audio_file" ]; then
        print_warning "audio.mp3 not found in $DATA_DIR"
        return 1
    fi

    # Align all markdown transcripts
    for md_file in "$DATA_DIR"/*.md; do
        [ -f "$md_file" ] || continue
        local filename
        filename=$(basename "$md_file")
        local model_name="${filename%.md}"
        local output_file="$DATA_DIR/${model_name}_lattifai.ass"

        print_step "Aligning $model_name transcript..."
        lai alignment align -Y "$audio_file" \
            client.profile=true \
            caption.include_speaker_in_text=false \
            caption.split_sentence=true \
            caption.input_path="$md_file" \
            caption.output_path="$output_file"
    done
}

run_alignment() {
    local dataset_id="$1"

    if [ -z "$LATTIFAI_API_KEY" ]; then
        print_warning "LATTIFAI_API_KEY not set. Please export LATTIFAI_API_KEY first."
        echo "  export LATTIFAI_API_KEY='your-api-key'"
        exit 1
    fi

    if [ -n "$dataset_id" ]; then
        run_alignment_for_dataset "$dataset_id"
    else
        # Run for all datasets
        while IFS= read -r id; do
            run_alignment_for_dataset "$id"
        done < <(get_all_dataset_ids)
    fi

    print_header "Alignment Complete"
}

# ============================================================================
# List available datasets
# ============================================================================
list_datasets() {
    print_header "Available Datasets"
    python3 -c "
import json
with open('$DATASETS_JSON') as f:
    data = json.load(f)
for ds in data['datasets']:
    print(f\"  {ds['id']}\")
    print(f\"    Name: {ds['name']}\")
    print(f\"    Language: {ds['language']}\")
    print(f\"    Duration: {ds['duration']}\")
    print(f\"    Speakers: {ds['num_speakers']}\")
    print()
"
}

# ============================================================================
# Main
# ============================================================================
usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  eval        Run evaluation metrics only (default)"
    echo "  transcribe  Transcribe audio with Gemini (requires GEMINI_API_KEY)"
    echo "  align       Generate alignments (requires LATTIFAI_API_KEY)"
    echo "  all         Run transcribe + align + eval pipeline"
    echo "  list        List available datasets"
    echo ""
    echo "Options:"
    echo "  --id <dataset_id>   Run for a specific dataset only"
    echo "  --local             Use local audio.mp3 instead of video_url (for transcribe)"
    echo "  -o, --output <dir>  Output directory (default: data/)"
    echo "  --prompt <file>     Custom prompt file for transcription"
    echo ""
    echo "Examples:"
    echo "  $0 eval                                       # Evaluate all datasets"
    echo "  $0 eval --id OpenAI-Introducing-GPT-4o       # Evaluate specific dataset"
    echo "  $0 list                                       # List available datasets"
    echo "  GEMINI_API_KEY=xxx $0 transcribe --id xxx    # Transcribe from YouTube URL"
    echo "  GEMINI_API_KEY=xxx $0 transcribe --local     # Transcribe from local audio"
    echo "  GEMINI_API_KEY=xxx $0 transcribe -o ./out    # Output to custom directory"
    echo "  LATTIFAI_API_KEY=xxx $0 align --id xxx       # Align specific dataset"
}

# Parse arguments
COMMAND="${1:-eval}"
DATASET_ID=""
USE_LOCAL="false"
OUTPUT_DIR="$PROJECT_DIR/data"
PROMPT_FILE=""

shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --id)
            DATASET_ID="$2"
            shift 2
            ;;
        --local)
            USE_LOCAL="true"
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --prompt)
            PROMPT_FILE="$2"
            shift 2
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

# Validate dataset ID if provided
if [ -n "$DATASET_ID" ]; then
    if ! dataset_exists "$DATASET_ID"; then
        print_error "Dataset not found: $DATASET_ID"
        echo ""
        list_datasets
        exit 1
    fi
fi

case "$COMMAND" in
    eval)
        run_eval "$DATASET_ID"
        ;;
    transcribe)
        run_transcribe "$DATASET_ID" "$USE_LOCAL" "$PROMPT_FILE"
        ;;
    align)
        run_alignment "$DATASET_ID"
        ;;
    all)
        run_transcribe "$DATASET_ID" "$USE_LOCAL" "$PROMPT_FILE"
        run_alignment "$DATASET_ID"
        run_eval "$DATASET_ID"
        ;;
    list)
        list_datasets
        ;;
    -h|--help)
        usage
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
