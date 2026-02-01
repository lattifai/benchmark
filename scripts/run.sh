#!/bin/bash
# Reproduce LattifAI Benchmark Results
# Usage: ./scripts/reproduce.sh [command] [--id <dataset_id>]

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

# Get dataset IDs from datasets.json (excludes -First5mins variants)
get_all_dataset_ids() {
    python3 -c "
import json
with open('$DATASETS_JSON') as f:
    data = json.load(f)
for ds in data['datasets']:
    if '-First5mins' not in ds['id']:
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
    local skip_events="$2"
    local models_arg="$3"
    local language_arg="$4"
    local tag="$5"
    local SRC_DIR="$DATA_ROOT/$dataset_id"
    local OUT_DIR="$OUTPUT_DIR/$dataset_id"

    # Check source data directory
    if [ ! -d "$SRC_DIR" ]; then
        print_warning "Source data not found: $SRC_DIR"
        return 1
    fi

    # Check for ground_truth.ass in source
    if [ ! -f "$SRC_DIR/ground_truth.ass" ]; then
        print_warning "ground_truth.ass not found in $SRC_DIR"
        return 1
    fi

    local dataset_name
    dataset_name=$(get_dataset_info "$dataset_id" "name")
    print_header "Evaluating: $dataset_name ($dataset_id)"

    cd "$PROJECT_DIR"

    # Use specified language or auto-detect from dataset
    local lang_code="$language_arg"
    if [ -z "$lang_code" ]; then
        local dataset_lang
        dataset_lang=$(get_dataset_info "$dataset_id" "language")
        lang_code="en"
        if [[ "$dataset_lang" == zh* ]]; then
            lang_code="zh"
        elif [[ "$dataset_lang" == ja* ]]; then
            lang_code="ja"
        fi
    fi

    # Build extra args
    local extra_args="--language $lang_code"
    if [ "$skip_events" = "true" ]; then
        extra_args="$extra_args --skip-events"
        print_step "Skipping [event] markers"
    fi

    # Convert .md files to .ass if not already converted (for evaluating raw Gemini output)
    while IFS= read -r model; do
        [ -z "$model" ] && continue
        local md_file="$OUT_DIR/${model}.md"
        local ass_file="$OUT_DIR/${model}.ass"

        # Skip if .md doesn't exist
        [ -f "$md_file" ] || continue

        # # Skip if .ass already exists
        # if [ -f "$ass_file" ]; then
        #     continue
        # fi

        print_step "Converting ${model}.md to .ass..."
        lai caption convert -Y "$md_file" "$ass_file" 2>/dev/null || {
            print_warning "Failed to convert $md_file"
            continue
        }
    done < <(get_models "$models_arg")

    print_step "Ground Truth (baseline)"
    python eval.py -r "$SRC_DIR/ground_truth.ass" -hyp "$SRC_DIR/ground_truth.ass" \
        --metrics der jer wer sca scer --collar 0.0 --model-name "Ground Truth" $extra_args

    # Evaluate specified models
    while IFS= read -r model; do
        [ -z "$model" ] && continue

        # Build display name with optional tag
        local display_name="$model"
        if [ -n "$tag" ]; then
            display_name="${model} ${tag}"
        fi

        # Evaluate raw Gemini output (.ass converted from .md)
        local ass_file="$OUT_DIR/${model}.ass"
        if [ -f "$ass_file" ]; then
            echo ""
            print_step "$display_name"
            # print_step "$SRC_DIR/ground_truth.ass $ass_file $extra_args"
            python eval.py -r "$SRC_DIR/ground_truth.ass" -hyp "$ass_file" \
                --metrics der jer wer sca scer --collar 0.0 --model-name "$display_name" $extra_args
        fi

        # Evaluate LattifAI aligned output
        local lattifai_file="$OUT_DIR/${model}_LattifAI.ass"
        if [ -f "$lattifai_file" ]; then
            echo ""
            print_step "${display_name}_LattifAI"
            python eval.py -r "$SRC_DIR/ground_truth.ass" -hyp "$lattifai_file" \
                --metrics der jer wer sca scer --collar 0.0 --model-name "${display_name}_LattifAI" $extra_args
        fi
    done < <(get_models "$models_arg")
}

run_eval() {
    local dataset_id="$1"
    local skip_events="$2"
    local models_arg="$3"
    local language_arg="$4"
    local tag="$5"

    if [ -n "$dataset_id" ]; then
        run_eval_for_dataset "$dataset_id" "$skip_events" "$models_arg" "$language_arg" "$tag"
    else
        # Run for all datasets
        while IFS= read -r id; do
            run_eval_for_dataset "$id" "$skip_events" "$models_arg" "$language_arg" "$tag"
        done < <(get_all_dataset_ids)
    fi

    print_header "Evaluation Complete"
}

# ============================================================================
# STEP 2: Transcribe Audio (requires GEMINI_API_KEY)
# ============================================================================
get_models() {
    local models_arg="$1"
    if [ -n "$models_arg" ]; then
        # Use user-specified models (comma-separated)
        echo "$models_arg" | tr ',' '\n'
    else
        # Use all models from datasets.json
        python3 -c "
import json
with open('$DATASETS_JSON') as f:
    data = json.load(f)
for model in data.get('models', []):
    print(model)
"
    fi
}

run_transcribe_for_dataset() {
    local dataset_id="$1"
    local use_local="$2"
    local prompt_file="$3"
    local include_thoughts="$4"
    local models_arg="$5"
    local temperature="$6"
    local SRC_DIR="$DATA_ROOT/$dataset_id"
    local OUT_DIR="$OUTPUT_DIR/$dataset_id"

    # Create output directory if not exists
    mkdir -p "$OUT_DIR"

    local dataset_name
    dataset_name=$(get_dataset_info "$dataset_id" "name")
    print_header "Transcribing: $dataset_name ($dataset_id)"

    # Determine input source (default: URL)
    local input_source
    if [ "$use_local" = "true" ]; then
        input_source="$SRC_DIR/audio.mp3"
        if [ ! -f "$input_source" ]; then
            print_warning "audio.mp3 not found in $SRC_DIR"
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

    # Build extra arguments
    local extra_args=""
    if [ -n "$prompt_file" ]; then
        extra_args="$extra_args transcription.prompt=\"$prompt_file\""
        print_step "Using prompt: $prompt_file"
    fi
    if [ "$include_thoughts" = "true" ]; then
        extra_args="$extra_args transcription.include_thoughts=true"
        print_step "Including thinking process"
    fi
    if [ -n "$temperature" ]; then
        extra_args="$extra_args transcription.temperature=$temperature"
        print_step "Using temperature: $temperature"
    fi

    # Transcribe with each model
    while IFS= read -r model; do
        [ -z "$model" ] && continue
        local output_file="$OUT_DIR/${model}.md"
        print_step "Transcribing with $model..."
        lai transcribe run -Y "$input_source" "$output_file" \
            transcription.model_name="$model" \
            $extra_args
    done < <(get_models "$models_arg")
}

run_transcribe() {
    local dataset_id="$1"
    local use_local="$2"
    local prompt_file="$3"
    local include_thoughts="$4"
    local models_arg="$5"
    local temperature="$6"

    if [ -z "$GEMINI_API_KEY" ]; then
        print_warning "GEMINI_API_KEY not set. Please export GEMINI_API_KEY first."
        echo "  export GEMINI_API_KEY='your-api-key'"
        exit 1
    fi

    if [ -n "$dataset_id" ]; then
        run_transcribe_for_dataset "$dataset_id" "$use_local" "$prompt_file" "$include_thoughts" "$models_arg" "$temperature"
    else
        # Run for all datasets
        while IFS= read -r id; do
            run_transcribe_for_dataset "$id" "$use_local" "$prompt_file" "$include_thoughts" "$models_arg" "$temperature"
        done < <(get_all_dataset_ids)
    fi

    print_header "Transcription Complete"
}

# ============================================================================
# STEP 3: Generate Alignments (requires LATTIFAI_API_KEY)
# ============================================================================
run_alignment_for_dataset() {
    local dataset_id="$1"
    local models_arg="$2"
    local SRC_DIR="$DATA_ROOT/$dataset_id"
    local OUT_DIR="$OUTPUT_DIR/$dataset_id"

    local dataset_name
    dataset_name=$(get_dataset_info "$dataset_id" "name")
    print_header "Aligning: $dataset_name ($dataset_id)"

    # Check for audio file in source directory
    local audio_file="$SRC_DIR/audio.mp3"
    if [ ! -f "$audio_file" ]; then
        print_warning "audio.mp3 not found in $SRC_DIR"
        return 1
    fi

    # Align transcripts for specified models
    mkdir -p "$OUT_DIR"

    while IFS= read -r model; do
        [ -z "$model" ] && continue
        local md_file="$OUT_DIR/${model}.md"
        if [ ! -f "$md_file" ]; then
            print_warning "Transcript not found: $md_file"
            continue
        fi
        local output_file="$OUT_DIR/${model}_LattifAI.ass"

        # Skip if output already exists
        if [ -f "$output_file" ]; then
            print_step "Skipping $model (already exists: $output_file)"
            continue
        fi

        print_step "Aligning $model transcript..."
        lai alignment align -Y "$audio_file" \
            client.profile=true \
            caption.include_speaker_in_text=false \
            caption.split_sentence=true \
            caption.input_path="$md_file" \
            caption.output_path="$output_file"
    done < <(get_models "$models_arg")
}

run_alignment() {
    local dataset_id="$1"
    local models_arg="$2"

    if [ -z "$LATTIFAI_API_KEY" ]; then
        print_warning "LATTIFAI_API_KEY not set. Please export LATTIFAI_API_KEY first."
        echo "  export LATTIFAI_API_KEY='your-api-key'"
        exit 1
    fi

    if [ -n "$dataset_id" ]; then
        run_alignment_for_dataset "$dataset_id" "$models_arg"
    else
        # Run for all datasets
        while IFS= read -r id; do
            run_alignment_for_dataset "$id" "$models_arg"
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
    echo "  --thoughts          Include Gemini thinking process in output"
    echo "  --skip-events       Skip [event] markers in eval (e.g., [Laughter])"
    echo "  --models <list>     Comma-separated model names (default: all from datasets.json)"
    echo "  --language <code>   Language code for eval (en, zh, ja). Auto-detected if not set"
    echo "  --temperature <val> Sampling temperature for transcription (e.g., 0.5)"
    echo "  --tag <suffix>      Suffix to append to model names in eval output (e.g., _temp0.5)"
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
INCLUDE_THOUGHTS="false"
SKIP_EVENTS="false"
MODELS=""
LANGUAGE=""
TEMPERATURE=""
TAG=""

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
        --thoughts)
            INCLUDE_THOUGHTS="true"
            shift
            ;;
        --skip-events)
            SKIP_EVENTS="true"
            shift
            ;;
        --models)
            MODELS="$2"
            shift 2
            ;;
        --language|-l)
            LANGUAGE="$2"
            shift 2
            ;;
        --temperature)
            TEMPERATURE="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
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
        run_eval "$DATASET_ID" "$SKIP_EVENTS" "$MODELS" "$LANGUAGE" "$TAG"
        ;;
    transcribe)
        run_transcribe "$DATASET_ID" "$USE_LOCAL" "$PROMPT_FILE" "$INCLUDE_THOUGHTS" "$MODELS" "$TEMPERATURE"
        ;;
    align)
        run_alignment "$DATASET_ID" "$MODELS"
        ;;
    all)
        run_transcribe "$DATASET_ID" "$USE_LOCAL" "$PROMPT_FILE" "$INCLUDE_THOUGHTS" "$MODELS" "$TEMPERATURE"
        run_alignment "$DATASET_ID" "$MODELS"
        run_eval "$DATASET_ID" "$SKIP_EVENTS" "$MODELS" "$LANGUAGE" "$TAG"
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
