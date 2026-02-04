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
# NOTE: Different prompts must use different output_dir to avoid .ass file conflicts
CONFIGS=(
    # "gemini-2.5-pro:prompts/Gemini_dotey.md:data:(dotey)"
    # "gemini-2.5-pro:prompts/Gemini_dotey.md:outputs/2.5pro_run2:(dotey run2)"
    "gemini-3-pro-preview:prompts/Gemini_dotey.md:data:(dotey)"
    "gemini-3-pro-preview:prompts/Gemini_dotey.md:outputs/3pro_run2:(dotey run2)"
    "gemini-3-flash-preview:prompts/Gemini_dotey.md:data:(dotey)"
    "gemini-3-flash-preview:prompts/Gemini_dotey.md:outputs/V1_1:(dotey run2)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_StartEnd.md:outputs/StartEnd_V1:(StartEnd)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_StartEnd.md:outputs/StartEnd_V1_2:(StartEnd run2)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_Precise.md:outputs/PreciseEnd_V1:(Precise)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_Precise.md:outputs/PreciseEnd_V1_2:(Precise run2)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_SRT.md:outputs/SRT_dotey:(SRT dotey)"
    "gemini-3-flash-preview:prompts/Gemini_dotey_SRT.md:outputs/SRT_dotey_2:(SRT dotey run2)"
    "gemini-3-flash-preview:prompts/Gemini_SRT_V2.md:outputs/SRT_V2:(SRT V2)"
    "gemini-3-flash-preview:prompts/Gemini_SRT_V2.md:outputs/SRT_V2_2:(SRT V2 run2)"
)

# ============================================================================
# Step 1: Run all transcriptions
# ============================================================================
print_header "Step 1: Transcribing (skips existing files)"

# Helper function to determine output extension from prompt file
get_output_ext() {
    local prompt="$1"
    if [[ "$prompt" == *"SRT"* ]] || [[ "$prompt" == *"srt"* ]]; then
        echo ".srt"
    else
        echo ".md"
    fi
}

for ds_entry in "${DATASETS[@]}"; do
    dataset_id="${ds_entry%%:*}"

    for config in "${CONFIGS[@]}"; do
        IFS=':' read -r model prompt output_dir tag <<< "$config"

        output_ext=$(get_output_ext "$prompt")
        target_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}${output_ext}"

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

# Wrapper function to handle alignment failures gracefully
# Creates .failed marker on failure, skips if marker exists (unless input is newer)
run_alignment() {
    local audio="$1"
    local input="$2"
    local output="$3"
    local label="$4"
    local failed_marker="${output}.failed"

    # Skip if failed marker exists and input is not newer
    if [ -f "$failed_marker" ] && [ ! "$input" -nt "$failed_marker" ]; then
        echo "  ⏭ Skipping (previously failed)"
        return 1
    fi

    # Remove stale failed marker if input is newer
    [ -f "$failed_marker" ] && rm -f "$failed_marker"

    if lai alignment align -Y "$audio" \
        alignment.model_hub=modelscope \
        client.profile=true \
        caption.include_speaker_in_text=false \
        caption.split_sentence=true \
        caption.input_path="$input" \
        caption.output_path="$output" 2>&1; then
        return 0
    else
        print_warning "Alignment failed: $label"
        touch "$failed_marker"
        return 1
    fi
}

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

            # Align YouTube Caption (official) if exists
            caption_file=$(get_dataset_info "$dataset_id" "caption")
            if [ -n "$caption_file" ]; then
                caption_path="${DATA_ROOT}/${dataset_id}/${caption_file}"
                caption_basename="${caption_file%.*}"
                caption_ass="${DATA_ROOT}/${dataset_id}/${caption_basename}.ass"
                yt_output_file="${DATA_ROOT}/${dataset_id}/${caption_basename}_LattifAI.ass"

                if [ -f "$caption_path" ]; then
                    # Convert to ASS if source is newer
                    if needs_update "$caption_path" "$caption_ass"; then
                        echo ""
                        print_step "Converting ${caption_file} → ${caption_basename}.ass"
                        convert_if_needed "$caption_path" "$caption_ass"
                    fi

                    echo ""
                    print_step "YouTube Caption (official) → ${caption_basename}_LattifAI.ass"

                    if [ -f "$yt_output_file" ]; then
                        echo "  ⏭ Skipping (already exists)"
                    else
                        run_alignment "$audio_file" "$caption_ass" "$yt_output_file" \
                            "YouTube Caption (official)" || true
                    fi
                fi
            fi

            for config in "${CONFIGS[@]}"; do
                IFS=':' read -r model prompt output_dir tag <<< "$config"

                output_ext=$(get_output_ext "$prompt")
                input_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}${output_ext}"
                output_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}_LattifAI.ass"

                if [ ! -f "$input_file" ]; then
                    continue
                fi

                echo ""
                print_step "${model} ${tag} → ${model}_LattifAI.ass"

                if [ -f "$output_file" ]; then
                    echo "  ⏭ Skipping (already exists)"
                    continue
                fi

                run_alignment "$audio_file" "$input_file" "$output_file" \
                    "${model} ${tag}" || true
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

    ref_file="${DATA_ROOT}/${dataset_id}/ground_truth.ass"

    # Evaluate official YouTube caption if exists
    caption_file=$(get_dataset_info "$dataset_id" "caption")
    if [ -n "$caption_file" ]; then
        caption_basename="${caption_file%.*}"
        caption_ass="${DATA_ROOT}/${dataset_id}/${caption_basename}.ass"
        yt_lattifai_file="${DATA_ROOT}/${dataset_id}/${caption_basename}_LattifAI.ass"

        # Use converted .ass if exists, otherwise use original
        if [ -f "$caption_ass" ]; then
            echo ""
            print_step "Evaluating: YouTube Caption (official)"
            result=$(run_eval_json "$ref_file" "$caption_ass")
            echo "{\"dataset\": \"$dataset_id\", \"model\": \"YouTube Caption (official)\", \"metrics\": $result}" >> "$RESULTS_FILE"
        fi

        # Evaluate LattifAI aligned YouTube caption
        if [ -f "$yt_lattifai_file" ]; then
            echo ""
            print_step "Evaluating: YouTube Caption (official) +LattifAI"
            result=$(run_eval_json "$ref_file" "$yt_lattifai_file")
            echo "{\"dataset\": \"$dataset_id\", \"model\": \"YouTube Caption (official) +LattifAI\", \"metrics\": $result}" >> "$RESULTS_FILE"
        fi
    fi

    for config in "${CONFIGS[@]}"; do
        IFS=':' read -r model prompt output_dir tag <<< "$config"

        output_ext=$(get_output_ext "$prompt")
        input_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}${output_ext}"
        hyp_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}.ass"
        lattifai_file="${PROJECT_DIR}/${output_dir}/${dataset_id}/${model}_LattifAI.ass"
        model_name="${model} ${tag}"

        # Convert input file (.md or .srt) to .ass if source is newer
        if [ -f "$input_file" ] && needs_update "$input_file" "$hyp_file"; then
            convert_if_needed "$input_file" "$hyp_file"
        fi

        # Evaluate raw Gemini output
        if [ -f "$hyp_file" ]; then
            echo ""
            print_step "Evaluating: $model_name"
            result=$(run_eval_json "$ref_file" "$hyp_file")
            echo "{\"dataset\": \"$dataset_id\", \"model\": \"$model_name\", \"metrics\": $result}" >> "$RESULTS_FILE"
        fi

        # Evaluate LattifAI aligned output
        if [ -f "$lattifai_file" ]; then
            echo ""
            print_step "Evaluating: ${model_name} +LattifAI"
            result=$(run_eval_json "$ref_file" "$lattifai_file")
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
