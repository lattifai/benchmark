#!/bin/bash
# Temperature benchmark script
# Tests different temperature values for Gemini transcription

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
DATASET_ID="OpenAI-Introducing-GPT-4o-First5mins"
MODEL="gemini-3-flash-preview"
PROMPT="prompts/Gemini_dotey.md"
OUTPUT_BASE="outputs/temperature"

# Temperature values to test (format: value:run)
TEMPERATURES=(
    "1.0:1"   # temperature 1.0, run 1
    "1.0:2"   # temperature 1.0, run 2
    "0.5:1"   # temperature 0.5, run 1
    "0.5:2"   # temperature 0.5, run 2
    "0.1:1"   # temperature 0.1, run 1
    "0.1:2"   # temperature 0.1, run 2
)

# ============================================================================
# Step 1: Run all transcriptions
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "  Step 1: Transcribing with different temperatures"
echo "═══════════════════════════════════════════════════════════════"

for entry in "${TEMPERATURES[@]}"; do
    temp="${entry%%:*}"
    run="${entry##*:}"

    # Create output directory name (replace . with empty)
    temp_clean="${temp//./}"
    output_dir="${OUTPUT_BASE}/t${temp_clean}_r${run}"
    target_file="${output_dir}/${DATASET_ID}/${MODEL}.md"

    echo ""
    echo "▶ Temperature: $temp (run $run) → $output_dir"

    # Skip if target file already exists
    if [ -f "$target_file" ]; then
        echo "  ⏭ Skipping (already exists: $target_file)"
        continue
    fi

    if [ "$temp" = "1.0" ]; then
        # Default temperature (don't pass --temperature)
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
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Step 2: Evaluating all results"
echo "═══════════════════════════════════════════════════════════════"

PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data"
RESULTS_FILE=$(mktemp)

for entry in "${TEMPERATURES[@]}"; do
    temp="${entry%%:*}"
    run="${entry##*:}"

    temp_clean="${temp//./}"
    output_dir="${OUTPUT_BASE}/t${temp_clean}_r${run}"
    hyp_file="${output_dir}/${DATASET_ID}/${MODEL}.ass"
    ref_file="${DATA_DIR}/${DATASET_ID}/ground_truth.ass"
    model_name="${MODEL} (temp=${temp}, run${run})"

    echo ""
    echo "▶ Evaluating: $model_name"

    # Convert .md to .ass if needed
    md_file="${output_dir}/${DATASET_ID}/${MODEL}.md"
    if [ -f "$md_file" ] && [ ! -f "$hyp_file" ]; then
        lai caption convert -Y "$md_file" "$hyp_file" 2>/dev/null || true
    fi

    if [ ! -f "$hyp_file" ]; then
        echo "  ⚠ Skipping (file not found: $hyp_file)"
        continue
    fi

    # Run eval and collect JSON output (compact to single line)
    result=$(python "$PROJECT_DIR/eval.py" \
        -r "$ref_file" \
        -hyp "$hyp_file" \
        --metrics der jer wer sca scer \
        --skip-events \
        --language en \
        --format json 2>/dev/null | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)))")

    # Append result with model name
    echo "{\"model\": \"$model_name\", \"metrics\": $result}" >> "$RESULTS_FILE"
done

# ============================================================================
# Step 3: Output summary table
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Summary Table"
echo "═══════════════════════════════════════════════════════════════"
echo ""

python3 << EOF
import json

results = []
with open("$RESULTS_FILE") as f:
    for line in f:
        if line.strip():
            results.append(json.loads(line))

if not results:
    print("No results found.")
else:
    # Calculate max model name width
    max_model_len = max(len(r["model"]) for r in results)
    max_model_len = max(max_model_len, 5)  # At least "Model" width

    # Format metric value
    def fmt(val):
        return f"{val:.4f} ({val*100:5.2f}%)"

    metric_width = 16  # "0.1234 (12.34%)"

    # Print header
    header = f"| {'Model':<{max_model_len}} | {'DER ↓':^{metric_width}} | {'JER ↓':^{metric_width}} | {'WER ↓':^{metric_width}} | {'SCA ↑':^{metric_width}} | {'SCER ↓':^{metric_width}} |"
    separator = f"|{'-' * (max_model_len + 2)}|{'-' * (metric_width + 2)}|{'-' * (metric_width + 2)}|{'-' * (metric_width + 2)}|{'-' * (metric_width + 2)}|{'-' * (metric_width + 2)}|"

    print(header)
    print(separator)

    # Print rows
    for r in results:
        m = r["metrics"]
        # der can be a dict with detailed info
        der_val = m.get("der", 0)
        if isinstance(der_val, dict):
            der_val = der_val.get("diarization error rate", 0)
        jer = m.get("jer", 0)
        wer = m.get("wer", 0)
        sca = m.get("sca", 0)
        scer = m.get("scer", 0)
        row = f"| {r['model']:<{max_model_len}} | {fmt(der_val):^{metric_width}} | {fmt(jer):^{metric_width}} | {fmt(wer):^{metric_width}} | {fmt(sca):^{metric_width}} | {fmt(scer):^{metric_width}} |"
        print(row)
EOF

rm -f "$RESULTS_FILE"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Temperature Benchmark Complete"
echo "═══════════════════════════════════════════════════════════════"

exit 0


python eval.py --verbose -r data/OpenAI-Introducing-GPT-4o-First5mins/ground_truth.ass \
    --hyp outputs/temperature/t10_r1/OpenAI-Introducing-GPT-4o-First5mins/gemini-3-flash-preview.ass \
    --metrics der jer wer sca scer --collar 0.0 --model-name "gemini-3-flash-preview temperature=1.0" --skip-events --language en
python eval.py --verbose -r outputs/temperature/t10_r1/OpenAI-Introducing-GPT-4o-First5mins/gemini-3-flash-preview.ass \
    --hyp outputs/temperature/t01_r1/OpenAI-Introducing-GPT-4o-First5mins/gemini-3-flash-preview.ass \
    --metrics der jer wer sca scer --collar 0.0 --model-name "gemini-3-flash-preview temperature=1.0" --skip-events --language en
