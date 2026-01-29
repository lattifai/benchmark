# LattifAI Benchmark

Evaluating LattifAI's audio-text processing capabilities across multiple dimensions.

**[View Interactive Results →](https://lattifai.github.io/benchmark/)**

## Forced Alignment

LattifAI improves timing accuracy by **37-62%** across Gemini models:

| Model | DER↓  | JER↓  | WER↓  | Improvement |
|-------|-----|-----|-----|-------------|
| Gemini 2.5 Pro | 36.10% | 39.17% | 15.11% | — |
| **+ LattifAI** | **22.52%** | **31.60%** | 15.11% | **↓ 37%** |
| Gemini 3 Pro Preview | 53.43% | 56.79% | 4.94% | — |
| **+ LattifAI** | **22.65%** | **36.56%** | 4.94% | **↓ 58%** |
| Gemini 3 Flash Preview | 30.44% | 30.42% | 4.54% | — |
| **+ LattifAI** | **11.42%** | **13.63%** | 4.54% | **↓ 62%** |

> DER/JER measure timing accuracy (lower = better). WER measures transcription quality (unchanged by alignment).

## Quick Start

```bash
# Install dependencies
pip install pysubs2 pyannote.core pyannote.metrics jiwer whisper-normalizer

# Run evaluation
./scripts/reproduce.sh eval

# Full reproduction (requires GEMINI_API_KEY)
GEMINI_API_KEY=xxx ./scripts/reproduce.sh all
```

## Metrics

| Metric | Description | Good Score |
|--------|-------------|------------|
| **DER** | Diarization Error Rate: false alarm + missed + confusion | < 20% |
| **JER** | Jaccard Error Rate: temporal overlap accuracy | Lower better |
| **WER** | Word Error Rate: transcription accuracy | < 10% |
| **SCA** | Speaker Count Accuracy | 100% |
| **SCER** | Speaker Count Error Rate | 0% |

## Test Data

Multi-language, multi-dataset structure supporting extensible benchmarking.

### Current Datasets

| ID | Language | Category | Name | Speakers |
|----|----------|----------|------|----------|
| `introducing-gpt4o` | English | Alignment | [Introducing GPT-4o](https://www.youtube.com/watch?v=DQacCB9tDaw) | 2 |

**See [DATA_STRUCTURE.md](DATA_STRUCTURE.md) for detailed documentation.**

## Files

```
lattifai-benchmark/
├── eval.py                      # Legacy evaluation script
├── scripts/
│   ├── reproduce.sh             # Legacy reproduction script
│   ├── migrate_data.py          # Data migration tool
│   ├── dataset_manager.py       # Dataset management CLI
│   └── eval_dataset.py          # Evaluate single dataset
├── data/
│   ├── datasets.json            # Global dataset index
│   ├── alignment/               # Forced alignment tests
│   │   ├── en/                  # English datasets
│   │   │   └── introducing-gpt4o/
│   │   │       ├── metadata.json           # Dataset metadata
│   │   │       ├── ground_truth.ass        # Reference
│   │   │       └── results/                # Model outputs
│   │   │           ├── gemini_*.md         # Raw transcripts
│   │   │           ├── gemini_*.ass        # Converted
│   │   │           └── gemini_*_lattifai.ass  # Aligned
│   │   └── zh/                  # Chinese datasets
│   ├── transcription/           # Pure transcription (future)
│   └── diarization/             # Speaker diarization (future)
└── index.html                   # Interactive visualization
```

## Usage

### Dataset Management

```bash
# List all datasets
python scripts/dataset_manager.py list

# Filter by language
python scripts/dataset_manager.py list -l en

# Show dataset details
python scripts/dataset_manager.py show introducing-gpt4o

# Add new dataset
python scripts/dataset_manager.py add \
  my-dataset-id "My Dataset" en alignment \
  "https://youtube.com/..." \
  --speakers 2 --tags multi-speaker
```

### Evaluation

```bash
# Evaluate a dataset (all models)
python scripts/eval_dataset.py introducing-gpt4o

# Custom metrics
python scripts/eval_dataset.py introducing-gpt4o -m der jer wer

# Legacy single file evaluation
python eval.py -r reference.ass -hyp hypothesis.ass -n "Model Name"
```

### Adding New Datasets

1. Create dataset entry:
   ```bash
   python scripts/dataset_manager.py add \
     dataset-id "Dataset Name" {language} alignment \
     "video-url" --speakers 2
   ```

2. Add ground truth:
   ```bash
   # Copy to data/alignment/{language}/{dataset-id}/ground_truth.ass
   ```

3. Add model results:
   ```bash
   # Create data/alignment/{language}/{dataset-id}/results/
   # Add model outputs (*.md, *.ass, *_lattifai.ass)
   ```

4. Update metadata.json with result entries

See [DATA_STRUCTURE.md](DATA_STRUCTURE.md) for details.

## References

- [pyannote.metrics](https://pyannote.github.io/pyannote-metrics/)
- [jiwer](https://github.com/jitsi/jiwer)
- [OpenBench](https://github.com/argmaxinc/OpenBench)
