#!/bin/bash
# Common functions and variables for benchmark scripts
# Usage: source "$(dirname "$0")/common.sh"

# ============================================================================
# Path Setup
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATASETS_JSON="$PROJECT_DIR/data/datasets.json"
DATA_ROOT="$PROJECT_DIR/data"

# Load .env file if exists
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# ============================================================================
# Colors
# ============================================================================
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# Print Functions
# ============================================================================
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# ============================================================================
# File Functions
# ============================================================================

# Check if source is newer than target (or target doesn't exist)
# Usage: if needs_update "$source" "$target"; then ... fi
needs_update() {
    local source="$1"
    local target="$2"

    # Target doesn't exist -> needs update
    [ ! -f "$target" ] && return 0

    # Source doesn't exist -> no update needed
    [ ! -f "$source" ] && return 1

    # Compare modification times: source newer than target?
    [ "$source" -nt "$target" ]
}

# Convert caption format if source is newer than target
# Usage: convert_if_needed "$source" "$target"
convert_if_needed() {
    local source="$1"
    local target="$2"

    if needs_update "$source" "$target"; then
        lai caption convert -Y "$source" "$target" 2>/dev/null || {
            print_warning "Failed to convert $(basename "$source")"
            return 1
        }
        return 0
    else
        return 1  # No conversion needed
    fi
}

# ============================================================================
# Dataset Functions
# ============================================================================
get_dataset_info() {
    local id="$1"
    local field="$2"
    python3 -c "
import json
with open('$DATASETS_JSON') as f:
    data = json.load(f)
for ds in data['datasets']:
    if ds['id'] == '$id':
        print(ds.get('$field', ''))
        break
"
}

dataset_exists() {
    local id="$1"
    python3 -c "
import json, sys
with open('$DATASETS_JSON') as f:
    data = json.load(f)
ids = [ds['id'] for ds in data['datasets']]
sys.exit(0 if '$id' in ids else 1)
"
}

get_language_code() {
    local dataset_id="$1"
    local lang_code="en"
    local dataset_lang
    dataset_lang=$(get_dataset_info "$dataset_id" "language")
    if [[ "$dataset_lang" == zh* ]]; then
        lang_code="zh"
    elif [[ "$dataset_lang" == ja* ]]; then
        lang_code="ja"
    fi
    echo "$lang_code"
}

# ============================================================================
# Evaluation Functions
# ============================================================================

# Run eval and return JSON result
# Usage: result=$(run_eval_json "$ref_file" "$hyp_file" ["skip_events"] ["metrics"])
# Language is auto-detected from dataset id in file path
# Default metrics: der jer wer sca scer
run_eval_json() {
    local ref_file="$1"
    local hyp_file="$2"
    local skip_events="${3:-true}"
    local metrics="${4:-der jer wer sca scer}"

    local extra_args=""
    if [ "$skip_events" = "true" ]; then
        extra_args="--skip-events"
    fi

    python "$PROJECT_DIR/eval.py" \
        -r "$ref_file" \
        -hyp "$hyp_file" \
        --metrics $metrics \
        --format json $extra_args 2>/dev/null | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)))"
}

# Print summary table from results file
# Usage: print_summary_table "$results_file" ["metrics"]
# Default metrics: "der jer wer sca scer"
# For DER/JER/WER only: print_summary_table "$file" "der jer wer"
print_summary_table() {
    local results_file="$1"
    local metrics="${2:-der jer wer sca scer}"

    python3 << EOF
import json

results = []
with open("$results_file") as f:
    for line in f:
        if line.strip():
            results.append(json.loads(line))

if not results:
    print("No results found.")
else:
    metrics = "$metrics".split()

    # Check if results have dataset field
    has_dataset = "dataset" in results[0]

    # Format metric value
    def fmt(val):
        return f"{val:.4f} ({val*100:5.2f}%)"

    def get_der(m):
        v = m.get("der", 0)
        return v.get("diarization error rate", 0) if isinstance(v, dict) else v

    def get_metric(m, name):
        if name == "der":
            return get_der(m)
        return m.get(name, 0)

    metric_width = 16  # "0.1234 (12.34%)"

    # Metric display names with arrows
    metric_names = {
        "der": "DER ↓",
        "jer": "JER ↓",
        "wer": "WER ↓",
        "sca": "SCA ↑",
        "scer": "SCER ↓",
    }

    def print_table(results_list):
        max_model_len = max(len(r["model"]) for r in results_list)
        max_model_len = max(max_model_len, 5)

        # Build header
        header_parts = [f"{'Model':<{max_model_len}}"]
        sep_parts = ['-' * (max_model_len + 2)]
        for m in metrics:
            header_parts.append(f"{metric_names.get(m, m):^{metric_width}}")
            sep_parts.append('-' * (metric_width + 2))

        print("| " + " | ".join(header_parts) + " |")
        print("|" + "|".join(sep_parts) + "|")

        for r in results_list:
            m = r["metrics"]
            row_parts = [f"{r['model']:<{max_model_len}}"]
            for metric in metrics:
                row_parts.append(f"{fmt(get_metric(m, metric)):^{metric_width}}")
            print("| " + " | ".join(row_parts) + " |")

    if has_dataset:
        # Group by dataset
        datasets = {}
        for r in results:
            ds = r.get("dataset", "unknown")
            if ds not in datasets:
                datasets[ds] = []
            datasets[ds].append(r)

        for ds, ds_results in datasets.items():
            print(f"Dataset: {ds}")
            print("-" * 100)
            print_table(ds_results)
            print("\n")
    else:
        # Single dataset mode
        print_table(results)

        # Print diff if exactly 2 results
        if len(results) == 2:
            print()
            m1, m2 = results[0]["metrics"], results[1]["metrics"]
            der_diff = get_der(m2) - get_der(m1)
            jer_diff = m2.get("jer", 0) - m1.get("jer", 0)
            wer_diff = m2.get("wer", 0) - m1.get("wer", 0)

            def fmt_diff(val):
                sign = "+" if val >= 0 else ""
                return f"{sign}{val*100:.2f}%"

            name1 = results[0]["model"].split()[-1].strip("()")
            name2 = results[1]["model"].split()[-1].strip("()")
            print(f"Δ ({name2} - {name1}): DER {fmt_diff(der_diff)}, JER {fmt_diff(jer_diff)}, WER {fmt_diff(wer_diff)}")
EOF
}
