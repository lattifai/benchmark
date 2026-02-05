#!/bin/bash
# Temperature benchmark script
# Tests different temperature values for Gemini transcription

set -e

# Load common functions
source "$(dirname "$0")/common.sh"

# Configuration
DATASET_ID="OpenAI-Introducing-GPT-4o-First5mins"
MODEL="gemini-3-flash-preview"
PROMPT="prompts/Gemini_dotey.md"
OUTPUT_BASE="outputs/temperature"

# Temperature values to test (format: value:run)
TEMPERATURES=(
    "1.0:1"
    "1.0:2"
    "0.5:1"
    "0.5:2"
    "0.1:1"
    "0.1:2"
)

# ============================================================================
# Step 1: Run all transcriptions
# ============================================================================
print_header "Step 1: Transcribing with different temperatures"

for entry in "${TEMPERATURES[@]}"; do
    temp="${entry%%:*}"
    run="${entry##*:}"

    temp_clean="${temp//./}"
    output_dir="${OUTPUT_BASE}/t${temp_clean}_r${run}"
    target_file="${output_dir}/${DATASET_ID}/${MODEL}.md"

    echo ""
    print_step "Temperature: $temp (run $run) → $output_dir"

    if [ -f "$target_file" ]; then
        echo "  ⏭ Skipping (already exists: $target_file)"
        continue
    fi

    if [ "$temp" = "1.0" ]; then
        "$SCRIPT_DIR/run.sh" transcribe --local \
            --id "$DATASET_ID" \
            --models "$MODEL" \
            -o "$output_dir" \
            --prompt "$PROMPT"
    else
        "$SCRIPT_DIR/run.sh" transcribe --local \
            --id "$DATASET_ID" \
            --models "$MODEL" \
            -o "$output_dir" \
            --prompt "$PROMPT" \
            --temperature "$temp"
    fi
done

# ============================================================================
# Step 2: Run all evaluations and collect results
# ============================================================================
print_header "Step 2: Evaluating all results"

RESULTS_FILE=$(mktemp)

for entry in "${TEMPERATURES[@]}"; do
    temp="${entry%%:*}"
    run="${entry##*:}"

    temp_clean="${temp//./}"
    output_dir="${OUTPUT_BASE}/t${temp_clean}_r${run}"
    hyp_file="${output_dir}/${DATASET_ID}/${MODEL}.ass"
    ref_file="${DATA_ROOT}/${DATASET_ID}/ground_truth.ass"
    model_name="${MODEL} (temp=${temp}, run${run})"

    echo ""
    print_step "Evaluating: $model_name"

    # Convert .md to .ass if source is newer
    md_file="${output_dir}/${DATASET_ID}/${MODEL}.md"
    if [ -f "$md_file" ] && needs_update "$md_file" "$hyp_file"; then
        convert_if_needed "$md_file" "$hyp_file"
    fi

    if [ ! -f "$hyp_file" ]; then
        print_warning "Skipping (file not found: $hyp_file)"
        continue
    fi

    result=$(run_eval_json "$ref_file" "$hyp_file" "true" "der jer wer")
    echo "{\"model\": \"$model_name\", \"metrics\": $result}" >> "$RESULTS_FILE"
done

# ============================================================================
# Step 3: Output summary table
# ============================================================================
print_header "Summary Table"

print_summary_table "$RESULTS_FILE" "der jer wer"
rm -f "$RESULTS_FILE"

print_header "Temperature Benchmark Complete"
