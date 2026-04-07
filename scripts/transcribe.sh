#!/bin/bash
# Transcription benchmark: run ASR models via `lai transcribe run` and measure WER
# Supports three model types: local, Gemini API, and vLLM/SGLang served models.
#
# Usage: ./transcribe.sh [OPTIONS]
#
# Examples:
#   ./transcribe.sh                                          # All local models
#   ./transcribe.sh --lang en --device mps                   # English, Apple Silicon
#   ./transcribe.sh -m "parakeet sensevoice"                 # Filter by keyword
#   ./transcribe.sh --type gemini                            # Gemini API models only
#   ./transcribe.sh --type vllm --api-base-url http://localhost:8000/v1  # vLLM models

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
  --type, -t TYPE          Model type filter: local, gemini, vllm (default: all)
  --api-base-url URL       vLLM/SGLang server URL (required for --type vllm)
                           Example: http://localhost:8000/v1
  --api-mode MODE          vLLM API mode: transcriptions, chat, realtime
                           (default: transcriptions)
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

  Qwen3-ASR (Alibaba):
    Qwen/Qwen3-ASR-0.6B                0.6B, multilingual
    Qwen/Qwen3-ASR-1.7B                1.7B, multilingual, higher accuracy

  Gemma 4 (Google):
    google/gemma-4-E2B                  2B, multilingual, 30s audio limit
    google/gemma-4-E2B-it               2B, instruction-tuned
    google/gemma-4-E4B                  4B, multilingual, 30s audio limit
    google/gemma-4-E4B-it               4B, instruction-tuned

═══════════════════════════════════════════════════════════════════════════════

Gemini API Models (--type gemini, requires GEMINI_API_KEY):

    gemini-2.5-pro                      highest accuracy, slowest
    gemini-2.5-flash                    balanced speed/quality
    gemini-2.5-flash-lite               fastest, lower accuracy
    gemini-3-flash-preview              next-gen flash
    gemini-3.1-pro-preview              next-gen pro
    gemini-3.1-flash-lite-preview       next-gen lite

═══════════════════════════════════════════════════════════════════════════════

vLLM/SGLang Models (--type vllm, requires --api-base-url):

    openai/whisper-large-v3-turbo       Whisper via vLLM (--api-mode transcriptions)
    Qwen/Qwen3-ASR-0.6B                Qwen ASR via SGLang (--api-mode chat)
    Qwen/Qwen3-ASR-1.7B                Qwen ASR via SGLang (--api-mode chat)
    THUDM/GLM-ASR-Nano-2512            GLM ASR via vLLM (--api-mode chat)
    mistralai/Voxtral-Mini-4B-2602     Voxtral via WebSocket (--api-mode realtime)
    VibeVoice                           VibeVoice via vLLM (--api-mode transcriptions)

  Usage: ./transcribe.sh --type vllm --api-base-url http://localhost:8000/v1 \
                          --api-mode chat -m "Qwen3-ASR"

═══════════════════════════════════════════════════════════════════════════════

Examples:
  # All local models on Apple Silicon
  ./transcribe.sh --device mps

  # Only Parakeet, English datasets
  ./transcribe.sh -m parakeet --lang en --device mps

  # Gemini models (API)
  ./transcribe.sh --type gemini -m "2.5-flash"

  # Qwen3-ASR via SGLang server
  ./transcribe.sh --type vllm --api-base-url http://localhost:8000/v1 \
                  --api-mode chat -m "Qwen3-ASR-1.7B"
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
#   type:         local, gemini, vllm
#   lang_support: en = English only, multi = multilingual
MODELS=(
    # --- Local models ---
    "local:nvidia/parakeet-tdt-0.6b-v3:en:parakeet-0.6b"
    "local:nvidia/canary-1b-v2:multi:canary-1b"
    "local:iic/SenseVoiceSmall:multi:sensevoice"
    "local:FunAudioLLM/Fun-ASR-Nano-2512:multi:funasr-nano"
    "local:FunAudioLLM/Fun-ASR-MLT-Nano-2512:multi:funasr-mlt-nano"
    "local:Qwen/Qwen3-ASR-0.6B:multi:qwen3-asr-0.6b"
    "local:Qwen/Qwen3-ASR-1.7B:multi:qwen3-asr-1.7b"
    "local:google/gemma-4-E2B:multi:gemma4-e2b"
    "local:google/gemma-4-E2B-it:multi:gemma4-e2b-it"
    "local:google/gemma-4-E4B:multi:gemma4-e4b"
    "local:google/gemma-4-E4B-it:multi:gemma4-e4b-it"

    # --- Gemini API models ---
    "gemini:gemini-2.5-pro:multi:gemini-2.5-pro"
    "gemini:gemini-2.5-flash:multi:gemini-2.5-flash"
    "gemini:gemini-2.5-flash-lite:multi:gemini-2.5-flash-lite"
    "gemini:gemini-3-flash-preview:multi:gemini-3-flash"
    "gemini:gemini-3.1-pro-preview:multi:gemini-3.1-pro"
    "gemini:gemini-3.1-flash-lite-preview:multi:gemini-3.1-flash-lite"

    # --- vLLM/SGLang models ---
    "vllm:openai/whisper-large-v3-turbo:multi:whisper-v3-turbo"
    "vllm:Qwen/Qwen3-ASR-0.6B:multi:vllm-qwen3-asr-0.6b"
    "vllm:Qwen/Qwen3-ASR-1.7B:multi:vllm-qwen3-asr-1.7b"
    "vllm:THUDM/GLM-ASR-Nano-2512:multi:glm-asr-nano"
    "vllm:mistralai/Voxtral-Mini-4B-Realtime-2602:multi:voxtral-mini-4b"
)

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

# Build CLI args for a given model type
build_transcribe_args() {
    local model_type="$1"
    local model_id="$2"
    local audio_file="$3"
    local output_file="$4"
    local transcribe_lang="$5"

    local args=(
        "$audio_file"
        "$output_file"
        "transcription.model_name=$model_id"
        "transcription.language=$transcribe_lang"
    )

    case "$model_type" in
        local)
            args+=("transcription.device=$DEVICE")
            ;;
        gemini)
            # Gemini API key from env (TranscriptionConfig reads GEMINI_API_KEY automatically)
            ;;
        vllm)
            args+=("transcription.api_base_url=$API_BASE_URL")
            args+=("transcription.api_mode=$API_MODE")
            ;;
    esac

    echo "${args[@]}"
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

if [ "$TYPE_FILTER" = "vllm" ] && [ -z "$API_BASE_URL" ]; then
    print_error "--api-base-url is required for --type vllm."
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

        # Type filter
        if [ -n "$TYPE_FILTER" ] && [ "$model_type" != "$TYPE_FILTER" ]; then
            continue
        fi

        # Default: skip gemini and vllm unless explicitly requested
        if [ -z "$TYPE_FILTER" ] && [ "$model_type" != "local" ]; then
            continue
        fi

        # Model name and language filters
        model_matches_filter "$model_id" || continue
        model_supports_lang "$model_lang" "$ds_lang" || continue

        # vLLM requires api-base-url even when type filter matches
        if [ "$model_type" = "vllm" ] && [ -z "$API_BASE_URL" ]; then
            print_warning "Skipping $short_name — --api-base-url not set"
            continue
        fi

        TOTAL=$((TOTAL + 1))

        output_dir="${OUTPUT_ROOT}/${dataset_id}"
        output_file="${output_dir}/${short_name}.ass"

        echo ""
        print_step "${short_name} (${model_type}) → ${dataset_id}"

        # Skip if output exists (unless --force)
        if [ -f "$output_file" ] && [ "$FORCE" != "true" ]; then
            echo "  ⏭ Skipping (already exists)"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        mkdir -p "$output_dir"

        transcribe_lang="$ds_lang"

        # Build and run transcription command
        read -ra cli_args <<< "$(build_transcribe_args "$model_type" "$model_id" "$audio_file" "$output_file" "$transcribe_lang")"

        echo "  \$ lai transcribe run -Y -v ${cli_args[*]}"

        if lai transcribe run -Y -v "${cli_args[@]}" 2>&1; then
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

    for model_entry in "${MODELS[@]}"; do
        IFS=':' read -r model_type model_id model_lang short_name <<< "$model_entry"

        # Apply same filters as Step 1
        if [ -n "$TYPE_FILTER" ] && [ "$model_type" != "$TYPE_FILTER" ]; then
            continue
        fi
        if [ -z "$TYPE_FILTER" ] && [ "$model_type" != "local" ]; then
            continue
        fi
        model_matches_filter "$model_id" || continue
        model_supports_lang "$model_lang" "$ds_lang" || continue

        hyp_file="${OUTPUT_ROOT}/${dataset_id}/${short_name}.ass"

        if [ ! -f "$hyp_file" ]; then
            continue
        fi

        echo ""
        print_step "Evaluating: ${short_name} (${dataset_id})"

        result=$(run_eval_json "$ref_file" "$hyp_file" "true" "wer")
        if [ -n "$result" ]; then
            echo "{\"dataset\": \"$dataset_id\", \"model\": \"$short_name\", \"metrics\": $result}" >> "$RESULTS_FILE"
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
