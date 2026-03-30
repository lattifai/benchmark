# LattifAI Benchmark

Evaluating LattifAI's audio-text alignment capabilities.

**[View Interactive Results →](https://lattifai.github.io/benchmark/)** | **[中文版 →](README-zh.md)**


## Test Data

We use two datasets covering English and Chinese:

#### 1. [OpenAI GPT-4o Launch Event](https://www.youtube.com/watch?v=DQacCB9tDaw) (English, ~26 min)

- **4 speakers** including ChatGPT's voice
- **Frequent interruptions** and overlapping speech
- **Audience applause** and ambient noise throughout

#### 2. [TheValley101: GPT-4o vs Gemini](https://www.youtube.com/watch?v=JaQmSHzjlpY) (Chinese & English, ~27 min)

- **14 speakers** including AI voice assistants (ChatGPT, Project Astra)
- **Code-switching** between Chinese and English throughout
- **Embedded video clips** from multiple sources with varying audio quality


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
| YouTube Caption (official)                        | 1.6578 (165.78%) | 0.6236 (62.36%)  | 0.2116 (21.16%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| YouTube Caption (official) +LattifAI              | 0.1125 (11.25%)  | 0.2048 (20.48%)  | 0.2101 (21.01%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey)                      | 0.4981 (49.81%)  | 0.5611 (56.11%)  | 0.0495 ( 4.95%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey) +LattifAI            | 0.1771 (17.71%)  | 0.3480 (34.80%)  | 0.0495 ( 4.95%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey run2)                 | 3.7759 (377.59%) | 0.8262 (82.62%)  | 0.0532 ( 5.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey run2) +LattifAI       | 0.0666 ( 6.66%)  | 0.1241 (12.41%)  | 0.0532 ( 5.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey)                    | 0.2476 (24.76%)  | 0.2571 (25.71%)  | 0.0454 ( 4.54%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey) +LattifAI          | 0.0618 ( 6.18%)  | 0.0954 ( 9.54%)  | 0.0454 ( 4.54%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey run2)               | 0.2501 (25.01%)  | 0.2451 (24.51%)  | 0.0444 ( 4.44%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey run2) +LattifAI     | 0.0595 ( 5.95%)  | 0.0849 ( 8.49%)  | 0.0444 ( 4.44%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd)                 | 0.2057 (20.57%)  | 0.2091 (20.91%)  | 0.0598 ( 5.98%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd) +LattifAI       | 0.0552 ( 5.52%)  | 0.0799 ( 7.99%)  | 0.0427 ( 4.27%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd run2)            | 0.1984 (19.84%)  | 0.1964 (19.64%)  | 0.0638 ( 6.38%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd run2) +LattifAI  | 0.0507 ( 5.07%)  | 0.0723 ( 7.23%)  | 0.0638 ( 6.38%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise)                  | 0.1597 (15.97%)  | 0.1569 (15.69%)  | 0.0419 ( 4.19%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise) +LattifAI        | 0.0413 ( 4.13%)  | 0.0523 ( 5.23%)  | 0.0419 ( 4.19%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise run2)             | 0.1775 (17.75%)  | 0.1742 (17.42%)  | 0.0665 ( 6.65%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise run2) +LattifAI   | 0.0596 ( 5.96%)  | 0.0789 ( 7.89%)  | 0.0665 ( 6.65%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey)                | 0.7444 (74.44%)  | 0.6870 (68.70%)  | 0.0464 ( 4.64%)  | 0.0000 ( 0.00%)  | 0.2500 (25.00%)  |
| gemini-3-flash-preview (SRT dotey) +LattifAI      | 0.1287 (12.87%)  | 0.0940 ( 9.40%)  | 0.0464 ( 4.64%)  | 0.0000 ( 0.00%)  | 0.2500 (25.00%)  |
| gemini-3-flash-preview (SRT dotey run2)           | 0.6070 (60.70%)  | 0.6340 (63.40%)  | 0.0449 ( 4.49%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey run2) +LattifAI | 0.0495 ( 4.95%)  | 0.0742 ( 7.42%)  | 0.0449 ( 4.49%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2)                   | 0.7270 (72.70%)  | 0.7498 (74.98%)  | 0.0452 ( 4.52%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2) +LattifAI         | 0.0535 ( 5.35%)  | 0.0864 ( 8.64%)  | 0.0452 ( 4.52%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2 run2)              | 0.7383 (73.83%)  | 0.7081 (70.81%)  | 0.0585 ( 5.85%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2 run2) +LattifAI    | 0.2867 (28.67%)  | 0.4758 (47.58%)  | 0.0585 ( 5.85%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| vibevoice                                         | 0.1494 (14.94%)  | 0.1515 (15.15%)  | 0.0374 ( 3.74%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
Dataset: TheValley101-GPT-4o-vs-Gemini
----------------------------------------------------------------------------------------------------
| Model                                         |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|-----------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-2.5-pro (dotey)                        | 0.2937 (29.37%)  | 0.9202 (92.02%)  | 0.1419 (14.19%)  | 0.0000 ( 0.00%)  | 0.8889 (88.89%)  |
| gemini-2.5-pro (dotey) +LattifAI              | 0.2827 (28.27%)  | 0.9195 (91.95%)  | 0.1419 (14.19%)  | 0.0000 ( 0.00%)  | 0.8889 (88.89%)  |
| gemini-2.5-pro (dotey run2)                   | 0.1933 (19.33%)  | 0.7652 (76.52%)  | 0.1845 (18.45%)  | 0.0000 ( 0.00%)  | 0.6667 (66.67%)  |
| gemini-2.5-pro (dotey run2) +LattifAI         | 0.1881 (18.81%)  | 0.7621 (76.21%)  | 0.1845 (18.45%)  | 0.0000 ( 0.00%)  | 0.6667 (66.67%)  |
| gemini-3-pro-preview (dotey)                  | 0.0695 ( 6.95%)  | 0.3410 (34.10%)  | 0.1112 (11.12%)  | 0.0000 ( 0.00%)  | 0.5556 (55.56%)  |
| gemini-3-pro-preview (dotey) +LattifAI        | 0.0474 ( 4.74%)  | 0.2198 (21.98%)  | 0.1112 (11.12%)  | 0.0000 ( 0.00%)  | 0.5556 (55.56%)  |
| gemini-3-pro-preview (dotey run2)             | 0.0485 ( 4.85%)  | 0.5187 (51.87%)  | 0.0440 ( 4.40%)  | 0.0000 ( 0.00%)  | 0.1111 (11.11%)  |
| gemini-3-pro-preview (dotey run2) +LattifAI   | 0.0300 ( 3.00%)  | 0.4814 (48.14%)  | 0.0440 ( 4.40%)  | 0.0000 ( 0.00%)  | 0.1111 (11.11%)  |
| gemini-3-flash-preview (dotey)                | 0.3812 (38.12%)  | 0.5816 (58.16%)  | 0.0994 ( 9.94%)  | 0.0000 ( 0.00%)  | 0.1111 (11.11%)  |
| gemini-3-flash-preview (dotey) +LattifAI      | 0.3660 (36.60%)  | 0.6353 (63.53%)  | 0.0994 ( 9.94%)  | 0.0000 ( 0.00%)  | 0.1111 (11.11%)  |
| gemini-3-flash-preview (dotey run2)           | 0.0793 ( 7.93%)  | 0.4742 (47.42%)  | 0.1032 (10.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey run2) +LattifAI | 0.0649 ( 6.49%)  | 0.5012 (50.12%)  | 0.1032 (10.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| vibevoice                                     | 0.0427 ( 4.27%)  | 0.6096 (60.96%)  | 0.0470 ( 4.70%)  | 0.0000 ( 0.00%)  | 0.4444 (44.44%)  |
```

> **Note on WER differences**: YouTube Caption +LattifAI may show slightly different WER than the original. This is because LattifAI's `split_sentence` reorganizes fragmented YouTube captions (e.g., `"we have 100"` + `"million people"` → `"we have 100 million people"`), which affects how numbers are normalized during WER calculation (`100` + `million` → `1000000` vs `100 million` → `100000000`).

> **Note on VibeVoice**: VibeVoice is a local ASR model with no public API. Results were generated by running the model locally. The JSON output (with speaker diarization) is converted to ASS using `scripts/vibevoice_json2ass.py`.

##### URL vs Local Audio

```
| Model                                    |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (URL)             | 0.2674 (26.74%)  | 0.2977 (29.77%)  | 0.0482 ( 4.82%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (URL +LattifAI)   | 0.0832 ( 8.32%)  | 0.1656 (16.56%)  | 0.0482 ( 4.82%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Local)           | 0.2866 (28.66%)  | 0.3244 (32.44%)  | 0.0467 ( 4.67%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Local +LattifAI) | 0.0752 ( 7.52%)  | 0.1524 (15.24%)  | 0.0467 ( 4.67%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (URL)               | 3.2400 (324.00%) | 0.8291 (82.91%)  | 0.0437 ( 4.37%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (URL +LattifAI)     | 0.0743 ( 7.43%)  | 0.1250 (12.50%)  | 0.0437 ( 4.37%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (Local)             | 0.3516 (35.16%)  | 0.4670 (46.70%)  | 0.0432 ( 4.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (Local +LattifAI)   | 0.1454 (14.54%)  | 0.3204 (32.04%)  | 0.0432 ( 4.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

##### Thinking Mode Impact

```
| Model                                               |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|-----------------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (no-think) (URL)             | 0.2668 (26.68%)  | 0.2835 (28.35%)  | 0.0653 ( 6.53%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (URL +LattifAI)   | 0.0596 ( 5.96%)  | 0.1002 (10.02%)  | 0.0653 ( 6.53%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (Local)           | 0.2765 (27.65%)  | 0.3321 (33.21%)  | 0.0505 ( 5.05%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (Local +LattifAI) | 0.0780 ( 7.80%)  | 0.1655 (16.55%)  | 0.0505 ( 5.05%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (URL)               | 0.2506 (25.06%)  | 0.2861 (28.61%)  | 0.0547 ( 5.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (URL +LattifAI)     | 0.0931 ( 9.31%)  | 0.1539 (15.39%)  | 0.0547 ( 5.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (Local)             | 3.1893 (318.93%) | 0.8272 (82.72%)  | 0.0412 ( 4.12%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (Local +LattifAI)   | 0.0609 ( 6.09%)  | 0.1230 (12.30%)  | 0.0412 ( 4.12%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

##### Temperature Comparison

```
| Model                                   |      DER ↓       |      JER ↓       |      WER ↓       |
|-----------------------------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (temp=1.0, run1) | 0.1679 (16.79%)  | 0.1470 (14.70%)  | 0.0177 ( 1.77%)  |
| gemini-3-flash-preview (temp=1.0, run2) | 0.1869 (18.69%)  | 0.1609 (16.09%)  | 0.0191 ( 1.91%)  |
| gemini-3-flash-preview (temp=0.5, run1) | 0.1590 (15.90%)  | 0.1399 (13.99%)  | 0.0147 ( 1.47%)  |
| gemini-3-flash-preview (temp=0.5, run2) | 0.2734 (27.34%)  | 0.2226 (22.26%)  | 0.0133 ( 1.33%)  |
| gemini-3-flash-preview (temp=0.1, run1) | 0.1790 (17.90%)  | 0.1571 (15.71%)  | 0.0147 ( 1.47%)  |
| gemini-3-flash-preview (temp=0.1, run2) | 0.1647 (16.47%)  | 0.1439 (14.39%)  | 0.0147 ( 1.47%)  |
```

> **Metrics**: DER/JER = timing accuracy (lower = better), WER = transcription quality, SCA = speaker count accuracy (only for diarization tests)


## Quick Start

```bash
pip install pysubs2 pyannote.core pyannote.metrics jiwer whisper-normalizer kaldialign

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

> **Collar**: DER/JER are calculated with a **200ms collar** (tolerance window around segment boundaries). This is standard practice to account for minor annotation differences.

## References

- [pyannote.metrics](https://pyannote.github.io/pyannote-metrics/)
- [jiwer](https://github.com/jitsi/jiwer)

---
Credits: [@dotey](https://x.com/dotey) for the [prompts/Gemini_dotey.md](https://x.com/dotey/status/1971810075867046131)
