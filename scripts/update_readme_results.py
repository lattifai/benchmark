#!/usr/bin/env python3
"""Update README.md and README-zh.md with benchmark results from table files.

Supports --lang <en|zh> for partial updates: only replace dataset blocks
matching the specified language while preserving other datasets' data.
"""

import argparse
import re
from pathlib import Path

# Dataset ID → language mapping (must match benchmark.sh ALL_DATASETS)
DATASET_LANG = {
    "OpenAI-Introducing-GPT-4o": "en",
    "TheValley101-GPT-4o-vs-Gemini": "zh",
}


def read_table(filepath: str) -> str:
    """Read table content from file, return empty string if not exists."""
    path = Path(filepath)
    if not path.exists():
        return "(No results yet)"
    content = path.read_text().strip()
    return content if content else "(No results yet)"


def parse_dataset_blocks(table_text: str) -> dict[str, str]:
    """Parse main table text into {dataset_id: block_text} dict.

    Each block starts with 'Dataset: <id>' followed by '---...' separator,
    then table rows, ending before the next 'Dataset:' line or end of text.
    """
    blocks = {}
    # Split by Dataset: header
    parts = re.split(r"(?=^Dataset: )", table_text, flags=re.MULTILINE)
    for part in parts:
        part = part.strip()
        if not part.startswith("Dataset: "):
            continue
        # Extract dataset id from first line
        first_line = part.split("\n", 1)[0]
        dataset_id = first_line.replace("Dataset: ", "").strip()
        blocks[dataset_id] = part
    return blocks


def merge_main_tables(existing_main: str, new_main: str, lang: str) -> str:
    """Merge new dataset blocks into existing main table by language.

    Only replaces blocks whose dataset_id matches the given language.
    """
    existing_blocks = parse_dataset_blocks(existing_main)
    new_blocks = parse_dataset_blocks(new_main)

    # Replace blocks matching the target language
    for dataset_id, block in new_blocks.items():
        ds_lang = DATASET_LANG.get(dataset_id)
        if ds_lang and ds_lang == lang:
            existing_blocks[dataset_id] = block
        elif ds_lang is None:
            # Unknown dataset — include it if it came from the new run
            existing_blocks[dataset_id] = block

    # Reassemble in a stable order (follow DATASET_LANG key order, then extras)
    ordered_ids = list(DATASET_LANG.keys())
    result_parts = []
    for did in ordered_ids:
        if did in existing_blocks:
            result_parts.append(existing_blocks[did])
    # Append any extra datasets not in DATASET_LANG
    for did, block in existing_blocks.items():
        if did not in ordered_ids:
            result_parts.append(block)

    return "\n\n\n".join(result_parts)


def extract_main_from_readme(content: str, start_pattern: str, end_pattern: str) -> str:
    """Extract the main benchmark code block content from README."""
    # Match: ##### <header>\n\n```\n<content>\n```
    # We need the content inside the first ``` block after the results header
    pattern = re.escape(start_pattern) + r"\n\n```\n(.*?)```"
    m = re.search(pattern, content, flags=re.DOTALL)
    return m.group(1).strip() if m else ""


def update_readme_en(readme_path: Path, tables: dict, lang: str | None) -> None:
    """Update English README.md."""
    content = readme_path.read_text()

    main_table = tables["main"]

    if lang:
        # Merge: only update datasets matching --lang
        existing_main = extract_main_from_readme(content, "##### Main Benchmark", "")
        if existing_main:
            main_table = merge_main_tables(existing_main, tables["main"], lang)

    # For --lang zh, keep existing url_local/no_thinking/temperature
    if lang == "zh":
        # Extract existing sub-tables from README to preserve them
        url_local = _extract_sub_table(content, "##### URL vs Local Audio") or tables["url_local"]
        no_thinking = _extract_sub_table(content, "##### Thinking Mode Impact") or tables["no_thinking"]
        temperature = _extract_sub_table(content, "##### Temperature Comparison") or tables["temperature"]
    else:
        url_local = tables["url_local"]
        no_thinking = tables["no_thinking"]
        temperature = tables["temperature"]

    new_results = f"""#### Results

##### Main Benchmark

```
{main_table}
```

> **Note on WER differences**: YouTube Caption +LattifAI may show slightly different WER than the original. This is because LattifAI's `split_sentence` reorganizes fragmented YouTube captions (e.g., `"we have 100"` + `"million people"` → `"we have 100 million people"`), which affects how numbers are normalized during WER calculation (`100` + `million` → `1000000` vs `100 million` → `100000000`).

##### URL vs Local Audio

```
{url_local}
```

##### Thinking Mode Impact

```
{no_thinking}
```

##### Temperature Comparison

```
{temperature}
```

> **Metrics**: DER/JER = timing accuracy (lower = better), WER = transcription quality, SCA = speaker count accuracy (only for diarization tests)

"""

    pattern = r"(#### Results\n).*?(?=\n## Quick Start)"
    new_content = re.sub(pattern, new_results, content, flags=re.DOTALL)

    readme_path.write_text(new_content)
    print(f"Updated: {readme_path}")


def update_readme_zh(readme_path: Path, tables: dict, lang: str | None) -> None:
    """Update Chinese README-zh.md."""
    content = readme_path.read_text()

    main_table = tables["main"]

    if lang:
        existing_main = extract_main_from_readme(content, "##### 主要基准测试", "")
        if existing_main:
            main_table = merge_main_tables(existing_main, tables["main"], lang)

    if lang == "zh":
        url_local = _extract_sub_table(content, "##### URL vs 本地音频") or tables["url_local"]
        no_thinking = _extract_sub_table(content, "##### 思考模式影响") or tables["no_thinking"]
        temperature = _extract_sub_table(content, "##### 温度参数对比") or tables["temperature"]
    else:
        url_local = tables["url_local"]
        no_thinking = tables["no_thinking"]
        temperature = tables["temperature"]

    new_results = f"""#### 结果

##### 主要基准测试

```
{main_table}
```

> **关于 WER 差异的说明**：YouTube Caption +LattifAI 可能显示与原始略有不同的 WER。这是因为 LattifAI 的 `split_sentence` 会重组 YouTube 的碎片化字幕（例如 `"we have 100"` + `"million people"` → `"we have 100 million people"`），这会影响 WER 计算时数字的规范化方式（`100` + `million` → `1000000` vs `100 million` → `100000000`）。

##### URL vs 本地音频

```
{url_local}
```

##### 思考模式影响

```
{no_thinking}
```

##### 温度参数对比

```
{temperature}
```

> **指标说明**：DER/JER = 时间戳准确度（越低越好），WER = 转录质量，SCA = 说话人数量准确率（仅用于说话人分离测试）

"""

    pattern = r"(#### 结果\n).*?(?=\n## 快速开始)"
    new_content = re.sub(pattern, new_results, content, flags=re.DOTALL)

    readme_path.write_text(new_content)
    print(f"Updated: {readme_path}")


def _extract_sub_table(readme_content: str, header: str) -> str | None:
    """Extract content inside a ```...``` block following a ##### header."""
    pattern = re.escape(header) + r"\n\n```\n(.*?)```"
    m = re.search(pattern, readme_content, flags=re.DOTALL)
    return m.group(1).strip() if m else None


def main():
    parser = argparse.ArgumentParser(description="Update README with benchmark results")
    parser.add_argument("--readme", required=True, help="Path to README.md")
    parser.add_argument("--main", required=True, help="Main benchmark table file")
    parser.add_argument("--url-local", required=True, help="URL vs Local table file")
    parser.add_argument("--no-thinking", required=True, help="No-thinking table file")
    parser.add_argument("--temperature", required=True, help="Temperature table file")
    parser.add_argument(
        "--lang", choices=["en", "zh"], default=None, help="Only update datasets for this language (merge mode)"
    )
    args = parser.parse_args()

    # Read all tables
    tables = {
        "main": read_table(args.main),
        "url_local": read_table(args.url_local),
        "no_thinking": read_table(args.no_thinking),
        "temperature": read_table(args.temperature),
    }

    print(f"Mode: {'merge (' + args.lang + ')' if args.lang else 'full replace'}")
    print(f"Main: {len(tables['main'])} chars")
    print(f"URL/Local: {len(tables['url_local'])} chars")
    print(f"No-thinking: {len(tables['no_thinking'])} chars")
    print(f"Temperature: {len(tables['temperature'])} chars")

    # Update English README
    readme_path = Path(args.readme)
    update_readme_en(readme_path, tables, args.lang)

    # Auto-detect and update Chinese README
    readme_zh_path = readme_path.parent / "README-zh.md"
    if readme_zh_path.exists():
        update_readme_zh(readme_zh_path, tables, args.lang)


if __name__ == "__main__":
    main()
