# LattifAI Benchmark

Evaluating LattifAI's audio-text alignment capabilities.

**[View Interactive Results →](https://lattifai.github.io/benchmark/)**


## Benchmark

```bash
# Run all benchmarks and update README results
./scripts/update_readme.sh

# Or run individually:
./scripts/temperature.sh                    # Temperature comparison (1.0, 0.5, 0.1)
./scripts/compare_URL_Local.sh --id ... --align  # URL vs Local audio
./scripts/benchmark.sh                      # Main DER/JER/WER benchmark
```

#### Results

##### Main Benchmark

```
Dataset: OpenAI-Introducing-GPT-4o
----------------------------------------------------------------------------------------------------
| Model                                             |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|---------------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| YouTube Caption (official)                        | 1.7485 (174.85%) | 0.6355 (63.55%)  | 0.2109 (21.09%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| YouTube Caption (official) +LattifAI              | 0.1602 (16.02%)  | 0.2430 (24.30%)  | 0.2096 (20.96%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey)                    | 0.3002 (30.02%)  | 0.3010 (30.10%)  | 0.0454 ( 4.54%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey) +LattifAI          | 0.1125 (11.25%)  | 0.1510 (15.10%)  | 0.0454 ( 4.54%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey run2)               | 0.2995 (29.95%)  | 0.2860 (28.60%)  | 0.0444 ( 4.44%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey run2) +LattifAI     | 0.0989 ( 9.89%)  | 0.1298 (12.98%)  | 0.0444 ( 4.44%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd run2)            | 0.2472 (24.72%)  | 0.2437 (24.37%)  | 0.0638 ( 6.38%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd run2) +LattifAI  | 0.1005 (10.05%)  | 0.1293 (12.93%)  | 0.0638 ( 6.38%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise)                  | 0.2270 (22.70%)  | 0.2213 (22.13%)  | 0.0419 ( 4.19%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise) +LattifAI        | 0.0935 ( 9.35%)  | 0.1183 (11.83%)  | 0.0419 ( 4.19%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise run2)             | 0.2295 (22.95%)  | 0.2286 (22.86%)  | 0.0665 ( 6.65%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise run2) +LattifAI   | 0.1116 (11.16%)  | 0.1414 (14.14%)  | 0.0665 ( 6.65%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey)                | 0.7793 (77.93%)  | 0.6913 (69.13%)  | 0.0464 ( 4.64%)  | 0.0000 ( 0.00%)  | 0.2500 (25.00%)  |
| gemini-3-flash-preview (SRT dotey) +LattifAI      | 0.1786 (17.86%)  | 0.1551 (15.51%)  | 0.0464 ( 4.64%)  | 0.0000 ( 0.00%)  | 0.2500 (25.00%)  |
| gemini-3-flash-preview (SRT dotey run2)           | 0.6491 (64.91%)  | 0.6446 (64.46%)  | 0.0449 ( 4.49%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey run2) +LattifAI | 0.1011 (10.11%)  | 0.1353 (13.53%)  | 0.0449 ( 4.49%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2)                   | 0.7696 (76.96%)  | 0.7583 (75.83%)  | 0.0452 ( 4.52%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2) +LattifAI         | 0.1052 (10.52%)  | 0.1461 (14.61%)  | 0.0452 ( 4.52%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2 run2)              | 0.7739 (77.39%)  | 0.7112 (71.12%)  | 0.0585 ( 5.85%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2 run2) +LattifAI    | 0.3319 (33.19%)  | 0.4884 (48.84%)  | 0.0585 ( 5.85%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

##### URL vs Local Audio

```
| Model                                    |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (URL)             | 0.3243 (32.43%)  | 0.3371 (33.71%)  | 0.0482 ( 4.82%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (URL +LattifAI)   | 0.1340 (13.40%)  | 0.2110 (21.10%)  | 0.0482 ( 4.82%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Local)           | 0.3312 (33.12%)  | 0.3458 (34.58%)  | 0.0467 ( 4.67%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Local +LattifAI) | 0.1217 (12.17%)  | 0.1855 (18.55%)  | 0.0467 ( 4.67%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (URL)               | 3.1122 (311.22%) | 0.8303 (83.03%)  | 0.0437 ( 4.37%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (URL +LattifAI)     | 0.1326 (13.26%)  | 0.1861 (18.61%)  | 0.0437 ( 4.37%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (Local)             | 0.4145 (41.45%)  | 0.4987 (49.87%)  | 0.0432 ( 4.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (Local +LattifAI)   | 0.1855 (18.55%)  | 0.3378 (33.78%)  | 0.0432 ( 4.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

##### Thinking Mode Impact

```
| Model                                               |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|-----------------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (no-think) (URL)             | 0.3228 (32.28%)  | 0.3270 (32.70%)  | 0.0653 ( 6.53%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (URL +LattifAI)   | 0.1093 (10.93%)  | 0.1520 (15.20%)  | 0.0653 ( 6.53%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (Local)           | 0.3221 (32.21%)  | 0.3533 (35.33%)  | 0.0505 ( 5.05%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (Local +LattifAI) | 0.1213 (12.13%)  | 0.1915 (19.15%)  | 0.0505 ( 5.05%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (URL)               | 0.3043 (30.43%)  | 0.3296 (32.96%)  | 0.0547 ( 5.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (URL +LattifAI)     | 0.1441 (14.41%)  | 0.2073 (20.73%)  | 0.0547 ( 5.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (Local)             | 3.0661 (306.61%) | 0.8285 (82.85%)  | 0.0412 ( 4.12%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (Local +LattifAI)   | 0.1032 (10.32%)  | 0.1527 (15.27%)  | 0.0412 ( 4.12%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

##### Temperature Comparison

```
| Model                                   |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|-----------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (temp=1.0, run1) | 0.1988 (19.88%)  | 0.1696 (16.96%)  | 0.0177 ( 1.77%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (temp=1.0, run2) | 0.2171 (21.71%)  | 0.1824 (18.24%)  | 0.0191 ( 1.91%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (temp=0.5, run1) | 0.1899 (18.99%)  | 0.1628 (16.28%)  | 0.0147 ( 1.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (temp=0.5, run2) | 0.3003 (30.03%)  | 0.2396 (23.96%)  | 0.0133 ( 1.33%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (temp=0.1, run1) | 0.2097 (20.97%)  | 0.1794 (17.94%)  | 0.0147 ( 1.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (temp=0.1, run2) | 0.1957 (19.57%)  | 0.1665 (16.65%)  | 0.0147 ( 1.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

> **Metrics**: DER/JER = timing accuracy (lower = better), WER = transcription quality, SCA = speaker count accuracy


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
