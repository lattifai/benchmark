#!/bin/bash
# Benchmark script for comparing different transcription configurations
# Runs transcription with various prompts/models and outputs unified results table

set -e

# Load common functions
source "$(dirname "$0")/common.sh"

# ============================================================================
# Configuration
# ============================================================================

# Datasets to benchmark (format: "dataset_id:language")
DATASETS=(
    "OpenAI-Introducing-GPT-4o:en"
    # "TheValley101-GPT-4o-vs-Gemini:zh"
)

# Test configurations (format: "model:prompt:output_dir:tag")
CONFIGS=(
    "gemini-2.5-pro:prompts/Gemini_dotey.md:data:(baseline)"
    "gemini-3-pro-preview:prompts/Gemini_dotey.md:data:(baseline)"
    "gemini-3-flash-preview:prompts/Gemini_dotey.md:data:(dotey)"
    "gemini-3-flash-preview:prompts/Gemini_dotey.md:outputs/V1_1:(dotey run2)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_StartEnd.md:outputs/StartEnd_V1:(StartEnd)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_StartEnd.md:outputs/StartEnd_V1_2:(StartEnd run2)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_Precise.md:outputs/PreciseEnd_V1:(Precise)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_Precise.md:outputs/PreciseEnd_V1_2:(Precise run2)"
)

# ============================================================================
# Step 1: Run all transcriptions
# ============================================================================
print_header "Step 1: Transcribing (skips existing files)"

for ds_entry in "${DATASETS[@]}"; do
    dataset_id="${ds_entry%%:*}"
    dataset_lang="${ds_entry##*:}"

    for config in "${CONFIGS[@]}"; do
        IFS=':' read -r model prompt output_dir tag <<< "$config"

        target_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}.md"

        echo ""
        print_step "${model} ${tag} → ${output_dir}/${dataset_id}"

        if [ -f "$target_file" ]; then
            echo "  ⏭ Skipping (already exists)"
            continue
        fi

        "$SCRIPT_DIR/run.sh" transcribe --local \
            --id "$dataset_id" \
            --models "$model" \
            -o "${PROJECT_DIR}/${output_dir}" \
            --prompt "$prompt"
    done
done

# ============================================================================
# Step 2: Run all evaluations and collect results
# ============================================================================
print_header "Step 2: Evaluating all results"

RESULTS_FILE=$(mktemp)

for ds_entry in "${DATASETS[@]}"; do
    dataset_id="${ds_entry%%:*}"
    dataset_lang="${ds_entry##*:}"

    ref_file="${DATA_ROOT}/${dataset_id}/ground_truth.ass"

    for config in "${CONFIGS[@]}"; do
        IFS=':' read -r model prompt output_dir tag <<< "$config"

        hyp_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}.ass"
        md_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}.md"
        model_name="${model} ${tag}"

        echo ""
        print_step "Evaluating: $model_name"

        # Convert .md to .ass if needed
        if [ -f "$md_file" ] && [ ! -f "$hyp_file" ]; then
            lai caption convert -Y "$md_file" "$hyp_file" 2>/dev/null || true
        fi

        if [ ! -f "$hyp_file" ]; then
            print_warning "Skipping (file not found: $hyp_file)"
            continue
        fi

        result=$(run_eval_json "$ref_file" "$hyp_file" "$dataset_lang")
        echo "{\"dataset\": \"$dataset_id\", \"model\": \"$model_name\", \"metrics\": $result}" >> "$RESULTS_FILE"
    done
done

# ============================================================================
# Step 3: Output summary table
# ============================================================================
print_header "Summary Table"

print_summary_table "$RESULTS_FILE"
rm -f "$RESULTS_FILE"

print_header "Benchmark Complete"
