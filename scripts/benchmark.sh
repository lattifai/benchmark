./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o --models gemini-2.5-pro -o data --prompt prompts/Gemini_dotey.md
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o --models gemini-2.5-pro -o data

./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o --models gemini-3-pro-preview -o data --prompt prompts/Gemini_dotey.md
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o --models gemini-3-pro-preview -o data

# gemini-3-flash-preview 1
./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o data --prompt prompts/Gemini_dotey.md
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o data

# gemini-3-flash-preview 2
./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/V1_1 --prompt prompts/Gemini_dotey.md
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/V1_1

# gemini-3-flash-preview StartEnd 1
./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/StartEnd_V1 --prompt prompts/Gemini_dotey_StartEnd.md
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/StartEnd_V1
lai caption convert -Y outputs/StartEnd_V1/OpenAI-Introducing-GPT-4o/gemini-3-flash-preview.md outputs/StartEnd_V1/OpenAI-Introducing-GPT-4o/gemini-3-flash-preview.TextGrid
# gemini-3-flash-preview StartEnd 2
./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/StartEnd_V1_2 --prompt prompts/Gemini_dotey_StartEnd.md
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/StartEnd_V1_2

# gemini-3-flash-preview PreciseEnd 1
./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/PreciseEnd_V1 --prompt prompts/Gemini_dotey_Precise.md
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/PreciseEnd_V1
lai caption convert -Y outputs/PreciseEnd_V1/OpenAI-Introducing-GPT-4o/gemini-3-flash-preview.md outputs/PreciseEnd_V1/OpenAI-Introducing-GPT-4o/gemini-3-flash-preview.TextGrid
# gemini-3-flash-preview PreciseEnd 2
./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/PreciseEnd_V1_2 --prompt prompts/Gemini_dotey_Precise.md
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o  --models gemini-3-flash-preview -o outputs/PreciseEnd_V1_2


# OpenAI-Introducing-GPT-4o
# 1) 重复转写的稳定性
# 2) + Start 是否有用
| Model | DER ↓ | JER ↓ | WER ↓ | SCA ↑ | SCER ↓ |
|--------|--------|--------|--------|--------|--------|
| gemini-3-flash-preview 1           | 0.3335 (33.35%) | 0.3187 (31.87%) | 0.0454 ( 4.54%) | 0.0000 ( 0.00%) | 0.2500 (25.00%) |
| gemini-3-flash-preview 2           | 0.3315 (33.15%) | 0.2958 (29.58%) | 0.0444 ( 4.44%) | 0.0000 ( 0.00%) | 0.2500 (25.00%) |
| gemini-3-flash-preview StartEnd 1  | 0.3434 (34.34%) | 0.2965 (29.65%) | 0.0597 ( 5.97%) | 0.0000 ( 0.00%) | 0.2500 (25.00%) |
| gemini-3-flash-preview StartEnd 2  | 0.2827 (28.27%) | 0.2653 (26.53%) | 0.0638 ( 6.38%) | 1.0000 (100.00%) | 0.0000 ( 0.00%) |
| gemini-3-flash-preview PreciseEnd 1 | 0.2782 (27.82%) | 0.2572 (25.72%) | 0.0419 ( 4.19%) | 1.0000 (100.00%) | 0.0000 ( 0.00%) |
| gemini-3-flash-preview PreciseEnd 2 | 0.2937 (29.37%) | 0.2586 (25.86%) | 0.0665 ( 6.65%) | 0.0000 ( 0.00%) | 0.2500 (25.00%) |



./scripts/run.sh transcribe --id TheValley101-GPT-4o-vs-Gemini --models gemini-2.5-pro -o data --prompt prompts/Gemini_dotey.md
./scripts/run.sh eval --language zh --id TheValley101-GPT-4o-vs-Gemini --models gemini-2.5-pro -o data

./scripts/run.sh transcribe --id TheValley101-GPT-4o-vs-Gemini --models gemini-3-pro-preview -o data --prompt prompts/Gemini_dotey.md
./scripts/run.sh eval --language zh --id TheValley101-GPT-4o-vs-Gemini --models gemini-3-pro-preview -o data

./scripts/run.sh transcribe --id TheValley101-GPT-4o-vs-Gemini --models gemini-3-flash-preview -o data --prompt prompts/Gemini_dotey.md
./scripts/run.sh eval --language zh --id TheValley101-GPT-4o-vs-Gemini --models gemini-3-flash-preview -o data
lai caption convert -Y data/TheValley101-GPT-4o-vs-Gemini/gemini-3-flash-preview.md data/TheValley101-GPT-4o-vs-Gemini/gemini-3-flash-preview.TextGrid


| Model | DER ↓ | JER ↓ | WER ↓ | SCA ↑ | SCER ↓ |
|--------|--------|--------|--------|--------|--------|
| Ground Truth           | 0.0000 ( 0.00%) | 0.0000 ( 0.00%) | 0.0000 ( 0.00%) | 1.0000 (100.00%) | 0.0000 ( 0.00%) |
| gemini-3-pro-preview   | 0.1000 (10.00%) | 0.4216 (42.16%) | 0.1625 (16.25%) | 0.0000 ( 0.00%) | 0.2727 (27.27%) |
| gemini-3-flash-preview | 0.4034 (40.34%) | 0.6886 (68.86%) | 0.1725 (17.25%) | 0.0000 ( 0.00%) | 0.0909 ( 9.09%) |
