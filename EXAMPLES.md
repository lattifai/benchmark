# Dataset Examples

## Adding a Chinese Dataset

```bash
# 1. Create dataset entry
python scripts/dataset_manager.py add \
  chinese-tech-interview \
  "中文科技访谈" \
  zh \
  alignment \
  "https://www.youtube.com/watch?v=XXXXXX" \
  --description "中文技术访谈，涉及AI话题" \
  --duration 600 \
  --speakers 2 \
  --tags chinese interview technical

# 2. Directory structure created:
# data/alignment/zh/chinese-tech-interview/
# ├── metadata.json
# └── (add files below)

# 3. Add ground truth
# Manually annotate and save as:
# data/alignment/zh/chinese-tech-interview/ground_truth.ass

# 4. Add model results
mkdir -p data/alignment/zh/chinese-tech-interview/results

# Transcribe with Gemini
lai transcription run \
  video.mp4 \
  data/alignment/zh/chinese-tech-interview/results/gemini_2.5_pro.md \
  --model gemini-2.5-pro \
  --language zh

# Convert to ASS
lai caption convert \
  data/alignment/zh/chinese-tech-interview/results/gemini_2.5_pro.md \
  data/alignment/zh/chinese-tech-interview/results/gemini_2.5_pro.ass \
  include_speaker_in_text=false

# Align with LattifAI
lai alignment align \
  video.mp4 \
  data/alignment/zh/chinese-tech-interview/results/gemini_2.5_pro.ass \
  data/alignment/zh/chinese-tech-interview/results/gemini_2.5_pro_lattifai.ass

# 5. Update metadata.json to add result entry
# Edit data/alignment/zh/chinese-tech-interview/metadata.json:
{
  "results": [
    {
      "model": "gemini-2.5-pro",
      "files": {
        "raw_transcript": "results/gemini_2.5_pro.md",
        "converted": "results/gemini_2.5_pro.ass",
        "aligned": "results/gemini_2.5_pro_lattifai.ass"
      }
    }
  ]
}

# 6. Evaluate
python scripts/eval_dataset.py chinese-tech-interview
```

## Adding a Japanese Dataset

```bash
# 1. Create dataset entry
python scripts/dataset_manager.py add \
  japanese-news-clip \
  "日本語ニュースクリップ" \
  ja \
  alignment \
  "https://www.youtube.com/watch?v=YYYYYY" \
  --description "日本語のニュース報道" \
  --duration 300 \
  --speakers 1 \
  --tags japanese news

# 2. Follow same steps as Chinese example above
# 3. Update metadata.json with Japanese-specific normalizer settings if needed
```

## Adding Multiple Models

```bash
# For each model, create three files:
# 1. Raw transcript (.md)
# 2. Converted (.ass)
# 3. Aligned (*_lattifai.ass)

DATASET_DIR="data/alignment/en/introducing-gpt4o"
MODELS=("gemini-2.5-pro" "gemini-3-pro-preview" "gemini-3-flash-preview")

for model in "${MODELS[@]}"; do
  # Transcribe
  lai transcription run \
    video.mp4 \
    "$DATASET_DIR/results/${model//-/_}.md" \
    --model "$model"

  # Convert
  lai caption convert \
    "$DATASET_DIR/results/${model//-/_}.md" \
    "$DATASET_DIR/results/${model//-/_}.ass" \
    include_speaker_in_text=false

  # Align
  lai alignment align \
    video.mp4 \
    "$DATASET_DIR/results/${model//-/_}.ass" \
    "$DATASET_DIR/results/${model//-/_}_lattifai.ass"
done
```

## Batch Evaluation

```bash
# Evaluate all English datasets
for dataset in $(python scripts/dataset_manager.py list -l en | tail -n +3 | head -n -2 | awk '{print $1}'); do
  echo "Evaluating: $dataset"
  python scripts/eval_dataset.py "$dataset"
done

# Evaluate all datasets in a category
for dataset in $(python scripts/dataset_manager.py list -c alignment | tail -n +3 | head -n -2 | awk '{print $1}'); do
  python scripts/eval_dataset.py "$dataset"
done
```

## Dataset Metadata Best Practices

### Complete Metadata Example

```json
{
  "id": "podcast-ep-1",
  "name": "Tech Podcast Episode 1",
  "description": "Discussion about AI ethics and regulation",
  "language": "en",
  "video": {
    "url": "https://youtube.com/...",
    "duration": 1800,
    "format": "youtube"
  },
  "speakers": {
    "count": 3,
    "labels": ["Host", "Guest 1", "Guest 2"]
  },
  "ground_truth": {
    "path": "ground_truth.ass",
    "format": "ass",
    "annotator": "manual",
    "annotation_date": "2026-01-28",
    "annotation_guidelines": "Labeled speaker changes, excluded background music"
  },
  "results": [
    {
      "model": "gemini-2.5-pro",
      "version": "2025-01",
      "parameters": {
        "temperature": 0.0,
        "language": "en"
      },
      "files": {
        "raw_transcript": "results/gemini_2.5_pro.md",
        "converted": "results/gemini_2.5_pro.ass",
        "aligned": "results/gemini_2.5_pro_lattifai.ass"
      },
      "metrics": {
        "der": 0.25,
        "jer": 0.30,
        "wer": 0.10
      }
    }
  ],
  "tags": ["multi-speaker", "podcast", "long-form", "english"],
  "difficulty": "hard",
  "notes": "Contains overlapping speech and background music",
  "created": "2026-01-28",
  "updated": "2026-01-29"
}
```

### Recommended Tags

- **Language**: `english`, `chinese`, `japanese`, `multilingual`
- **Content Type**: `interview`, `podcast`, `news`, `lecture`, `presentation`, `conversation`
- **Complexity**: `multi-speaker`, `overlapping-speech`, `background-noise`, `music`
- **Domain**: `technical`, `business`, `general`, `academic`
- **Format**: `long-form`, `short-clip`, `scripted`, `spontaneous`

### Difficulty Levels

- **easy**: Single speaker, clear audio, scripted
- **medium**: 2-3 speakers, good audio, natural speech
- **hard**: 3+ speakers, some noise, overlapping speech, music
- **expert**: Challenging audio conditions, many speakers, complex content
