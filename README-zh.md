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
| YouTube Caption (official)                        | 1.6563 (165.63%) | 0.6222 (62.22%)  | 0.2116 (21.16%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| YouTube Caption (official) +LattifAI              | 0.1099 (10.99%)  | 0.1975 (19.75%)  | 0.2101 (21.01%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey)                      | 0.4980 (49.80%)  | 0.5605 (56.05%)  | 0.0495 ( 4.95%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey) +LattifAI            | 0.1734 (17.34%)  | 0.3399 (33.99%)  | 0.0495 ( 4.95%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (dotey run2)                 | 3.7755 (377.55%) | 0.8262 (82.62%)  | 0.0532 ( 5.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey)                    | 0.2534 (25.34%)  | 0.2698 (26.98%)  | 0.0454 ( 4.54%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey) +LattifAI          | 0.0667 ( 6.67%)  | 0.1113 (11.13%)  | 0.0454 ( 4.54%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey run2)               | 0.2538 (25.38%)  | 0.2546 (25.46%)  | 0.0444 ( 4.44%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (dotey run2) +LattifAI     | 0.0642 ( 6.42%)  | 0.1019 (10.19%)  | 0.0444 ( 4.44%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd)                 | 0.3488 (34.88%)  | 0.2208 (22.08%)  | 0.0427 ( 4.27%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd) +LattifAI       | 0.0540 ( 5.40%)  | 0.0868 ( 8.68%)  | 0.0427 ( 4.27%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd run2)            | 0.2012 (20.12%)  | 0.2052 (20.52%)  | 0.0638 ( 6.38%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (StartEnd run2) +LattifAI  | 0.0542 ( 5.42%)  | 0.0845 ( 8.45%)  | 0.0638 ( 6.38%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise)                  | 0.1645 (16.45%)  | 0.1718 (17.18%)  | 0.0419 ( 4.19%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise) +LattifAI        | 0.0457 ( 4.57%)  | 0.0696 ( 6.96%)  | 0.0419 ( 4.19%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise run2)             | 0.1825 (18.25%)  | 0.1892 (18.92%)  | 0.0665 ( 6.65%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Precise run2) +LattifAI   | 0.0643 ( 6.43%)  | 0.0958 ( 9.58%)  | 0.0665 ( 6.65%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey)                | 0.7415 (74.15%)  | 0.6836 (68.36%)  | 0.0464 ( 4.64%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey) +LattifAI      | 0.1325 (13.25%)  | 0.1087 (10.87%)  | 0.0464 ( 4.64%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey run2)           | 0.6070 (60.70%)  | 0.6344 (63.44%)  | 0.0449 ( 4.49%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT dotey run2) +LattifAI | 0.0539 ( 5.39%)  | 0.0904 ( 9.04%)  | 0.0449 ( 4.49%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2)                   | 0.7313 (73.13%)  | 0.7542 (75.42%)  | 0.0452 ( 4.52%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2) +LattifAI         | 0.0582 ( 5.82%)  | 0.1029 (10.29%)  | 0.0452 ( 4.52%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2 run2)              | 0.7340 (73.40%)  | 0.7031 (70.31%)  | 0.0585 ( 5.85%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (SRT V2 run2) +LattifAI    | 0.2821 (28.21%)  | 0.4691 (46.91%)  | 0.0585 ( 5.85%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

> **关于 WER 差异的说明**：YouTube Caption +LattifAI 可能显示与原始略有不同的 WER。这是因为 LattifAI 的 `split_sentence` 会重组 YouTube 的碎片化字幕（例如 `"we have 100"` + `"million people"` → `"we have 100 million people"`），这会影响 WER 计算时数字的规范化方式（`100` + `million` → `1000000` vs `100 million` → `100000000`）。

##### URL vs 本地音频

```
| Model                                    |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (URL)             | 0.2711 (27.11%)  | 0.3060 (30.60%)  | 0.0482 ( 4.82%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (URL +LattifAI)   | 0.0880 ( 8.80%)  | 0.1778 (17.78%)  | 0.0482 ( 4.82%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Local)           | 0.2829 (28.29%)  | 0.3163 (31.63%)  | 0.0467 ( 4.67%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (Local +LattifAI) | 0.0714 ( 7.14%)  | 0.1420 (14.20%)  | 0.0467 ( 4.67%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (URL)               | 3.2400 (324.00%) | 0.8291 (82.91%)  | 0.0437 ( 4.37%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (URL +LattifAI)     | 0.0766 ( 7.66%)  | 0.1378 (13.78%)  | 0.0437 ( 4.37%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (Local)             | 0.3551 (35.51%)  | 0.4730 (47.30%)  | 0.0432 ( 4.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (Local +LattifAI)   | 0.1487 (14.87%)  | 0.3276 (32.76%)  | 0.0432 ( 4.32%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

##### 思考模式影响

```
| Model                                               |      DER ↓       |      JER ↓       |      WER ↓       |      SCA ↑       |      SCER ↓      |
|-----------------------------------------------------|------------------|------------------|------------------|------------------|------------------|
| gemini-3-flash-preview (no-think) (URL)             | 0.2712 (27.12%)  | 0.2940 (29.40%)  | 0.0653 ( 6.53%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (URL +LattifAI)   | 0.0655 ( 6.55%)  | 0.1147 (11.47%)  | 0.0653 ( 6.53%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (Local)           | 0.2720 (27.20%)  | 0.3225 (32.25%)  | 0.0505 ( 5.05%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-flash-preview (no-think) (Local +LattifAI) | 0.0756 ( 7.56%)  | 0.1542 (15.42%)  | 0.0505 ( 5.05%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (URL)               | 0.2555 (25.55%)  | 0.2981 (29.81%)  | 0.0547 ( 5.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (URL +LattifAI)     | 0.0992 ( 9.92%)  | 0.1692 (16.92%)  | 0.0547 ( 5.47%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (Local)             | 3.1893 (318.93%) | 0.8272 (82.72%)  | 0.0412 ( 4.12%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
| gemini-3-pro-preview (no-think) (Local +LattifAI)   | 0.0571 ( 5.71%)  | 0.1113 (11.13%)  | 0.0412 ( 4.12%)  | 1.0000 (100.00%) | 0.0000 ( 0.00%)  |
```

##### 温度参数对比

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
