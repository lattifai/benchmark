# MOSS-Transcribe-Diarize — DER / WER Benchmark

> 中文版本:[MOSS-Transcribe-Diarize-results-zh.md](MOSS-Transcribe-Diarize-results-zh.md)

End-to-end transcription + diarization evaluation of
[`OpenMOSS-Team/MOSS-Transcribe-Diarize`](https://huggingface.co/OpenMOSS-Team/MOSS-Transcribe-Diarize)
(0.9B) on two datasets from this repo.

## Setup

| Item | Value |
|------|-------|
| Model | [`OpenMOSS-Team/MOSS-Transcribe-Diarize`](https://huggingface.co/OpenMOSS-Team/MOSS-Transcribe-Diarize) (HF rev [`e6d68cd`](https://huggingface.co/OpenMOSS-Team/MOSS-Transcribe-Diarize/commit/e6d68cd), 2026‑07‑15) |
| Serving | vLLM `0.23.1rc1.dev949+g68b4a1d58.cu129` (pinned nightly per model card), OpenAI `/v1/audio/transcriptions` |
| Host | `ubuntu_local`, single RTX 4090 (24 GB) |
| Decoding | greedy (`temperature=0`), `max_completion_tokens=40000` |
| Prompt | server default (timestamped transcription + `[Sxx]` diarization) |
| Eval | `eval.py`, `collar=0.25`, `skip_overlap=false`, language auto-detected |
| Date | 2026‑07‑18 |

MOSS speaker labels `S01/S02/…` are relabeled to `Speaker 1/2/…` before scoring
(the `[Sxx]` form is otherwise collapsed to a single speaker by eval.py's speaker-name
normalizer). Diarization DER then maps hypothesis speakers to reference names via
pyannote's optimal mapping.

## Results (collar = 0.25 s)

| Dataset | Lang | Audio | DER ↓ | WER ↓ | JER ↓ | SCA ↑ | SCER ↓ |
|---------|------|-------|-------|-------|-------|-------|--------|
| OpenAI-Introducing-GPT-4o | en | 26:13 | **14.88 %** | **4.02 %** | 38.87 % | 100 % | 0 % |
| TheValley101-GPT-4o-vs-Gemini | zh & en | 27:08 | **4.98 %** | **4.32 %** | 65.84 % | 0 % | 44.4 % |

### DER component breakdown (seconds, collar = 0.25 s)

| Dataset | False alarm | Missed | Confusion | Correct | Total |
|---------|-------------|--------|-----------|---------|-------|
| OpenAI-Introducing-GPT-4o | 10.27 | 21.99 | 131.00 | 944.48 | 1097.47 |
| TheValley101-GPT-4o-vs-Gemini | 1.41 | 37.13 | 36.94 | 1442.27 | 1516.34 |

### Sensitivity to collar

| Dataset | DER @0.20 | DER @0.25 | WER |
|---------|-----------|-----------|-----|
| OpenAI-Introducing-GPT-4o | 15.43 % | 14.88 % | 4.02 % |
| TheValley101-GPT-4o-vs-Gemini | 5.09 % | 4.98 % | 4.32 % |

## Notes

- **Transcription (WER ≈ 4 %) is excellent** on both the English keynote and the
  Chinese/English mixed commentary.
- **OpenAI keynote**: MOSS finds exactly 4 speakers (SCA = 100 %). Residual DER is
  mostly *confusion* (131 s) — the reference distinguishes 4 named speakers and MOSS
  occasionally swaps two of them within the demo sections.
- **TheValley101**: DER is very low (5 %) because one narrator (`host`) dominates the
  audio and MOSS tracks it well, but MOSS under-segments the many short interview
  speakers — it emits 5 anonymous speakers vs. ~10 reference speakers (SCER = 44 %),
  which inflates JER even though time-weighted DER stays small.
- A first run truncated at ~5120 output tokens (the model card's
  `generation_config.json` default). Raising `max_completion_tokens` to 40000 lets the
  decoder finish the full diarized transcript; both audios are covered end-to-end
  (1543 s / 1624 s).

## Error analysis

Error type breakdown per dataset (collar = 0.25 s), from `eval.py --verbose`:

| Dataset | False alarm | Missed | Confusion | Dominant error |
|---------|-------------|--------|-----------|----------------|
| OpenAI-Introducing-GPT-4o | 10.3 s / 110 seg | 22.0 s / 75 seg | **131.0 s / 68 seg** | speaker confusion |
| TheValley101-GPT-4o-vs-Gemini | 1.4 s / 14 seg | 37.1 s / 466 seg | 36.9 s / 28 seg | boundary + embedded clips |

### OpenAI keynote — one systematic confusion dominates (80 % of error)

Optimal speaker mapping: `Speaker 1→Mira Murati`, `Speaker 3→Barrett Zoph`,
`Speaker 4→ChatGPT`. **Mark Chen has no dedicated hypothesis speaker.**

Confusion (131 s) is almost entirely a single failure: during the live GPT-4o demo
(≈ 558 s–1399 s) **MOSS merges Mark Chen and Barrett Zoph into one speaker
(`Speaker 3`)**. Mark hosts the demo while Barrett plays the "friend"; the two trade
lines rapidly and MOSS cannot separate them acoustically, so nearly all of Mark Chen's
speech is scored as confusion against `Speaker 3`. Representative segments:

```
[562.05-566.98] CONF  ref=Mark Chen  hyp=Barrett Zoph  "So one of the key capabilities we're really excited…"
[659.52-663.45] CONF  ref=Mark Chen  hyp=Barrett Zoph  "Right, so if you've used our voice mode experience…"
[719.55-722.53] CONF  ref=Mark Chen  hyp=Barrett Zoph  "So my friend Barrett here, he's been having trouble…"
```

The other ~32 s (FA + MISS) are sub-second timestamp-boundary fragments (47 of 75 MISS
segments are < 0.3 s; all 110 FA segments are < 0.3 s), i.e. collar-edge alignment
noise, not real detection errors. Opening/closing by Mira Murati and the ChatGPT demo
voice are tracked correctly (SCA = 100 %).

### TheValley101 — no single hotspot; low DER, but under-segmented

Optimal mapping: `Speaker 1→host`, `Speaker 2→ChatGPT`, `Speaker 3→Yusen Dai`,
`Speaker 5→Howie Xu`. Error splits evenly between MISS (37 s) and CONF (37 s):

- **MISS (37 s) is entirely fragmentation**: 449 of 466 segments are < 0.3 s and none
  exceed 1 s — pure timestamp-boundary misalignment against the reference, not missed
  speech.
- **CONF (37 s) comes from the embedded English source clips.** This video is a Chinese
  voice-over that splices in original GPT-4o / Project-Astra launch footage. Inside
  those clips MOSS collapses the several English speakers (Mark Chen, ChatGPT, Barrett
  Zoph, Mira Murati, Astra User) mostly into `host` or `ChatGPT`:

```
[237.97-239.94] CONF  ref=ChatGPT      hyp=host     "Mark you're not a vacuum cleaner"
[570.62-572.91] CONF  ref=Astra User1  hyp=host     "What can I add here to make this system faster"
[347.99-349.74] CONF  ref=User_1       hyp=ChatGPT  "Do the singing voice again please"
```

DER stays at ~5 % because the Chinese narrator (`host`) dominates the runtime and is
tracked accurately, but MOSS emits only 5 speakers vs. ~10 in the reference
(SCA = 0, SCER = 44 %) — it under-segments the many brief interview/clip voices.

### What the technical report says about interleaved / overlapping speech

The MOSS report (arXiv:2601.01554) **does explicitly target rapid turn-taking and
overlap**, so the co-host confusion above is a case they claim to optimize for:

- **Simulated training data** is built by a "controllable probabilistic simulator …
  enforcing speaker alternation while permitting overlaps capped at 80 percent of the
  shorter segment" (§3.2) — a deliberate data-augmentation for alternating/overlapping
  speakers, not just incidental in-the-wild overlap.
- A dedicated **Movies** benchmark is "characterized by short utterances, rapid speaker
  alternation, and frequent overlaps," on which they report best-in-class cpCER and Δcp
  and "robust handling of speaker boundaries across diverse conversational regimes."
- Their headline diarization metric is **Δcp** (extra CER from speaker attribution),
  reported lowest under "frequent turn-taking and long-range speaker re-entrance."

Caveat when comparing: their claim rests on **cpCER/Δcp** (text/attribution-based) over
movie dialogue, whereas the co-host merge above is measured by **time-based DER** on an
English live-demo. Different metric and domain — but it does show the exact failure mode
(fast-alternating co-speakers folded into one label) still surfaces in practice.

### Takeaways

- Transcription is not the bottleneck anywhere (WER ≈ 4 % on both).
- The real weakness is **separating speakers who alternate rapidly in a shared acoustic
  scene** — co-hosts in a live demo (OpenAI) and multiple voices inside spliced-in
  clips (TheValley101). MOSS tends to assign such interleaved speech to one dominant
  label.
- Timestamp granularity is fine but boundaries are a few tens of ms off, generating many
  tiny collar-edge FA/MISS fragments; these inflate segment counts but contribute little
  total time.

## Reproduce

```bash
# On ubuntu_local: serve (encoder cache sized for ~26 min audio, single-seq to fit 24 GB)
VLLM_MAX_AUDIO_DECODE_DURATION_S=7200 PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
vllm serve OpenMOSS-Team/MOSS-Transcribe-Diarize --trust-remote-code \
  --port 8010 --gpu-memory-utilization 0.55 --max-model-len 65536 \
  --max-num-batched-tokens 32768 --max-num-seqs 1

# Transcribe + parse to ASS
python scripts/moss_transcribe.py audio.mp3 --api-base http://localhost:8010/v1 \
  --model MOSS-Transcribe-Diarize -o data/<dataset>/moss-transcribe-diarize

# Evaluate
python eval.py -r data/<dataset>/ground_truth.ass \
  -hyp data/<dataset>/moss-transcribe-diarize.ass -m der jer wer sca scer -c 0.25
```
