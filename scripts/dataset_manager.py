#!/usr/bin/env python3
"""Dataset management tool for LattifAI Benchmark."""

import argparse
import json
from pathlib import Path
from typing import Dict, List, Optional


class DatasetManager:
    """Manage benchmark datasets."""

    def __init__(self, data_root: Path = Path("data")):
        self.data_root = data_root
        self.datasets_file = data_root / "datasets.json"
        self.datasets = self._load_datasets()

    def _load_datasets(self) -> Dict:
        """Load datasets.json."""
        if not self.datasets_file.exists():
            return {"version": "1.0.0", "datasets": [], "languages": {}, "categories": {}}

        with open(self.datasets_file, "r", encoding="utf-8") as f:
            return json.load(f)

    def _save_datasets(self):
        """Save datasets.json."""
        with open(self.datasets_file, "w", encoding="utf-8") as f:
            json.dump(self.datasets, f, indent=2, ensure_ascii=False)

    def list_datasets(self, language: Optional[str] = None, category: Optional[str] = None) -> List[Dict]:
        """List all datasets with optional filters."""
        datasets = self.datasets.get("datasets", [])

        if language:
            datasets = [d for d in datasets if d["language"] == language]
        if category:
            datasets = [d for d in datasets if d["category"] == category]

        return datasets

    def get_dataset(self, dataset_id: str) -> Optional[Dict]:
        """Get dataset by ID."""
        for dataset in self.datasets.get("datasets", []):
            if dataset["id"] == dataset_id:
                return dataset
        return None

    def get_metadata(self, dataset_id: str) -> Optional[Dict]:
        """Get detailed metadata for a dataset."""
        dataset = self.get_dataset(dataset_id)
        if not dataset:
            return None

        metadata_path = self.data_root / dataset["path"] / "metadata.json"
        if not metadata_path.exists():
            return None

        with open(metadata_path, "r", encoding="utf-8") as f:
            return json.load(f)

    def add_dataset(
        self, dataset_id: str, name: str, language: str, category: str, video_url: str, description: str = "", **kwargs
    ) -> Dict:
        """Add a new dataset."""

        # Check if exists
        if self.get_dataset(dataset_id):
            raise ValueError(f"Dataset '{dataset_id}' already exists")

        # Create directory structure
        path = f"{category}/{language}/{dataset_id}"
        dataset_dir = self.data_root / path
        dataset_dir.mkdir(parents=True, exist_ok=True)

        # Create metadata.json
        metadata = {
            "id": dataset_id,
            "name": name,
            "description": description,
            "language": language,
            "video": {
                "url": video_url,
                "duration": kwargs.get("duration", 0),
                "format": kwargs.get("format", "youtube"),
            },
            "speakers": {"count": kwargs.get("num_speakers", 1), "labels": kwargs.get("speaker_labels", [])},
            "ground_truth": {
                "path": "ground_truth.ass",
                "format": "ass",
                "annotator": kwargs.get("annotator", "manual"),
                "annotation_date": kwargs.get("annotation_date", ""),
            },
            "results": [],
            "tags": kwargs.get("tags", []),
            "difficulty": kwargs.get("difficulty", "medium"),
            "created": kwargs.get("created", ""),
            "updated": kwargs.get("updated", ""),
        }

        metadata_path = dataset_dir / "metadata.json"
        with open(metadata_path, "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)

        # Add to datasets.json
        dataset_entry = {
            "id": dataset_id,
            "language": language,
            "category": category,
            "name": name,
            "description": description,
            "video_url": video_url,
            "duration": kwargs.get("duration", 0),
            "num_speakers": kwargs.get("num_speakers", 1),
            "path": path,
            "ground_truth": "ground_truth.ass",
            "models": kwargs.get("models", []),
            "tags": kwargs.get("tags", []),
        }

        self.datasets["datasets"].append(dataset_entry)
        self._save_datasets()

        print(f"✅ Created dataset: {dataset_id}")
        print(f"   Path: {dataset_dir}")
        print(f"   Metadata: {metadata_path}")

        return dataset_entry

    def print_datasets(self, datasets: List[Dict]):
        """Pretty print datasets."""
        if not datasets:
            print("No datasets found.")
            return

        print(f"\n{'ID':<25} {'Language':<10} {'Category':<15} {'Name':<40}")
        print("=" * 95)
        for ds in datasets:
            print(f"{ds['id']:<25} " f"{ds['language']:<10} " f"{ds['category']:<15} " f"{ds['name']:<40}")
        print(f"\nTotal: {len(datasets)} datasets\n")


def main():
    parser = argparse.ArgumentParser(description="LattifAI Dataset Manager")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # List command
    list_parser = subparsers.add_parser("list", help="List datasets")
    list_parser.add_argument("-l", "--language", help="Filter by language")
    list_parser.add_argument("-c", "--category", help="Filter by category")

    # Show command
    show_parser = subparsers.add_parser("show", help="Show dataset details")
    show_parser.add_argument("dataset_id", help="Dataset ID")

    # Add command
    add_parser = subparsers.add_parser("add", help="Add new dataset")
    add_parser.add_argument("dataset_id", help="Dataset ID")
    add_parser.add_argument("name", help="Dataset name")
    add_parser.add_argument("language", help="Language code (en, zh, ja, ...)")
    add_parser.add_argument("category", help="Category (alignment, transcription, ...)")
    add_parser.add_argument("video_url", help="Video URL")
    add_parser.add_argument("-d", "--description", default="", help="Description")
    add_parser.add_argument("--duration", type=int, default=0, help="Duration in seconds")
    add_parser.add_argument("--speakers", type=int, default=1, help="Number of speakers")
    add_parser.add_argument("--tags", nargs="+", default=[], help="Tags")

    args = parser.parse_args()

    manager = DatasetManager()

    if args.command == "list":
        datasets = manager.list_datasets(language=args.language, category=args.category)
        manager.print_datasets(datasets)

    elif args.command == "show":
        dataset = manager.get_dataset(args.dataset_id)
        if not dataset:
            print(f"❌ Dataset not found: {args.dataset_id}")
            return

        metadata = manager.get_metadata(args.dataset_id)

        print(f"\n{'=' * 60}")
        print(f"Dataset: {dataset['name']}")
        print(f"{'=' * 60}")
        print(f"ID:          {dataset['id']}")
        print(f"Language:    {dataset['language']}")
        print(f"Category:    {dataset['category']}")
        print(f"Video:       {dataset['video_url']}")
        print(f"Duration:    {dataset['duration']}s")
        print(f"Speakers:    {dataset['num_speakers']}")
        print(f"Path:        {dataset['path']}")
        print(f"Tags:        {', '.join(dataset.get('tags', []))}")

        if metadata:
            print(f"\nGround Truth: {metadata['ground_truth']['path']}")
            print(f"Results:      {len(metadata.get('results', []))} models")

        print()

    elif args.command == "add":
        try:
            manager.add_dataset(
                dataset_id=args.dataset_id,
                name=args.name,
                language=args.language,
                category=args.category,
                video_url=args.video_url,
                description=args.description,
                duration=args.duration,
                num_speakers=args.speakers,
                tags=args.tags,
            )
        except ValueError as e:
            print(f"❌ Error: {e}")

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
