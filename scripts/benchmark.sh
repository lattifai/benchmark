#!/bin/bash
# Benchmark script for comparing different transcription configurations
# Runs transcription with various prompts/models and outputs unified results table

set -e

# Load common functions
source "$(dirname "$0")/common.sh"

# ============================================================================
# Configuration
# ============================================================================

# Set to "true" to run LattifAI alignment after transcription
RUN_ALIGNMENT="true"

# Datasets to benchmark (format: "dataset_id:language")
DATASETS=(
    "OpenAI-Introducing-GPT-4o:en"
    # "TheValley101-GPT-4o-vs-Gemini:zh"
)

# Test configurations (format: "model:prompt:output_dir:tag")
CONFIGS=(
    "gemini-2.5-pro:prompts/Gemini_dotey.md:data:(dotey)"
    "gemini-2.5-pro:prompts/Gemini_dotey.md:outputs/2.5pro_run2:(dotey run2)"
    "gemini-3-pro-preview:prompts/Gemini_dotey.md:data:(dotey)"
    "gemini-3-pro-preview:prompts/Gemini_dotey.md:outputs/3pro_run2:(dotey run2)"
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

        "$SCRIPT_DIR/run.sh" transcribe \
            --id "$dataset_id" \
            --models "$model" \
            -o "${PROJECT_DIR}/${output_dir}" \
            --prompt "$prompt"
    done
done

# ============================================================================
# Step 2: Run LattifAI alignment (optional)
# ============================================================================
if [ "$RUN_ALIGNMENT" = "true" ]; then
    print_header "Step 2: Aligning with LattifAI (skips existing files)"

    if [ -z "$LATTIFAI_API_KEY" ]; then
        print_warning "LATTIFAI_API_KEY not set. Skipping alignment."
    else
        for ds_entry in "${DATASETS[@]}"; do
            dataset_id="${ds_entry%%:*}"
            audio_file="${DATA_ROOT}/${dataset_id}/audio.mp3"

            if [ ! -f "$audio_file" ]; then
                print_warning "audio.mp3 not found for $dataset_id"
                continue
            fi

            for config in "${CONFIGS[@]}"; do
                IFS=':' read -r model prompt output_dir tag <<< "$config"

                md_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}.md"
                output_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}_LattifAI.ass"

                if [ ! -f "$md_file" ]; then
                    continue
                fi

                echo ""
                print_step "${model} ${tag} → ${model}_LattifAI.ass"

                if [ -f "$output_file" ]; then
                    echo "  ⏭ Skipping (already exists)"
                    continue
                fi

                lai alignment align -Y "$audio_file" \
                    client.profile=true \
                    caption.include_speaker_in_text=false \
                    caption.split_sentence=true \
                    caption.input_path="$md_file" \
                    caption.output_path="$output_file"
            done
        done
    fi
fi

# ============================================================================
# Step 3: Run all evaluations and collect results
# ============================================================================
print_header "Step 3: Evaluating all results"

RESULTS_FILE=$(mktemp)

for ds_entry in "${DATASETS[@]}"; do
    dataset_id="${ds_entry%%:*}"
    dataset_lang="${ds_entry##*:}"

    ref_file="${DATA_ROOT}/${dataset_id}/ground_truth.ass"

    # Evaluate official YouTube caption if exists
    caption_file=$(get_dataset_info "$dataset_id" "caption")
    if [ -n "$caption_file" ]; then
        caption_path="${DATA_ROOT}/${dataset_id}/${caption_file}"
        if [ -f "$caption_path" ]; then
            echo ""
            print_step "Evaluating: YouTube Caption (official)"
            result=$(run_eval_json "$ref_file" "$caption_path" "$dataset_lang")
            echo "{\"dataset\": \"$dataset_id\", \"model\": \"YouTube Caption (official)\", \"metrics\": $result}" >> "$RESULTS_FILE"
        fi
    fi

    for config in "${CONFIGS[@]}"; do
        IFS=':' read -r model prompt output_dir tag <<< "$config"

        md_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}.md"
        hyp_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}.ass"
        lattifai_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}_LattifAI.ass"
        model_name="${model} ${tag}"

        # Convert .md to .ass if needed
        if [ -f "$md_file" ] && [ ! -f "$hyp_file" ]; then
            lai caption convert -Y "$md_file" "$hyp_file" 2>/dev/null || true
        fi

        # Evaluate raw Gemini output
        if [ -f "$hyp_file" ]; then
            echo ""
            print_step "Evaluating: $model_name"
            result=$(run_eval_json "$ref_file" "$hyp_file" "$dataset_lang")
            echo "{\"dataset\": \"$dataset_id\", \"model\": \"$model_name\", \"metrics\": $result}" >> "$RESULTS_FILE"
        fi

        # Evaluate LattifAI aligned output
        if [ -f "$lattifai_file" ]; then
            echo ""
            print_step "Evaluating: ${model_name} +LattifAI"
            result=$(run_eval_json "$ref_file" "$lattifai_file" "$dataset_lang")
            echo "{\"dataset\": \"$dataset_id\", \"model\": \"${model_name} +LattifAI\", \"metrics\": $result}" >> "$RESULTS_FILE"
        fi
    done
done

# ============================================================================
# Step 4: Output summary table
# ============================================================================
print_header "Summary Table"

print_summary_table "$RESULTS_FILE"
rm -f "$RESULTS_FILE"

print_header "Benchmark Complete"
