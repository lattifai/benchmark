#!/bin/bash
# Run all benchmarks and update README.md with results
# Usage: ./scripts/update_readme.sh [--skip-run] [--lang <en|zh>] [--diarization]

set -e

source "$(dirname "$0")/common.sh"

README="$PROJECT_DIR/README.md"
RESULTS_DIR="$PROJECT_DIR/.benchmark_results"
mkdir -p "$RESULTS_DIR"

SKIP_RUN="false"
LANG_FILTER=""
DIARIZATION="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-run)
            SKIP_RUN="true"
            shift
            ;;
        --lang)
            LANG_FILTER="$2"
            shift 2
            ;;
        --diarization)
            DIARIZATION="true"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-run] [--lang <en|zh>] [--diarization]"
            exit 1
            ;;
    esac
done

# ============================================================================
# Run benchmarks (unless --skip-run)
# ============================================================================

if [ "$SKIP_RUN" = "false" ]; then
    # Steps 1-3 are English-only tests; skip when --lang zh
    if [ -z "$LANG_FILTER" ] || [ "$LANG_FILTER" = "en" ]; then
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
    else
        print_header "Skipping steps 1-3 (English-only tests, --lang $LANG_FILTER)"
    fi

    print_header "4. Main Benchmark (DER/JER/WER)"
    BENCH_ARGS=()
    [ -n "$LANG_FILTER" ] && BENCH_ARGS+=(--lang "$LANG_FILTER")
    [ "$DIARIZATION" = "true" ] && BENCH_ARGS+=(--diarization)
    "$SCRIPT_DIR/benchmark.sh" "${BENCH_ARGS[@]}" 2>&1 | tee "$RESULTS_DIR/benchmark.log"
else
    print_header "Skipping benchmark runs (using existing logs)"
fi

# ============================================================================
# Extract results from logs to temp files
# ============================================================================

print_header "Extracting Results"

# Extract tables
grep -E "^Dataset:|^-{10,}|^\|" "$RESULTS_DIR/benchmark.log" > "$RESULTS_DIR/main_table.txt" 2>/dev/null || true

if [ -z "$LANG_FILTER" ] || [ "$LANG_FILTER" = "en" ]; then
    grep -A 100 "^| Model" "$RESULTS_DIR/url_local.log" | grep -E "^\|" | head -20 > "$RESULTS_DIR/url_local_table.txt" 2>/dev/null || true
    grep -A 100 "^| Model" "$RESULTS_DIR/no_thinking.log" | grep -E "^\|" | head -20 > "$RESULTS_DIR/no_thinking_table.txt" 2>/dev/null || true
    grep -A 100 "^| Model" "$RESULTS_DIR/temperature.log" | grep -E "^\|" | head -20 > "$RESULTS_DIR/temperature_table.txt" 2>/dev/null || true
fi

echo "Extracted:"
echo "  Main: $(wc -l < "$RESULTS_DIR/main_table.txt") lines"
[ -f "$RESULTS_DIR/url_local_table.txt" ] && echo "  URL/Local: $(wc -l < "$RESULTS_DIR/url_local_table.txt") lines"
[ -f "$RESULTS_DIR/no_thinking_table.txt" ] && echo "  No-thinking: $(wc -l < "$RESULTS_DIR/no_thinking_table.txt") lines"
[ -f "$RESULTS_DIR/temperature_table.txt" ] && echo "  Temperature: $(wc -l < "$RESULTS_DIR/temperature_table.txt") lines"

# ============================================================================
# Update README.md
# ============================================================================

print_header "Updating README.md and README-zh.md"

LANG_ARG=""
if [ -n "$LANG_FILTER" ]; then
    LANG_ARG="--lang $LANG_FILTER"
fi

python3 "$SCRIPT_DIR/update_readme_results.py" \
    --readme "$README" \
    --main "$RESULTS_DIR/main_table.txt" \
    --url-local "$RESULTS_DIR/url_local_table.txt" \
    --no-thinking "$RESULTS_DIR/no_thinking_table.txt" \
    --temperature "$RESULTS_DIR/temperature_table.txt" \
    $LANG_ARG

print_header "All Complete"
print_info "Results saved to: $RESULTS_DIR/"
print_info "README.md and README-zh.md updated"
