#!/usr/bin/env python3
"""Update README.md and README-zh.md with benchmark results from table files."""

import argparse
import re
from pathlib import Path


def read_table(filepath: str) -> str:
    """Read table content from file, return empty string if not exists."""
    path = Path(filepath)
    if not path.exists():
        return "(No results yet)"
    content = path.read_text().strip()
    return content if content else "(No results yet)"


def update_readme_en(readme_path: Path, tables: dict) -> None:
    """Update English README.md."""
    content = readme_path.read_text()

    new_results = f"""#### Results

##### Main Benchmark

```
{tables['main']}
```

> **Note on WER differences**: YouTube Caption +LattifAI may show slightly different WER than the original. This is because LattifAI's `split_sentence` reorganizes fragmented YouTube captions (e.g., `"we have 100"` + `"million people"` → `"we have 100 million people"`), which affects how numbers are normalized during WER calculation (`100` + `million` → `1000000` vs `100 million` → `100000000`).

##### URL vs Local Audio

```
{tables['url_local']}
```

##### Thinking Mode Impact

```
{tables['no_thinking']}
```

##### Temperature Comparison

```
{tables['temperature']}
```

> **Metrics**: DER/JER = timing accuracy (lower = better), WER = transcription quality, SCA = speaker count accuracy

"""

    pattern = r"(#### Results\n).*?(?=\n## Quick Start)"
    new_content = re.sub(pattern, new_results, content, flags=re.DOTALL)

    readme_path.write_text(new_content)
    print(f"Updated: {readme_path}")


def update_readme_zh(readme_path: Path, tables: dict) -> None:
    """Update Chinese README-zh.md."""
    content = readme_path.read_text()

    new_results = f"""#### 结果

##### 主要基准测试

```
{tables['main']}
```

> **关于 WER 差异的说明**：YouTube Caption +LattifAI 可能显示与原始略有不同的 WER。这是因为 LattifAI 的 `split_sentence` 会重组 YouTube 的碎片化字幕（例如 `"we have 100"` + `"million people"` → `"we have 100 million people"`），这会影响 WER 计算时数字的规范化方式（`100` + `million` → `1000000` vs `100 million` → `100000000`）。

##### URL vs 本地音频

```
{tables['url_local']}
```

##### 思考模式影响

```
{tables['no_thinking']}
```

##### 温度参数对比

```
{tables['temperature']}
```

> **指标说明**：DER/JER = 时间戳准确度（越低越好），WER = 转录质量，SCA = 说话人数量准确率

"""

    pattern = r"(#### 结果\n).*?(?=\n## 快速开始)"
    new_content = re.sub(pattern, new_results, content, flags=re.DOTALL)

    readme_path.write_text(new_content)
    print(f"Updated: {readme_path}")


def main():
    parser = argparse.ArgumentParser(description="Update README with benchmark results")
    parser.add_argument("--readme", required=True, help="Path to README.md")
    parser.add_argument("--main", required=True, help="Main benchmark table file")
    parser.add_argument("--url-local", required=True, help="URL vs Local table file")
    parser.add_argument("--no-thinking", required=True, help="No-thinking table file")
    parser.add_argument("--temperature", required=True, help="Temperature table file")
    args = parser.parse_args()

    # Read all tables
    tables = {
        "main": read_table(args.main),
        "url_local": read_table(args.url_local),
        "no_thinking": read_table(args.no_thinking),
        "temperature": read_table(args.temperature),
    }

    print(f"Main: {len(tables['main'])} chars")
    print(f"URL/Local: {len(tables['url_local'])} chars")
    print(f"No-thinking: {len(tables['no_thinking'])} chars")
    print(f"Temperature: {len(tables['temperature'])} chars")

    # Update English README
    readme_path = Path(args.readme)
    update_readme_en(readme_path, tables)

    # Auto-detect and update Chinese README
    readme_zh_path = readme_path.parent / "README-zh.md"
    if readme_zh_path.exists():
        update_readme_zh(readme_zh_path, tables)


if __name__ == "__main__":
    main()
