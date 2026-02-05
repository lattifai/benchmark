# LattifAI 基准测试

评估 LattifAI 的音频-文本对齐能力。

**[查看交互式结果 →](https://lattifai.github.io/benchmark/index-zh.html)** | **[English →](README.md)**


## 测试数据

我们使用 [OpenAI GPT-4o 发布会](https://www.youtube.com/watch?v=DQacCB9tDaw)（约 26 分钟）作为主要测试素材。这是一个具有挑战性的案例：

- **4 位说话人**，包括 ChatGPT 的语音
- **频繁的打断**和语音重叠
- 全程伴有**观众掌声**和环境噪音

> **关于样本量的说明**：目前我们只有一个主要数据集。虽然数量有限，但我们对每个实验至少运行两次以验证结果的稳定性。未来会补充更多数据集。


## 基准测试

```bash
# 运行所有基准测试并更新 README 结果
./scripts/update_readme.sh

# 或单独运行：
./scripts/temperature.sh                    # 温度参数对比 (1.0, 0.5, 0.1)
./scripts/compare_URL_Local.sh --id ... --align  # URL vs 本地音频
./scripts/benchmark.sh                      # 主要 DER/JER/WER 基准测试
```

#### 结果

##### 主要基准测试

```
Dataset: OpenAI-Introducing-GPT-4o
----------------------------------------------------------------------------------------------------
| Model                                             |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|---------------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| YouTube Caption (official)                        | 1.7284 (172.84%) | 0.6334 (63.34%)  | 0.2116 (21.16%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| YouTube Caption (official) +LattifAI              | 0.1574 (15.74%)  | 0.2370 (23.70%)  | 0.2101 (21.01%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey)                      | 0.5433 (54.33%)  | 0.5730 (57.30%)  | 0.0495 ( 4.95%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey) +LattifAI            | 0.2218 (22.18%)  | 0.3659 (36.59%)  | 0.0495 ( 4.95%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey run2)                 | 3.6103 (361.03%) | 0.8275 (82.75%)  | 0.0532 ( 5.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey)                    | 0.3002 (30.02%)  | 0.3010 (30.10%)  | 0.0454 ( 4.54%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey) +LattifAI          | 0.1125 (11.25%)  | 0.1512 (15.12%)  | 0.0454 ( 4.54%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey run2)               | 0.2995 (29.95%)  | 0.2860 (28.60%)  | 0.0444 ( 4.44%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey run2) +LattifAI     | 0.1104 (11.04%)  | 0.1454 (14.54%)  | 0.0444 ( 4.44%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd)                 | 0.4038 (40.38%)  | 0.2621 (26.21%)  | 0.0427 ( 4.27%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd) +LattifAI       | 0.1004 (10.04%)  | 0.1308 (13.08%)  | 0.0427 ( 4.27%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd run2)            | 0.2472 (24.72%)  | 0.2437 (24.37%)  | 0.0638 ( 6.38%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd run2) +LattifAI  | 0.1005 (10.05%)  | 0.1293 (12.93%)  | 0.0638 ( 6.38%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise)                  | 0.2127 (21.27%)  | 0.2119 (21.19%)  | 0.0419 ( 4.19%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise) +LattifAI        | 0.0929 ( 9.29%)  | 0.1177 (11.77%)  | 0.0419 ( 4.19%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise run2)             | 0.2295 (22.95%)  | 0.2286 (22.86%)  | 0.0665 ( 6.65%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise run2) +LattifAI   | 0.1115 (11.15%)  | 0.1413 (14.13%)  | 0.0665 ( 6.65%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey)                | 0.7793 (77.93%)  | 0.6913 (69.13%)  | 0.0464 ( 4.64%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey) +LattifAI      | 0.1781 (17.81%)  | 0.1546 (15.46%)  | 0.0464 ( 4.64%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey run2)           | 0.6491 (64.91%)  | 0.6446 (64.46%)  | 0.0449 ( 4.49%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey run2) +LattifAI | 0.1006 (10.06%)  | 0.1348 (13.48%)  | 0.0449 ( 4.49%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2)                   | 0.7696 (76.96%)  | 0.7583 (75.83%)  | 0.0452 ( 4.52%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2) +LattifAI         | 0.1050 (10.50%)  | 0.1462 (14.62%)  | 0.0452 ( 4.52%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2 run2)              | 0.7739 (77.39%)  | 0.7112 (71.12%)  | 0.0585 ( 5.85%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2 run2) +LattifAI    | 0.3308 (33.08%)  | 0.4879 (48.79%)  | 0.0585 ( 5.85%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

> **关于 WER 差异的说明**：YouTube Caption +LattifAI 可能显示与原始略有不同的 WER。这是因为 LattifAI 的 `split_sentence` 会重组 YouTube 的碎片化字幕（例如 `"we have 100"` + `"million people"` → `"we have 100 million people"`），这会影响 WER 计算时数字的规范化方式（`100` + `million` → `1000000` vs `100 million` → `100000000`）。

##### URL vs 本地音频

```
| Model                                    |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (URL)             | 0.3186 (31.86%)  | 0.3345 (33.45%)  | 0.0482 ( 4.82%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (URL +LattifAI)   | 0.1342 (13.42%)  | 0.2127 (21.27%)  | 0.0482 ( 4.82%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Local)           | 0.3312 (33.12%)  | 0.3458 (34.58%)  | 0.0467 ( 4.67%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Local +LattifAI) | 0.1193 (11.93%)  | 0.1827 (18.27%)  | 0.0467 ( 4.67%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (URL)               | 3.1103 (311.03%) | 0.8303 (83.03%)  | 0.0437 ( 4.37%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (URL +LattifAI)     | 0.1226 (12.26%)  | 0.1774 (17.74%)  | 0.0437 ( 4.37%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (Local)             | 0.4064 (40.64%)  | 0.4954 (49.54%)  | 0.0432 ( 4.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (Local +LattifAI)   | 0.1967 (19.67%)  | 0.3534 (35.34%)  | 0.0432 ( 4.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

##### 思考模式影响

```
| Model                                               |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|-----------------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (no-think) (URL)             | 0.3187 (31.87%)  | 0.3249 (32.49%)  | 0.0653 ( 6.53%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (URL +LattifAI)   | 0.1114 (11.14%)  | 0.1548 (15.48%)  | 0.0653 ( 6.53%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (Local)           | 0.3212 (32.12%)  | 0.3523 (35.23%)  | 0.0505 ( 5.05%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (Local +LattifAI) | 0.1235 (12.35%)  | 0.1943 (19.43%)  | 0.0505 ( 5.05%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (URL)               | 0.3043 (30.43%)  | 0.3296 (32.96%)  | 0.0547 ( 5.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (URL +LattifAI)     | 0.1454 (14.54%)  | 0.2077 (20.77%)  | 0.0547 ( 5.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (Local)             | 3.0630 (306.30%) | 0.8285 (82.85%)  | 0.0412 ( 4.12%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (Local +LattifAI)   | 0.1034 (10.34%)  | 0.1531 (15.31%)  | 0.0412 ( 4.12%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

##### 温度参数对比

```
| Model                                   |      DER ↓       |      JER ↓       |      WER ↓       |
|-----------------------------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (temp=1.0, run1) | 0.1988 (19.88%)  | 0.1696 (16.96%)  | 0.0177 ( 1.77%)  |
| gemini-3-flash-preview (temp=1.0, run2) | 0.2171 (21.71%)  | 0.1824 (18.24%)  | 0.0191 ( 1.91%)  |
| gemini-3-flash-preview (temp=0.5, run1) | 0.1899 (18.99%)  | 0.1628 (16.28%)  | 0.0147 ( 1.47%)  |
| gemini-3-flash-preview (temp=0.5, run2) | 0.3003 (30.03%)  | 0.2396 (23.96%)  | 0.0133 ( 1.33%)  |
| gemini-3-flash-preview (temp=0.1, run1) | 0.2097 (20.97%)  | 0.1794 (17.94%)  | 0.0147 ( 1.47%)  |
| gemini-3-flash-preview (temp=0.1, run2) | 0.1957 (19.57%)  | 0.1665 (16.65%)  | 0.0147 ( 1.47%)  |
```

> **指标说明**：DER/JER = 时间戳准确度（越低越好），WER = 转录质量，SCA = 说话人数量准确率（仅用于说话人分离测试）


## 快速开始

```bash
pip install pysubs2 pyannote.core pyannote.metrics jiwer whisper-normalizer

# 设置 API 密钥（由 run.sh 自动加载）
cp .env.example .env
# 编辑 .env 填入你的密钥

# 列出数据集
./scripts/run.sh list

# 运行评估
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o

# 完整流程（转录 → 对齐 → 评估）
./scripts/run.sh all --id OpenAI-Introducing-GPT-4o
```

## 使用方法

```bash
./scripts/run.sh [命令] [选项]

命令:
  list        列出可用数据集
  eval        运行评估（默认）
  transcribe  使用 Gemini 转录（需要 GEMINI_API_KEY）
  align       使用 LattifAI 对齐（需要 LATTIFAI_API_KEY）
  all         运行完整流程

选项:
  --id <id>       针对特定数据集运行
  --local         使用本地 audio.mp3 而非 YouTube URL
  -o <dir>        输出目录（默认：data/）
  --prompt <file> 自定义转录提示词
  --thoughts      在输出中包含 Gemini 思考过程
  --skip-events   评估时跳过 [event] 标记（如 [Laughter]）
  --models <list> 逗号分隔的模型列表（默认：datasets.json 中的所有模型）
```

### 评估原始 Gemini 输出（跳过对齐）

```bash
# 仅转录，然后评估原始 Gemini 时间戳
./scripts/run.sh transcribe --id OpenAI-Introducing-GPT-4o
./scripts/run.sh eval --id OpenAI-Introducing-GPT-4o

# eval 会在需要时自动转换 .md → .ass
```

## 数据结构

```
data/
├── datasets.json              # 数据集索引
├── OpenAI-Introducing-GPT-4o/
│   ├── audio.mp3
│   ├── ground_truth.ass       # 参考标注
│   ├── gemini-2.5-pro.md      # 转录结果
└── TheValley101-GPT-4o-vs-Gemini/
    └── ...
```

## 指标说明

| 指标 | 说明 |
|------|------|
| **DER** | 说话人分离错误率 (Diarization Error Rate) |
| **JER** | Jaccard 错误率 (Jaccard Error Rate) |
| **WER** | 词错误率 (Word Error Rate) |
| **SCA** | 说话人数量准确率 (Speaker Count Accuracy) |

## 参考资料

- [pyannote.metrics](https://pyannote.github.io/pyannote-metrics/)
- [jiwer](https://github.com/jitsi/jiwer)

---
致谢：[@dotey](https://x.com/dotey) 提供的 [prompts/Gemini_dotey.md](https://x.com/dotey/status/1971810075867046131)
