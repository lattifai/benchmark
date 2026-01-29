# Test Data Structure

## Overview

The benchmark uses a hierarchical, multi-language data structure:

```
data/
├── datasets.json                           # Global dataset index
├── alignment/                              # Forced alignment tests
│   ├── en/                                 # English datasets
│   │   └── introducing-gpt4o/
│   │       ├── metadata.json               # Dataset metadata
│   │       ├── ground_truth.ass            # Human-annotated reference
│   │       └── results/                    # Model outputs
│   │           ├── gemini_2.5_pro.md       # Raw transcript
│   │           ├── gemini_2.5_pro.ass      # Converted to ASS
│   │           └── gemini_2.5_pro_lattifai.ass  # After alignment
│   ├── zh/                                 # Chinese datasets
│   │   └── example-case/
│   │       ├── metadata.json
│   │       ├── ground_truth.ass
│   │       └── results/
│   └── ja/                                 # Japanese datasets
├── transcription/                          # Pure transcription tests (future)
└── diarization/                            # Speaker diarization tests (future)
```

## Files

### `datasets.json`

Global index of all datasets:

```json
{
  "version": "1.0.0",
  "datasets": [
    {
      "id": "introducing-gpt4o",
      "language": "en",
      "category": "alignment",
      "name": "Introducing GPT-4o",
      "description": "...",
      "video_url": "https://youtube.com/...",
      "duration": 180,
      "num_speakers": 2,
      "path": "alignment/en/introducing-gpt4o",
      "ground_truth": "ground_truth.ass",
      "models": ["gemini-2.5-pro", ...],
      "tags": ["multi-speaker", "english"]
    }
  ],
  "languages": {
    "en": "English",
    "zh": "Chinese (Simplified)",
    ...
  },
  "categories": {
    "alignment": "Forced Alignment",
    ...
  }
}
```

### `metadata.json`

Detailed metadata for each dataset:

```json
{
  "id": "introducing-gpt4o",
  "name": "Introducing GPT-4o",
  "description": "...",
  "language": "en",
  "video": {
    "url": "https://youtube.com/...",
    "duration": 180,
    "format": "youtube"
  },
  "speakers": {
    "count": 2,
    "labels": ["Speaker 1", "Speaker 2"]
  },
  "ground_truth": {
    "path": "ground_truth.ass",
    "format": "ass",
    "annotator": "manual",
    "annotation_date": "2024-05"
  },
  "results": [
    {
      "model": "gemini-2.5-pro",
      "files": {
        "raw_transcript": "results/gemini_2.5_pro.md",
        "converted": "results/gemini_2.5_pro.ass",
        "aligned": "results/gemini_2.5_pro_lattifai.ass"
      }
    }
  ],
  "tags": ["multi-speaker", "product-announcement"],
  "difficulty": "medium",
  "created": "2024-05-13",
  "updated": "2026-01-28"
}
```

## Dataset Management

### List Datasets

```bash
# List all datasets
python scripts/dataset_manager.py list

# Filter by language
python scripts/dataset_manager.py list -l en

# Filter by category
python scripts/dataset_manager.py list -c alignment
```

### Show Dataset Details

```bash
python scripts/dataset_manager.py show introducing-gpt4o
```

### Add New Dataset

```bash
python scripts/dataset_manager.py add \
  my-dataset-id \
  "My Dataset Name" \
  en \
  alignment \
  "https://youtube.com/watch?v=..." \
  --description "Dataset description" \
  --duration 120 \
  --speakers 2 \
  --tags multi-speaker technical
```

This will:
1. Create `data/alignment/en/my-dataset-id/`
2. Generate `metadata.json`
3. Update `datasets.json`

### Add Ground Truth and Results

After creating a dataset, manually add:

1. **Ground truth**: `ground_truth.ass` in the dataset directory
2. **Model results**: Create `results/` subdirectory and add model outputs
3. **Update metadata.json**: Add result entries:

```json
{
  "results": [
    {
      "model": "model-name",
      "files": {
        "raw_transcript": "results/model_name.md",
        "converted": "results/model_name.ass",
        "aligned": "results/model_name_lattifai.ass"
      }
    }
  ]
}
```

## Evaluation

### Evaluate Single Dataset

```bash
# Evaluate with default metrics (DER, JER, WER, SCA, SCER)
python scripts/eval_dataset.py introducing-gpt4o

# Custom metrics
python scripts/eval_dataset.py introducing-gpt4o -m der jer wer

# With collar
python scripts/eval_dataset.py introducing-gpt4o --collar 0.25
```

### Evaluate All Datasets

```bash
# Evaluate all datasets in a language
for dataset in $(python scripts/dataset_manager.py list -l en | grep -v "^ID" | grep -v "^=" | grep -v "^Total" | awk '{print $1}'); do
  python scripts/eval_dataset.py "$dataset"
done
```

## Migration

To migrate existing data to the new structure:

```bash
python scripts/migrate_data.py
```

This will:
1. Move `data/introducing-gpt4o/` to `data/alignment/en/introducing-gpt4o/`
2. Organize files into `ground_truth.ass` and `results/` subdirectory
3. Create `metadata.json`
4. Update `datasets.json`

## Adding New Languages

1. Create language directory: `data/alignment/{language_code}/`
2. Add dataset: `python scripts/dataset_manager.py add ...`
3. Add ground truth and results
4. Update language normalizer in `eval.py` if needed

## Adding New Categories

1. Create category directory: `data/{category}/`
2. Update `datasets.json` categories section
3. Create datasets under the category

## Best Practices

1. **Consistent naming**: Use lowercase with hyphens for IDs (e.g., `my-dataset-id`)
2. **File formats**: Store ground truth as ASS for speaker info + timing
3. **Results organization**: Keep raw transcripts (`.md`), converted (`.ass`), and aligned versions
4. **Metadata completeness**: Fill in all metadata fields for better discoverability
5. **Tags**: Use consistent tags across datasets (e.g., `multi-speaker`, `technical`, `interview`)
