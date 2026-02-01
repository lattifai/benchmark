#!/usr/bin/env python3
"""Update README.md with benchmark results from table files."""

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


def main():
    parser = argparse.ArgumentParser(description="Update README with benchmark results")
    parser.add_argument("--readme", required=True, help="Path to README.md")
    parser.add_argument("--main", required=True, help="Main benchmark table file")
    parser.add_argument("--url-local", required=True, help="URL vs Local table file")
    parser.add_argument("--no-thinking", required=True, help="No-thinking table file")
    parser.add_argument("--temperature", required=True, help="Temperature table file")
    args = parser.parse_args()

    # Read all tables
    main_table = read_table(args.main)
    url_local_table = read_table(args.url_local)
    no_thinking_table = read_table(args.no_thinking)
    temperature_table = read_table(args.temperature)

    print(f"Main: {len(main_table)} chars")
    print(f"URL/Local: {len(url_local_table)} chars")
    print(f"No-thinking: {len(no_thinking_table)} chars")
    print(f"Temperature: {len(temperature_table)} chars")

    # Read README
    readme_path = Path(args.readme)
    content = readme_path.read_text()

    # Build new Results section
    new_results = f"""#### Results

##### Main Benchmark

```
{main_table}
```

> **Note on WER differences**: YouTube Caption +LattifAI may show slightly different WER than the original. This is because LattifAI's `split_sentence` reorganizes fragmented YouTube captions (e.g., `"we have 100"` + `"million people"` → `"we have 100 million people"`), which affects how numbers are normalized during WER calculation (`100` + `million` → `1000000` vs `100 million` → `100000000`).

##### URL vs Local Audio

```
{url_local_table}
```

##### Thinking Mode Impact

```
{no_thinking_table}
```

##### Temperature Comparison

```
{temperature_table}
```

> **Metrics**: DER/JER = timing accuracy (lower = better), WER = transcription quality, SCA = speaker count accuracy

"""

    # Replace Results section (from #### Results to ## Quick Start)
    pattern = r"(#### Results\n).*?(?=\n## Quick Start)"
    new_content = re.sub(pattern, new_results, content, flags=re.DOTALL)

    # Write back
    readme_path.write_text(new_content)
    print(f"Updated: {readme_path}")


if __name__ == "__main__":
    main()
