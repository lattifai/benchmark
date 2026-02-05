#!/bin/bash
# Reproduce LattifAI Benchmark Results
# Usage: ./scripts/run.sh [command] [--id <dataset_id>]

set -e

# Load common functions
source "$(dirname "$0")/common.sh"

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

# Get models from datasets.json or user-specified list
get_models() {
    local models_arg="$1"
    if [ -n "$models_arg" ]; then
        echo "$models_arg" | tr ',' '\n'
    else
        python3 -c "
import json
with open('$DATASETS_JSON') as f:
    data = json.load(f)
for model in data.get('models', []):
    print(model)
"
    fi
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

    if [ ! -d "$SRC_DIR" ]; then
        print_warning "Source data not found: $SRC_DIR"
        return 1
    fi

    if [ ! -f "$SRC_DIR/ground_truth.ass" ]; then
        print_warning "ground_truth.ass not found in $SRC_DIR"
        return 1
    fi

    local dataset_name
    dataset_name=$(get_dataset_info "$dataset_id" "name")
    print_header "Evaluating: $dataset_name ($dataset_id)"

    cd "$PROJECT_DIR"

    local lang_code="$language_arg"
    if [ -z "$lang_code" ]; then
        lang_code=$(get_language_code "$dataset_id")
    fi

    local extra_args="--language $lang_code"
    if [ "$skip_events" = "true" ]; then
        extra_args="$extra_args --skip-events"
        print_step "Skipping [event] markers"
    fi

    # Convert .md or .srt files to .ass if needed
    while IFS= read -r model; do
        [ -z "$model" ] && continue
        local ass_file="$OUT_DIR/${model}.ass"

        # Try .md first, then .srt
        local input_file=""
        if [ -f "$OUT_DIR/${model}.md" ]; then
            input_file="$OUT_DIR/${model}.md"
        elif [ -f "$OUT_DIR/${model}.srt" ]; then
            input_file="$OUT_DIR/${model}.srt"
        else
            continue
        fi

        if needs_update "$input_file" "$ass_file"; then
            print_step "Converting $(basename "$input_file") to .ass..."
            convert_if_needed "$input_file" "$ass_file" || continue
        fi
    done < <(get_models "$models_arg")

    print_step "Ground Truth (baseline)"
    python eval.py -r "$SRC_DIR/ground_truth.ass" -hyp "$SRC_DIR/ground_truth.ass" \
        --metrics der jer wer sca scer --collar 0.2 --model-name "Ground Truth" $extra_args

    # Evaluate specified models
    while IFS= read -r model; do
        [ -z "$model" ] && continue

        local display_name="$model"
        if [ -n "$tag" ]; then
            display_name="${model} ${tag}"
        fi

        # Evaluate raw Gemini output
        local ass_file="$OUT_DIR/${model}.ass"
        if [ -f "$ass_file" ]; then
            echo ""
            print_step "$display_name"
            python eval.py -r "$SRC_DIR/ground_truth.ass" -hyp "$ass_file" \
                --metrics der jer wer sca scer --collar 0.2 --model-name "$display_name" $extra_args
        fi

        # Evaluate LattifAI aligned output
        local lattifai_file="$OUT_DIR/${model}_LattifAI.ass"
        if [ -f "$lattifai_file" ]; then
            echo ""
            print_step "${display_name}_LattifAI"
            python eval.py -r "$SRC_DIR/ground_truth.ass" -hyp "$lattifai_file" \
                --metrics der jer wer sca scer --collar 0.2 --model-name "${display_name}_LattifAI" $extra_args
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
        while IFS= read -r id; do
            run_eval_for_dataset "$id" "$skip_events" "$models_arg" "$language_arg" "$tag"
        done < <(get_all_dataset_ids)
    fi

    print_header "Evaluation Complete"
}

# ============================================================================
# STEP 2: Transcribe Audio (requires GEMINI_API_KEY)
# ============================================================================
run_transcribe_for_dataset() {
    local dataset_id="$1"
    local use_local="$2"
    local prompt_file="$3"
    local include_thoughts="$4"
    local models_arg="$5"
    local temperature="$6"
    local no_thinking="$7"
    local SRC_DIR="$DATA_ROOT/$dataset_id"
    local OUT_DIR="$OUTPUT_DIR/$dataset_id"

    mkdir -p "$OUT_DIR"

    local dataset_name
    dataset_name=$(get_dataset_info "$dataset_id" "name")
    print_header "Transcribing: $dataset_name ($dataset_id)"

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

    local extra_args=""
    if [ -n "$prompt_file" ]; then
        extra_args="$extra_args transcription.prompt=\"$prompt_file\""
        print_step "Using prompt: $prompt_file"
    fi
    if [ "$no_thinking" = "true" ]; then
        extra_args="$extra_args transcription.thinking=false"
        print_step "Thinking mode: disabled"
    elif [ "$include_thoughts" = "true" ]; then
        extra_args="$extra_args transcription.include_thoughts=true"
        print_step "Including thinking process in output"
    fi
    if [ -n "$temperature" ]; then
        extra_args="$extra_args transcription.temperature=$temperature"
        print_step "Using temperature: $temperature"
    fi

    # Determine output extension based on prompt file name
    local output_ext=".md"
    if [[ "$prompt_file" == *"SRT"* ]] || [[ "$prompt_file" == *"srt"* ]]; then
        output_ext=".srt"
    fi

    while IFS= read -r model; do
        [ -z "$model" ] && continue
        local suffix=""
        if [ "$no_thinking" = "true" ]; then
            suffix="_no-thinking"
        fi
        local output_file="$OUT_DIR/${model}${suffix}${output_ext}"
        print_step "Transcribing with $model → ${output_ext}"
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
    local no_thinking="$7"

    if [ -z "$GEMINI_API_KEY" ]; then
        print_warning "GEMINI_API_KEY not set. Add it to .env file:"
        echo "  cp .env.example .env && edit .env"
        exit 1
    fi

    if [ -n "$dataset_id" ]; then
        run_transcribe_for_dataset "$dataset_id" "$use_local" "$prompt_file" "$include_thoughts" "$models_arg" "$temperature" "$no_thinking"
    else
        while IFS= read -r id; do
            run_transcribe_for_dataset "$id" "$use_local" "$prompt_file" "$include_thoughts" "$models_arg" "$temperature" "$no_thinking"
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
    local diarization="$3"
    local SRC_DIR="$DATA_ROOT/$dataset_id"
    local OUT_DIR="$OUTPUT_DIR/$dataset_id"

    local dataset_name
    dataset_name=$(get_dataset_info "$dataset_id" "name")
    print_header "Aligning: $dataset_name ($dataset_id)"

    local audio_file="$SRC_DIR/audio.mp3"
    if [ ! -f "$audio_file" ]; then
        print_warning "audio.mp3 not found in $SRC_DIR"
        return 1
    fi

    mkdir -p "$OUT_DIR"

    while IFS= read -r model; do
        [ -z "$model" ] && continue

        # Try .md first, then .srt
        local input_file=""
        if [ -f "$OUT_DIR/${model}.md" ]; then
            input_file="$OUT_DIR/${model}.md"
        elif [ -f "$OUT_DIR/${model}.srt" ]; then
            input_file="$OUT_DIR/${model}.srt"
        else
            print_warning "Transcript not found: $OUT_DIR/${model}.md or .srt"
            continue
        fi

        local output_file="$OUT_DIR/${model}_LattifAI.ass"
        if [ "$diarization" = "true" ]; then
            output_file="$OUT_DIR/${model}_LattifAI_Diarization.ass"
        fi

        if [ -f "$output_file" ]; then
            print_step "Skipping $model (already exists: $output_file)"
            continue
        fi

        local diar_arg=""
        if [ "$diarization" = "true" ]; then
            diar_arg="diarization.enabled=true"
        fi

        print_step "Aligning $model transcript ($(basename "$input_file"))..."
        lai alignment align -Y "$audio_file" \
            alignment.model_hub=modelscope \
            client.profile=true \
            caption.include_speaker_in_text=false \
            caption.split_sentence=true \
            caption.input_path="$input_file" \
            caption.output_path="$output_file" \
            $diar_arg
    done < <(get_models "$models_arg")
}

run_alignment() {
    local dataset_id="$1"
    local models_arg="$2"
    local diarization="$3"

    if [ -z "$LATTIFAI_API_KEY" ]; then
        print_warning "LATTIFAI_API_KEY not set. Add it to .env file:"
        echo "  cp .env.example .env && edit .env"
        exit 1
    fi

    if [ -n "$dataset_id" ]; then
        run_alignment_for_dataset "$dataset_id" "$models_arg" "$diarization"
    else
        while IFS= read -r id; do
            run_alignment_for_dataset "$id" "$models_arg" "$diarization"
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
    echo "  --no-thinking       Disable Gemini thinking mode (faster, cheaper)"
    echo "  --thoughts          Include Gemini thinking process in output"
    echo "  --skip-events       Skip [event] markers in eval (e.g., [Laughter])"
    echo "  --diarization       Enable speaker diarization in alignment"
    echo "  --models <list>     Comma-separated model names (default: all from datasets.json)"
    echo "  --language <code>   Language code for eval (en, zh, ja). Auto-detected if not set"
    echo "  --temperature <val> Sampling temperature for transcription (e.g., 0.5)"
    echo "  --tag <suffix>      Suffix to append to model names in eval output (e.g., _temp0.5)"
    echo ""
    echo "Examples:"
    echo "  $0 list                                       # List available datasets"
    echo "  $0 eval                                       # Evaluate all datasets"
    echo "  $0 eval --id OpenAI-Introducing-GPT-4o       # Evaluate specific dataset"
    echo "  $0 transcribe --id OpenAI-Introducing-GPT-4o # Transcribe (requires .env)"
    echo "  $0 transcribe --local                        # Transcribe from local audio"
    echo "  $0 align --id OpenAI-Introducing-GPT-4o      # Align (requires .env)"
    echo "  $0 all --id OpenAI-Introducing-GPT-4o        # Full pipeline"
}

# Parse arguments
COMMAND="${1:-eval}"
DATASET_ID=""
USE_LOCAL="false"
OUTPUT_DIR="$PROJECT_DIR/data"
PROMPT_FILE=""
INCLUDE_THOUGHTS="false"
NO_THINKING="false"
SKIP_EVENTS="false"
MODELS=""
LANGUAGE=""
TEMPERATURE=""
TAG=""
DIARIZATION="false"

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
        --no-thinking)
            NO_THINKING="true"
            shift
            ;;
        --skip-events)
            SKIP_EVENTS="true"
            shift
            ;;
        --diarization)
            DIARIZATION="true"
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
        run_transcribe "$DATASET_ID" "$USE_LOCAL" "$PROMPT_FILE" "$INCLUDE_THOUGHTS" "$MODELS" "$TEMPERATURE" "$NO_THINKING"
        ;;
    align)
        run_alignment "$DATASET_ID" "$MODELS" "$DIARIZATION"
        ;;
    all)
        run_transcribe "$DATASET_ID" "$USE_LOCAL" "$PROMPT_FILE" "$INCLUDE_THOUGHTS" "$MODELS" "$TEMPERATURE" "$NO_THINKING"
        run_alignment "$DATASET_ID" "$MODELS" "$DIARIZATION"
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
