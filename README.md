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

- **Video**: [Introducing GPT-4o](https://www.youtube.com/watch?v=DQacCB9tDaw) (OpenAI)
- **Ground Truth**: Manually annotated speaker-labeled subtitles
- **Location**: `data/introducing-gpt4o/`

## Files

```
lattifai-benchmark/
├── eval.py                  # Evaluation script
├── scripts/
│   └── reproduce.sh         # Reproduction script
├── data/
│   └── introducing-gpt4o/
│       ├── ground_truth.ass           # Reference annotations
│       ├── gemini_*.md                # Raw Gemini transcripts
│       ├── gemini_*.ass               # Converted to ASS
│       └── gemini_*_lattifai.ass      # After LattifAI alignment
└── index.html               # Interactive visualization
```

## Usage

```bash
# Single file evaluation
python eval.py -r reference.ass -hyp hypothesis.ass -n "Model Name"

# Specific metrics
python eval.py -r ref.ass -hyp hyp.ass -m der wer

# JSON output
python eval.py -r ref.ass -hyp hyp.ass -f json
```

## References

- [pyannote.metrics](https://pyannote.github.io/pyannote-metrics/)
- [jiwer](https://github.com/jitsi/jiwer)
- [OpenBench](https://github.com/argmaxinc/OpenBench)
