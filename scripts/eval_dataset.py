#!/usr/bin/env python3
"""Evaluate a single dataset with all available models."""

import argparse
import json
import subprocess
from pathlib import Path
from typing import List, Optional


def eval_dataset(
    dataset_id: str, data_root: Path = Path("data"), metrics: Optional[List[str]] = None, collar: float = 0.0
):
    """Evaluate all models for a dataset."""

    if metrics is None:
        metrics = ["der", "jer", "wer", "sca", "scer"]

    # Load dataset metadata
    datasets_file = data_root / "datasets.json"
    with open(datasets_file, "r") as f:
        datasets_info = json.load(f)

    # Find dataset
    dataset = None
    for ds in datasets_info["datasets"]:
        if ds["id"] == dataset_id:
            dataset = ds
            break

    if not dataset:
        print(f"❌ Dataset not found: {dataset_id}")
        return

    # Load detailed metadata
    dataset_dir = data_root / dataset["path"]
    metadata_file = dataset_dir / "metadata.json"

    with open(metadata_file, "r") as f:
        metadata = json.load(f)

    # Ground truth path
    ground_truth = dataset_dir / metadata["ground_truth"]["path"]
    if not ground_truth.exists():
        print(f"❌ Ground truth not found: {ground_truth}")
        return

    print(f"\n{'=' * 70}")
    print(f"Evaluating Dataset: {metadata['name']}")
    print(f"{'=' * 70}")
    print(f"Language: {metadata['language']}")
    print(f"Speakers: {metadata['speakers']['count']}")
    print(f"Ground Truth: {ground_truth.name}")
    print(f"Metrics: {', '.join(metrics)}")
    print(f"{'=' * 70}\n")

    # Evaluate ground truth (baseline)
    print("📊 Ground Truth (baseline)")
    cmd = [
        "python",
        "eval.py",
        "-r",
        str(ground_truth),
        "-hyp",
        str(ground_truth),
        "--metrics",
        *metrics,
        "--collar",
        str(collar),
        "--model-name",
        "Ground Truth",
    ]
    subprocess.run(cmd, check=True)

    # Evaluate each model
    for result in metadata.get("results", []):
        model_name = result["model"]
        files = result["files"]

        print(f"\n{'─' * 70}")

        # Evaluate raw/converted version
        if "converted" in files:
            converted_path = dataset_dir / files["converted"]
            if converted_path.exists():
                print(f"📊 {model_name}")
                cmd = [
                    "python",
                    "eval.py",
                    "-r",
                    str(ground_truth),
                    "-hyp",
                    str(converted_path),
                    "--metrics",
                    *metrics,
                    "--collar",
                    str(collar),
                    "--model-name",
                    model_name,
                ]
                subprocess.run(cmd, check=True)

        # Evaluate aligned version
        if "aligned" in files:
            aligned_path = dataset_dir / files["aligned"]
            if aligned_path.exists():
                print(f"📊 {model_name} + LattifAI")
                cmd = [
                    "python",
                    "eval.py",
                    "-r",
                    str(ground_truth),
                    "-hyp",
                    str(aligned_path),
                    "--metrics",
                    *metrics,
                    "--collar",
                    str(collar),
                    "--model-name",
                    f"{model_name} + LattifAI",
                ]
                subprocess.run(cmd, check=True)

    print(f"\n{'=' * 70}")
    print("✅ Evaluation Complete")
    print(f"{'=' * 70}\n")


def main():
    parser = argparse.ArgumentParser(description="Evaluate a benchmark dataset")
    parser.add_argument("dataset_id", help="Dataset ID to evaluate")
    parser.add_argument(
        "-m", "--metrics", nargs="+", default=["der", "jer", "wer", "sca", "scer"], help="Metrics to compute"
    )
    parser.add_argument("--collar", type=float, default=0.0, help="Collar for DER/JER (seconds)")
    parser.add_argument("--data-root", type=Path, default=Path("data"), help="Data root directory")

    args = parser.parse_args()

    eval_dataset(dataset_id=args.dataset_id, data_root=args.data_root, metrics=args.metrics, collar=args.collar)


if __name__ == "__main__":
    main()
