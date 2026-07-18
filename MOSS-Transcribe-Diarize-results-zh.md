# MOSS-Transcribe-Diarize — DER / WER 评测

> English version: [MOSS-Transcribe-Diarize-results.md](MOSS-Transcribe-Diarize-results.md)

对
[`OpenMOSS-Team/MOSS-Transcribe-Diarize`](https://huggingface.co/OpenMOSS-Team/MOSS-Transcribe-Diarize)
(0.9B) 做端到端"转录 + 说话人分离"评测,数据来自本仓库的两个数据集。

## 环境配置

| 项目 | 取值 |
|------|------|
| 模型 | [`OpenMOSS-Team/MOSS-Transcribe-Diarize`](https://huggingface.co/OpenMOSS-Team/MOSS-Transcribe-Diarize)(HF 版本 [`e6d68cd`](https://huggingface.co/OpenMOSS-Team/MOSS-Transcribe-Diarize/commit/e6d68cd),2026‑07‑15) |
| 服务 | vLLM `0.23.1rc1.dev949+g68b4a1d58.cu129`(按模型卡指定的 pinned nightly),OpenAI `/v1/audio/transcriptions` 端点 |
| 主机 | `ubuntu_local`,单卡 RTX 4090(24 GB) |
| 解码 | 贪心(`temperature=0`),`max_completion_tokens=40000` |
| 提示词 | 服务端默认(带时间戳的转录 + `[Sxx]` 说话人分离) |
| 评测 | `eval.py`,`collar=0.25`,`skip_overlap=false`,语言自动识别 |
| 日期 | 2026‑07‑18 |

评测前把 MOSS 的说话人标签 `S01/S02/…` 改写为 `Speaker 1/2/…`(否则 `[Sxx]`
形式会被 eval.py 的说话人名规范化逻辑折叠成单一说话人)。DER 计算时再由 pyannote 的
最优映射把假设说话人对齐到参考的真实姓名。

## 结果(collar = 0.25 s)

| 数据集 | 语言 | 时长 | DER ↓ | WER ↓ | JER ↓ | SCA ↑ | SCER ↓ |
|--------|------|------|-------|-------|-------|-------|--------|
| OpenAI-Introducing-GPT-4o | 英 | 26:13 | **14.88 %** | **4.02 %** | 38.87 % | 100 % | 0 % |
| TheValley101-GPT-4o-vs-Gemini | 中 & 英 | 27:08 | **4.98 %** | **4.32 %** | 65.84 % | 0 % | 44.4 % |

### DER 分量拆解(秒,collar = 0.25 s)

| 数据集 | 虚检 (FA) | 漏检 (Miss) | 混淆 (Conf) | 正确 | 总计 |
|--------|-----------|-------------|-------------|------|------|
| OpenAI-Introducing-GPT-4o | 10.27 | 21.99 | 131.00 | 944.48 | 1097.47 |
| TheValley101-GPT-4o-vs-Gemini | 1.41 | 37.13 | 36.94 | 1442.27 | 1516.34 |

### 对 collar 的敏感性

| 数据集 | DER @0.20 | DER @0.25 | WER |
|--------|-----------|-----------|-----|
| OpenAI-Introducing-GPT-4o | 15.43 % | 14.88 % | 4.02 % |
| TheValley101-GPT-4o-vs-Gemini | 5.09 % | 4.98 % | 4.32 % |

## 说明

- **转录质量优秀(WER ≈ 4 %)**:无论是英文发布会还是中英混合解说都很好。
- **OpenAI 发布会**:MOSS 恰好识别出 4 个说话人(SCA = 100 %)。残余 DER 主要是
  *混淆*(131 s)——参考区分了 4 位具名说话人,而 MOSS 在演示环节把其中两位搞混了。
- **TheValley101**:DER 很低(5 %),因为一位主播(`host`)主导了绝大部分音频且被
  准确追踪;但 MOSS 欠分割了众多短暂的采访说话人——只输出 5 个匿名说话人 vs 参考的
  约 10 个(SCER = 44 %),这抬高了 JER,尽管按时间加权的 DER 仍然很小。
- 首次运行在约 5120 输出 token 处被截断(模型卡 `generation_config.json` 的默认值)。
  把 `max_completion_tokens` 提到 40000 后解码器才能生成完整的分离转录;两段音频都
  端到端覆盖(1543 s / 1624 s)。

## 错误分析

各数据集的错误类型拆解(collar = 0.25 s,来自 `eval.py --verbose`):

| 数据集 | 虚检 (FA) | 漏检 (Miss) | 混淆 (Conf) | 主导错误 |
|--------|-----------|-------------|-------------|----------|
| OpenAI-Introducing-GPT-4o | 10.3 s / 110 段 | 22.0 s / 75 段 | **131.0 s / 68 段** | 说话人混淆 |
| TheValley101-GPT-4o-vs-Gemini | 1.4 s / 14 段 | 37.1 s / 466 段 | 36.9 s / 28 段 | 边界碎片 + 嵌入片段 |

### OpenAI 发布会 —— 单一系统性混淆主导(占错误 80 %)

最优说话人映射:`Speaker 1→Mira Murati`、`Speaker 3→Barrett Zoph`、
`Speaker 4→ChatGPT`。**Mark Chen 没有专属的假设说话人。**

混淆(131 s)几乎全部来自一处失败:在 GPT-4o 现场演示环节(约 558 s–1399 s)
**MOSS 把 Mark Chen 和 Barrett Zoph 合并成同一个说话人(`Speaker 3`)**。Mark 主持
演示、Barrett 扮演"朋友",两人快速交替对话,MOSS 在声学上无法区分,于是 Mark Chen
几乎全部语音都被算作对 `Speaker 3` 的混淆。代表性片段:

```
[562.05-566.98] CONF  ref=Mark Chen  hyp=Barrett Zoph  "So one of the key capabilities we're really excited…"
[659.52-663.45] CONF  ref=Mark Chen  hyp=Barrett Zoph  "Right, so if you've used our voice mode experience…"
[719.55-722.53] CONF  ref=Mark Chen  hyp=Barrett Zoph  "So my friend Barrett here, he's been having trouble…"
```

其余约 32 s(FA + MISS)都是亚秒级的时间戳边界碎片(75 段 MISS 里 47 段 < 0.3 s;
全部 110 段 FA 都 < 0.3 s),属于 collar 边缘的对齐噪声,不是真正的检测错误。开场/
结尾的 Mira Murati 和 ChatGPT 演示语音都被正确追踪(SCA = 100 %)。

### TheValley101 —— 没有单一热点;DER 低,但欠分割

最优映射:`Speaker 1→host`、`Speaker 2→ChatGPT`、`Speaker 3→Yusen Dai`、
`Speaker 5→Howie Xu`。错误在 MISS(37 s)和 CONF(37 s)之间大致均分:

- **MISS(37 s)全是碎片**:466 段里 449 段 < 0.3 s,没有一段超过 1 s——纯粹是相对
  参考的时间戳边界错位,而非漏掉的语音。
- **CONF(37 s)来自嵌入的英文原声片段。** 这是一段中文配音视频,中间剪进了 GPT-4o /
  Project Astra 的原始发布片段。在这些片段里,MOSS 把多个英文说话人(Mark Chen、
  ChatGPT、Barrett Zoph、Mira Murati、Astra User)大多折叠进了 `host` 或 `ChatGPT`:

```
[237.97-239.94] CONF  ref=ChatGPT      hyp=host     "Mark you're not a vacuum cleaner"
[570.62-572.91] CONF  ref=Astra User1  hyp=host     "What can I add here to make this system faster"
[347.99-349.74] CONF  ref=User_1       hyp=ChatGPT  "Do the singing voice again please"
```

DER 保持在约 5 %,因为中文主播(`host`)主导了运行时长且被准确追踪;但 MOSS 只输出
5 个说话人 vs 参考的约 10 个(SCA = 0,SCER = 44 %)——它欠分割了众多短暂的采访/
片段人声。

### 技术报告如何看待交错 / 重叠语音

MOSS 报告(arXiv:2601.01554)**确实明确针对快速交替和重叠做了优化**,所以上面的
联合主持人混淆,正是他们声称优化过的场景:

- **模拟训练数据**由"可控概率模拟器……强制说话人交替,同时允许重叠上限为较短片段的
  80 %"构造(§3.2)——这是针对交替/重叠说话人的刻意数据增强,而不仅仅是自然录音里
  偶发的重叠。
- 专门的 **Movies** 基准"以短句、快速说话人交替和频繁重叠为特征",他们在此报告了
  最优的 cpCER 和 Δcp,以及"在多样对话场景下对说话人边界的鲁棒处理"。
- 他们的核心分离指标是 **Δcp**(说话人归因带来的额外 CER),在"频繁交替和长距离
  说话人再进入"下报告为最低。

对比时的注意点:他们的结论建立在电影对白上的 **cpCER/Δcp**(文本 / 归因层面),而
上面的联合主持人合并是用英文 live demo 上的**时间维度 DER** 衡量的。指标和数据域都
不同——但它确实说明了那个失败模式(快速交替的共说话人被折叠成一个标签)在实践中
仍会出现。

### 要点

- 转录在任何场景都不是瓶颈(两个数据集 WER ≈ 4 %)。
- 真正的短板是**分离同一声学场景里快速交替的说话人**——发布会里的联合主持人
  (OpenAI),以及剪辑片段里的多个人声(TheValley101)。MOSS 倾向于把这类交错语音
  归到一个主导标签上。
- 时间戳粒度没问题,但边界有几十毫秒偏移,产生大量微小的 collar 边缘 FA/MISS 碎片;
  这些抬高了段数,但对总时长贡献很小。

## 复现

```bash
# 在 ubuntu_local 上:启动服务(encoder 缓存按约 26 分钟音频设定,单序列以适配 24 GB)
VLLM_MAX_AUDIO_DECODE_DURATION_S=7200 PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
vllm serve OpenMOSS-Team/MOSS-Transcribe-Diarize --trust-remote-code \
  --port 8010 --gpu-memory-utilization 0.55 --max-model-len 65536 \
  --max-num-batched-tokens 32768 --max-num-seqs 1

# 转录 + 解析为 ASS
python scripts/moss_transcribe.py audio.mp3 --api-base http://localhost:8010/v1 \
  --model MOSS-Transcribe-Diarize -o data/<dataset>/moss-transcribe-diarize

# 评测
python eval.py -r data/<dataset>/ground_truth.ass \
  -hyp data/<dataset>/moss-transcribe-diarize.ass -m der jer wer sca scer -c 0.25
```
