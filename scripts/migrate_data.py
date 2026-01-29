#!/usr/bin/env python3
"""Migrate existing test data to new multi-language structure."""

import json
import shutil
from pathlib import Path


def migrate_introducing_gpt4o():
    """Migrate introducing-gpt4o data to new structure."""

    # Paths
    old_dir = Path("data/introducing-gpt4o")
    new_dir = Path("data/alignment/en/introducing-gpt4o")
    results_dir = new_dir / "results"

    # Create new structure
    results_dir.mkdir(parents=True, exist_ok=True)

    # Copy ground truth
    if (old_dir / "ground_truth.ass").exists():
        shutil.copy2(old_dir / "ground_truth.ass", new_dir / "ground_truth.ass")
        print("✓ Copied ground_truth.ass")

    # Move model results
    patterns = [
        ("gemini_2.5_pro", "gemini-2.5-pro"),
        ("gemini_3_pro", "gemini-3-pro-preview"),
        ("gemini_3_flash", "gemini-3-flash-preview"),
    ]

    for file_prefix, model_name in patterns:
        for ext in [".md", ".ass"]:
            src = old_dir / f"{file_prefix}{ext}"
            if src.exists():
                dst = results_dir / f"{file_prefix}{ext}"
                shutil.copy2(src, dst)
                print(f"✓ Copied {src.name}")

        # Aligned version
        src = old_dir / f"{file_prefix}_lattifai.ass"
        if src.exists():
            dst = results_dir / f"{file_prefix}_lattifai.ass"
            shutil.copy2(src, dst)
            print(f"✓ Copied {src.name}")

    print(f"\n✅ Migration complete: {new_dir}")
    print(f"   Ground truth: {new_dir / 'ground_truth.ass'}")
    print(f"   Results: {results_dir}")


def create_example_zh_dataset():
    """Create example Chinese dataset structure."""

    zh_dir = Path("data/alignment/zh/example-case")
    zh_dir.mkdir(parents=True, exist_ok=True)

    metadata = {
        "id": "example-case",
        "name": "示例中文数据集",
        "description": "中文语音对齐测试数据集示例",
        "language": "zh",
        "video": {"url": "https://example.com/video", "duration": 120, "format": "youtube"},
        "speakers": {"count": 1, "labels": ["说话人"]},
        "ground_truth": {
            "path": "ground_truth.ass",
            "format": "ass",
            "annotator": "manual",
            "annotation_date": "2026-01",
        },
        "results": [],
        "tags": ["chinese", "example"],
        "difficulty": "easy",
        "created": "2026-01-29",
        "updated": "2026-01-29",
    }

    with open(zh_dir / "metadata.json", "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Created example Chinese dataset: {zh_dir}")


if __name__ == "__main__":
    print("🔄 Migrating test data to new structure...\n")

    migrate_introducing_gpt4o()
    create_example_zh_dataset()

    print("\n📊 New structure:")
    print(
        """
    data/
    ├── datasets.json                           # Global dataset index
    ├── alignment/
    │   ├── en/
    │   │   └── introducing-gpt4o/
    │   │       ├── metadata.json               # Dataset metadata
    │   │       ├── ground_truth.ass            # Reference
    │   │       └── results/                    # Model outputs
    │   │           ├── gemini_*.md
    │   │           ├── gemini_*.ass
    │   │           └── gemini_*_lattifai.ass
    │   └── zh/
    │       └── example-case/
    │           └── metadata.json
    """
    )

    print("\n💡 Next steps:")
    print("1. Review migrated data in data/alignment/en/introducing-gpt4o/")
    print("2. Add more datasets by creating new language/case folders")
    print("3. Update scripts/reproduce.sh to use new structure")
    print("4. Update eval.py to support dataset discovery")
