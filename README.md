# LattifAI Benchmark

Evaluating LattifAI's audio-text alignment capabilities.

**[View Interactive Results →](https://lattifai.github.io/benchmark/)**


## Benchmark
```
# gemini-3-flash-preview temperature = 1.0 0.5 0.1
bash scripts/temperature.sh

# YouTube URL or local audio file
bash scripts/compare_URL_Local.sh --id OpenAI-Introducing-GPT-4o --models gemini-3-flash-preview,gemini-3-pro-preview --skip-events --align

# 验证 Thinking 机制是否有效
bash scripts/compare_URL_Local.sh --id OpenAI-Introducing-GPT-4o --models gemini-3-flash-preview,gemini-3-pro-preview --skip-events --align --no-thinking

# DER JER and etc
bash scripts/benchmark.sh
```

#### Results

LattifAI improves timing accuracy by **37-62%** across Gemini models:

| Model | DER↓ | JER↓ | WER↓ | Improvement |
|-------|------|------|------|-------------|
| Gemini 2.5 Pro | 36.10% | 39.17% | 15.11% | — |
| **+ LattifAI** | **22.52%** | **31.60%** | 15.11% | **↓ 37%** |
| Gemini 3 Pro Preview | 53.43% | 56.79% | 4.94% | — |
| **+ LattifAI** | **22.65%** | **36.56%** | 4.94% | **↓ 58%** |
| Gemini 3 Flash Preview | 30.44% | 30.42% | 4.54% | — |
| **+ LattifAI** | **11.42%** | **13.63%** | 4.54% | **↓ 62%** |

> DER/JER = timing accuracy (lower = better). WER = transcription quality.

## Quick Start

```bash
pip install pysubs2 pyannote.core pyannote.metrics jiwer whisper-normalizer

# Setup API keys (auto-loaded by run.sh)
cp .env.example .env
# Edit .env with your keys

# List datasets
./scripts/run.sh list

# Run evaluation
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o

# Full pipeline (transcribe → align → eval)
./scripts/run.sh all --id OpenAI-Introducing-GPT-4o
```

## Usage

```bash
./scripts/run.sh [command] [options]

Commands:
  list        List available datasets
  eval        Run evaluation (default)
  transcribe  Transcribe with Gemini (requires GEMINI_API_KEY)
  align       Align with LattifAI (requires LATTIFAI_API_KEY)
  all         Run full pipeline

Options:
  --id <id>       Run for specific dataset
  --local         Use local audio.mp3 instead of YouTube URL
  -o <dir>        Output directory (default: data/)
  --prompt <file> Custom prompt for transcription
  --thoughts      Include Gemini thinking process in output
  --skip-events   Skip [event] markers in eval (e.g., [Laughter])
  --models <list> Comma-separated models (default: all in datasets.json)
```

### Evaluate Raw Gemini Output (Skip Alignment)

```bash
# Transcribe only, then evaluate raw Gemini timestamps
./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o

# eval auto-converts .md → .ass if needed
```

## Data Structure

```
data/
├── datasets.json              # Dataset index
├── OpenAI-Introducing-GPT-4o/
│   ├── audio.mp3
│   ├── ground_truth.ass       # Reference
│   ├── gemini-2.5-pro.md      # Transcripts
└── TheValley101-GPT-4o-vs-Gemini/
    └── ...
```

## Metrics

| Metric | Description |
|--------|-------------|
| **DER** | Diarization Error Rate |
| **JER** | Jaccard Error Rate |
| **WER** | Word Error Rate |
| **SCA** | Speaker Count Accuracy |

## References

- [pyannote.metrics](https://pyannote.github.io/pyannote-metrics/)
- [jiwer](https://github.com/jitsi/jiwer)

---
Credits: [@dotey](https://x.com/dotey) for the [prompts/Gemini_dotey.md](https://x.com/dotey/status/1971810075867046131)
