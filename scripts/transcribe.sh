#!/bin/bash
# Transcription benchmark: run ASR models via `lai transcribe run` and measure WER
# Supports three model types: local, Gemini API, and vLLM/SGLang served models.
#
# Usage: ./scripts/transcribe.sh [OPTIONS]
#
# Examples:
#   ./scripts/transcribe.sh                                          # All local models
#   ./scripts/transcribe.sh --lang en --device mps                   # English, Apple Silicon
#   ./scripts/transcribe.sh -m "parakeet sensevoice"                 # Filter by keyword
#   ./scripts/transcribe.sh --type gemini                            # Gemini API models only
#   ./scripts/transcribe.sh --type vllm --api-base-url http://localhost:8000/v1  # vLLM models

set -e

# Load common functions
source "$(dirname "$0")/common.sh"

# ============================================================================
# Configuration
# ============================================================================
LANG_FILTER=""
MODEL_FILTER=""
DEVICE="cpu"
FORCE=false
TYPE_FILTER=""           # "local", "gemini", "vllm", or "" (all)
API_BASE_URL=""          # vLLM/SGLang server URL
API_MODE="transcriptions" # vLLM API mode: transcriptions, chat, realtime
AUDIO_CONTENT_TYPE=""     # chat mode audio format: audio_url (vLLM) or audio (mlx-vlm)
CHAT_AUDIO_FIRST=""      # content order: true = [audio, text], false = [text, audio]
PROMPT_FILE=""           # Custom prompt file for transcription
SUFFIX=""                # Output filename suffix and display tag
EXTRA_ARGS=()            # Extra key=value args passed directly to lai transcribe run
DATASET_FILTER=""        # Dataset ID keyword filter

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --lang)
            LANG_FILTER="$2"
            shift 2
            ;;
        --models|-m)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                MODEL_FILTER="${MODEL_FILTER:+$MODEL_FILTER }$1"
                shift
            done
            ;;
        --device|-d)
            DEVICE="$2"
            shift 2
            ;;
        --type|-t)
            TYPE_FILTER="$2"
            shift 2
            ;;
        --api-base-url)
            API_BASE_URL="$2"
            shift 2
            ;;
        --api-mode)
            API_MODE="$2"
            shift 2
            ;;
        --audio-content-type)
            AUDIO_CONTENT_TYPE="$2"
            shift 2
            ;;
        --chat-audio-first)
            CHAT_AUDIO_FIRST="true"
            shift
            ;;
        --prompt)
            PROMPT_FILE="$2"
            shift 2
            ;;
        --suffix)
            SUFFIX="$2"
            shift 2
            ;;
        --extra)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                EXTRA_ARGS+=("$1")
                shift
            done
            ;;
        --dataset|-ds)
            DATASET_FILTER="$2"
            shift 2
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        -h|--help)
            cat << 'HELPEOF'
Usage: transcribe.sh [OPTIONS]

Run transcription models and evaluate WER against ground truth.

Options:
  --lang LANG              Filter datasets by language (en|zh)
  --models, -m LIST        Space-separated keywords to filter models
                           Example: -m 'parakeet sensevoice'
  --device, -d DEVICE      Compute device: cpu, cuda, mps (default: cpu)
  --type, -t TYPE          Model type filter: local, gemini, vllm, mlx (default: local)
  --api-base-url URL       Server URL (required for --type vllm)
                           Example: http://localhost:8000/v1
  --api-mode MODE          API mode: transcriptions, chat, realtime
                           (default: transcriptions)
  --audio-content-type FMT  Audio content type in chat mode:
                           audio_url (vLLM), input_audio (mlx-vlm),
                           audio (Google native) (default: audio_url)
  --prompt FILE|TEXT       Custom prompt for transcription (file path or string)
  --suffix TAG             Append suffix to output filename and display name
                           e.g. --suffix dotey → file: model_dotey.ass, name: model(dotey)
  --dataset, -ds ID        Filter by dataset ID keyword
                           Available: OpenAI-Introducing-GPT-4o-First5mins
                                      OpenAI-Introducing-GPT-4o
                                      TheValley101-GPT-4o-vs-Gemini
                           Example: --dataset First5mins
  --force, -f              Re-run even if output exists
  -h, --help               Show this help

═══════════════════════════════════════════════════════════════════════════════

Local Models (--type local):

  NeMo (NVIDIA):
    nvidia/parakeet-tdt-0.6b-v3        0.6B, English-only, TDT CTC
    nvidia/canary-1b-v2                 1B, multilingual (24 langs), encoder-decoder

  SenseVoice (Alibaba):
    iic/SenseVoiceSmall                 multilingual (zh/en/ja/ko/yue), speech+event

  FunASR (Alibaba):
    FunAudioLLM/Fun-ASR-Nano-2512      lightweight, Chinese-focused
    FunAudioLLM/Fun-ASR-MLT-Nano-2512  lightweight, multilingual

═══════════════════════════════════════════════════════════════════════════════

Gemini API Models (--type gemini, requires GEMINI_API_KEY):

    gemini-2.5-pro                      highest accuracy, slowest
    gemini-2.5-flash                    balanced speed/quality
    gemini-2.5-flash-lite               fastest, lower accuracy
    gemini-3-flash-preview              next-gen flash
    gemini-3.1-pro-preview              next-gen pro
    gemini-3.1-flash-lite-preview       next-gen lite

═══════════════════════════════════════════════════════════════════════════════

vLLM/SGLang/OpenAI-Compatible Models (--type vllm, requires --api-base-url):

  ASR models (--api-mode transcriptions, works with mlx-audio/vLLM/faster-whisper):
    Qwen/Qwen3-ASR-0.6B                Qwen ASR 0.6B
    Qwen/Qwen3-ASR-1.7B                Qwen ASR 1.7B
    mistralai/Voxtral-Mini-4B-2602     Voxtral (--api-mode realtime)

  Multimodal LLMs (--api-mode chat, audio via chat completions):
    google/gemma-4-E2B-it               Gemma4 E2B (vLLM: audio_url)
    google/gemma-4-E4B-it               Gemma4 E4B (vLLM: audio_url)
    mlx-community/gemma-4-e4b-it-8bit  Gemma4 E4B 8bit (mlx-vlm: --audio-content-type input_audio)

═══════════════════════════════════════════════════════════════════════════════

Examples:
  # All local models on Apple Silicon
  ./scripts/transcribe.sh --device mps

  # Only Parakeet, English datasets
  ./scripts/transcribe.sh -m parakeet --lang en --device mps

  # Gemini models (API)
  ./scripts/transcribe.sh --type gemini -m "2.5-flash"

  # ASR via mlx-audio / vLLM (transcriptions endpoint)
  # mlx_audio.server --host 0.0.0.0 --port 8081
  ./scripts/transcribe.sh --type vllm --api-base-url http://localhost:8081/v1 \
                  --api-mode transcriptions -m "Qwen3-ASR"

  # Gemma4 via vLLM (chat endpoint, audio format)
  # vllm serve google/gemma-4-E4B-it --port 8083
  ./scripts/transcribe.sh --type vllm \
    --api-base-url http://localhost:8083/v1 \
    --api-mode chat \
    -m gemma-4-E2B-it gemma-4-e4b-it --audio-content-type audio_url

  # Gemma4 via mlx-vlm (chat endpoint, input_audio format)
  # mlx_vlm.server --trust-remote-code --port 8082
  ./scripts/transcribe.sh --type mlx --api-base-url http://localhost:8082/v1 \
    -m gemma-4-e4b-it-8bit
HELPEOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

# ============================================================================
# Model Registry
# ============================================================================
# Format: "type:model_id:lang_support:short_name"
#   type:         local, gemini, vllm, mlx
#   lang_support: en = English only, multi = multilingual

LOCAL_MODELS=(
    "local:nvidia/parakeet-tdt-0.6b-v3:en:parakeet-0.6b"
    "local:nvidia/canary-1b-v2:multi:canary-1b"
    "local:iic/SenseVoiceSmall:multi:sensevoice"
    "local:FunAudioLLM/Fun-ASR-Nano-2512:multi:funasr-nano"
    "local:FunAudioLLM/Fun-ASR-MLT-Nano-2512:multi:funasr-mlt-nano"
)

GEMINI_MODELS=(
    "gemini:gemini-2.5-pro:multi:gemini-2.5-pro"
    "gemini:gemini-2.5-flash:multi:gemini-2.5-flash"
    "gemini:gemini-2.5-flash-lite:multi:gemini-2.5-flash-lite"
    "gemini:gemini-3-flash-preview:multi:gemini-3-flash"
    "gemini:gemini-3.1-pro-preview:multi:gemini-3.1-pro"
    "gemini:gemini-3.1-flash-lite-preview:multi:gemini-3.1-flash-lite"
)

# Requires --api-base-url
VLLM_MODELS=(
    "vllm:Qwen/Qwen3-ASR-0.6B:multi:vllm-qwen3-asr-0.6b"
    "vllm:Qwen/Qwen3-ASR-1.7B:multi:vllm-qwen3-asr-1.7b"
    "vllm:mistralai/Voxtral-Mini-4B-Realtime-2602:multi:voxtral-mini-4b"
    "vllm:google/gemma-4-E2B-it:multi:vllm-gemma4-e2b-it"
    "vllm:google/gemma-4-E4B-it:multi:vllm-gemma4-e4b-it"
)

# mlx-vlm / mlx-audio served models (Apple Silicon); uses --api-mode chat --audio-content-type input_audio
MLX_MODELS=(
    "mlx:mlx-community/gemma-4-e4b-it-8bit:multi:mlx-gemma4-e4b-it-8bit"
    "mlx:mlx-community/gemma-4-e4b-it-4bit:multi:mlx-gemma4-e4b-it-4bit"
    "mlx:google/gemma-4-E2B-it:multi:mlx-gemma4-e2b-it"
)

# Assemble MODELS based on --type filter
MODELS=()
case "$TYPE_FILTER" in
    local)  MODELS=("${LOCAL_MODELS[@]}") ;;
    gemini) MODELS=("${GEMINI_MODELS[@]}") ;;
    vllm)   MODELS=("${VLLM_MODELS[@]}") ;;
    mlx)    MODELS=("${MLX_MODELS[@]}") ;;
    "")     MODELS=("${LOCAL_MODELS[@]}") ;;  # Default: local models only
    *)      print_error "Unknown type: $TYPE_FILTER (expected: local, gemini, vllm, mlx)"; exit 1 ;;
esac

# ---------- Datasets ----------
ALL_DATASETS=(
    "OpenAI-Introducing-GPT-4o:en"
    "OpenAI-Introducing-GPT-4o-First5mins:en"
    "TheValley101-GPT-4o-vs-Gemini:zh"
)

# Filter datasets by language and/or dataset ID keyword
DATASETS=()
for ds in "${ALL_DATASETS[@]}"; do
    ds_id="${ds%%:*}"
    ds_lang="${ds##*:}"
    [ -n "$LANG_FILTER" ] && [ "$ds_lang" != "$LANG_FILTER" ] && continue
    [ -n "$DATASET_FILTER" ] && [[ "$ds_id" != *"$DATASET_FILTER"* ]] && continue
    DATASETS+=("$ds")
done

if [ ${#DATASETS[@]} -eq 0 ]; then
    print_error "No datasets match language '$LANG_FILTER'"
    exit 1
fi

# ============================================================================
# Helpers
# ============================================================================
model_matches_filter() {
    local model="$1"
    [ -z "$MODEL_FILTER" ] && return 0
    for m in $MODEL_FILTER; do
        [[ "$model" == *"$m"* ]] && return 0
    done
    return 1
}

model_supports_lang() {
    local model_lang="$1"   # "en" or "multi"
    local dataset_lang="$2" # "en" or "zh"
    [ "$model_lang" = "multi" ] && return 0
    [ "$model_lang" = "$dataset_lang" ] && return 0
    return 1
}

# Build CLI args into global CLI_ARGS array (avoids word-splitting on spaces in values)
build_transcribe_args() {
    local model_type="$1"
    local model_id="$2"
    local audio_file="$3"
    local output_file="$4"
    local transcribe_lang="$5"

    CLI_ARGS=(
        "$audio_file"
        "$output_file"
        "transcription.model_name=$model_id"
        "transcription.language=$transcribe_lang"
    )

    if [ -n "$PROMPT_FILE" ]; then
        CLI_ARGS+=("transcription.prompt=$PROMPT_FILE")
    fi

    case "$model_type" in
        local)
            CLI_ARGS+=("transcription.device=$DEVICE")
            ;;
        gemini)
            # Gemini API key from env (TranscriptionConfig reads GEMINI_API_KEY automatically)
            ;;
        vllm)
            CLI_ARGS+=("transcription.api_base_url=$API_BASE_URL")
            CLI_ARGS+=("transcription.api_mode=$API_MODE")
            if [ -n "$AUDIO_CONTENT_TYPE" ]; then
                CLI_ARGS+=("transcription.audio_content_type=$AUDIO_CONTENT_TYPE")
            fi
            if [ "$CHAT_AUDIO_FIRST" = "true" ]; then
                CLI_ARGS+=("transcription.chat_audio_first=true")
            fi
            ;;
        mlx)
            CLI_ARGS+=("transcription.api_base_url=$API_BASE_URL")
            CLI_ARGS+=("transcription.api_mode=${API_MODE:-chat}")
            CLI_ARGS+=("transcription.audio_content_type=${AUDIO_CONTENT_TYPE:-input_audio}")
            if [ "$CHAT_AUDIO_FIRST" = "true" ]; then
                CLI_ARGS+=("transcription.chat_audio_first=true")
            fi
            ;;
    esac

    # Append any extra args passed via --extra
    if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
        CLI_ARGS+=("${EXTRA_ARGS[@]}")
    fi
}

# Output directory for transcription results
OUTPUT_ROOT="${PROJECT_DIR}/outputs/transcribe"

# ============================================================================
# Validation
# ============================================================================
if [ "$TYPE_FILTER" = "gemini" ] && [ -z "$GEMINI_API_KEY" ]; then
    print_error "GEMINI_API_KEY not set. Required for --type gemini."
    exit 1
fi

if [[ "$TYPE_FILTER" =~ ^(vllm|mlx)$ ]] && [ -z "$API_BASE_URL" ]; then
    print_error "--api-base-url is required for --type $TYPE_FILTER."
    exit 1
fi

# ============================================================================
# Step 1: Run transcription for each model × dataset
# ============================================================================
print_header "Step 1: Transcribing (device=$DEVICE)"

TOTAL=0
SKIPPED=0
FAILED=0

for ds_entry in "${DATASETS[@]}"; do
    dataset_id="${ds_entry%%:*}"
    ds_lang="${ds_entry##*:}"
    audio_file="${DATA_ROOT}/${dataset_id}/audio.mp3"

    if [ ! -f "$audio_file" ]; then
        print_warning "audio.mp3 not found for $dataset_id — skipping"
        continue
    fi

    for model_entry in "${MODELS[@]}"; do
        IFS=':' read -r model_type model_id model_lang short_name <<< "$model_entry"

        # Model name and language filters
        model_matches_filter "$model_id" || continue
        model_supports_lang "$model_lang" "$ds_lang" || continue

        # vLLM/mlx requires api-base-url even when type filter matches
        if [[ "$model_type" =~ ^(vllm|mlx)$ ]] && [ -z "$API_BASE_URL" ]; then
            print_warning "Skipping $short_name — --api-base-url not set"
            continue
        fi

        TOTAL=$((TOTAL + 1))

        output_dir="${OUTPUT_ROOT}/${dataset_id}"
        display_name="${short_name}"
        file_name="${short_name}"
        if [ -n "$SUFFIX" ]; then
            file_name="${short_name}_${SUFFIX}"
            display_name="${short_name}(${SUFFIX})"
        fi
        output_file="${output_dir}/${file_name}.ass"

        echo ""
        print_step "${display_name} (${model_type}) → ${dataset_id}"

        # Skip if output exists (unless --force)
        if [ -f "$output_file" ] && [ "$FORCE" != "true" ]; then
            echo "  ⏭ Skipping (already exists)"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        mkdir -p "$output_dir"

        transcribe_lang="$ds_lang"

        # Build and run transcription command
        build_transcribe_args "$model_type" "$model_id" "$audio_file" "$output_file" "$transcribe_lang"

        echo "  \$ lai transcribe run -Y -v ${CLI_ARGS[*]}"

        if lai transcribe run -Y -v "${CLI_ARGS[@]}" 2>&1; then
            print_info "  ✓ Saved: ${output_file}"
        else
            print_error "  ✗ Failed: ${short_name} on ${dataset_id}"
            FAILED=$((FAILED + 1))
        fi
    done
done

echo ""
print_info "Transcription: total=$TOTAL, skipped=$SKIPPED, failed=$FAILED"

# ============================================================================
# Step 2: Evaluate WER
# ============================================================================
print_header "Step 2: Evaluating WER"

RESULTS_FILE=$(mktemp)

for ds_entry in "${DATASETS[@]}"; do
    dataset_id="${ds_entry%%:*}"
    ds_lang="${ds_entry##*:}"
    ref_file="${DATA_ROOT}/${dataset_id}/ground_truth.ass"

    if [ ! -f "$ref_file" ]; then
        print_warning "ground_truth.ass not found for $dataset_id — skipping eval"
        continue
    fi

    output_dir="${OUTPUT_ROOT}/${dataset_id}"
    if [ ! -d "$output_dir" ]; then
        continue
    fi

    # Evaluate all .ass files in the output directory
    for hyp_file in "$output_dir"/*.ass; do
        [ -f "$hyp_file" ] || continue
        model_name="$(basename "${hyp_file%.ass}")"

        echo ""
        print_step "Evaluating: ${model_name} (${dataset_id})"

        result=$(run_eval_json "$ref_file" "$hyp_file" "true" "wer")
        if [ -n "$result" ]; then
            echo "{\"dataset\": \"$dataset_id\", \"model\": \"$model_name\", \"metrics\": $result}" >> "$RESULTS_FILE"
        else
            print_warning "  Eval returned empty result"
        fi
    done
done

# ============================================================================
# Step 3: Summary table (WER only)
# ============================================================================
print_header "WER Summary"

if [ ! -s "$RESULTS_FILE" ]; then
    print_warning "No results to display."
else
    print_summary_table "$RESULTS_FILE" "wer"
fi

rm -f "$RESULTS_FILE"

print_header "Transcription Benchmark Complete"
