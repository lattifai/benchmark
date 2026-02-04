#!/bin/bash
# Run all benchmarks and update README.md with results
# Usage: ./scripts/update_readme.sh [--skip-run]

set -e

source "$(dirname "$0")/common.sh"

README="$PROJECT_DIR/README.md"
RESULTS_DIR="$PROJECT_DIR/.benchmark_results"
mkdir -p "$RESULTS_DIR"

SKIP_RUN="false"
if [ "$1" = "--skip-run" ]; then
    SKIP_RUN="true"
fi

# ============================================================================
# Run all benchmarks (unless --skip-run)
# ============================================================================

if [ "$SKIP_RUN" = "false" ]; then
    print_header "1. Temperature Benchmark"
    "$SCRIPT_DIR/temperature.sh" 2>&1 | tee "$RESULTS_DIR/temperature.log"

    print_header "2. URL vs Local (with Thinking)"
    "$SCRIPT_DIR/compare_URL_Local.sh" \
        --id OpenAI-Introducing-GPT-4o \
        --models gemini-3-flash-preview,gemini-3-pro-preview \
        --skip-events --align 2>&1 | tee "$RESULTS_DIR/url_local.log"

    print_header "3. URL vs Local (no Thinking)"
    "$SCRIPT_DIR/compare_URL_Local.sh" \
        --id OpenAI-Introducing-GPT-4o \
        --models gemini-3-flash-preview,gemini-3-pro-preview \
        --skip-events --align --no-thinking 2>&1 | tee "$RESULTS_DIR/no_thinking.log"

    print_header "4. Main Benchmark (DER/JER/WER)"
    "$SCRIPT_DIR/benchmark.sh" 2>&1 | tee "$RESULTS_DIR/benchmark.log"
else
    print_header "Skipping benchmark runs (using existing logs)"
fi

# ============================================================================
# Extract results from logs to temp files
# ============================================================================

print_header "Extracting Results"

# Extract tables
grep -E "^Dataset:|^-{10,}|^\|" "$RESULTS_DIR/benchmark.log" > "$RESULTS_DIR/main_table.txt" 2>/dev/null || true
grep -A 100 "^| Model" "$RESULTS_DIR/url_local.log" | grep -E "^\|" | head -20 > "$RESULTS_DIR/url_local_table.txt" 2>/dev/null || true
grep -A 100 "^| Model" "$RESULTS_DIR/no_thinking.log" | grep -E "^\|" | head -20 > "$RESULTS_DIR/no_thinking_table.txt" 2>/dev/null || true
grep -A 100 "^| Model" "$RESULTS_DIR/temperature.log" | grep -E "^\|" | head -20 > "$RESULTS_DIR/temperature_table.txt" 2>/dev/null || true

echo "Extracted:"
echo "  Main: $(wc -l < "$RESULTS_DIR/main_table.txt") lines"
echo "  URL/Local: $(wc -l < "$RESULTS_DIR/url_local_table.txt") lines"
echo "  No-thinking: $(wc -l < "$RESULTS_DIR/no_thinking_table.txt") lines"
echo "  Temperature: $(wc -l < "$RESULTS_DIR/temperature_table.txt") lines"

# ============================================================================
# Update README.md
# ============================================================================

print_header "Updating README.md and README-zh.md"

python3 "$SCRIPT_DIR/update_readme_results.py" \
    --readme "$README" \
    --main "$RESULTS_DIR/main_table.txt" \
    --url-local "$RESULTS_DIR/url_local_table.txt" \
    --no-thinking "$RESULTS_DIR/no_thinking_table.txt" \
    --temperature "$RESULTS_DIR/temperature_table.txt"

print_header "All Complete"
print_info "Results saved to: $RESULTS_DIR/"
print_info "README.md and README-zh.md updated"
