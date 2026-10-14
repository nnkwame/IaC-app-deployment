#!/usr/bin/env python3

import csv
import json
from pathlib import Path

import matplotlib.pyplot as plt


def load_results(results_dir: Path):
    rows = []

    for path in sorted(results_dir.glob("*.json")):
        with path.open() as f:
            data = json.load(f)

        latency = data["latency_ms"]

        rows.append({
            "endpoint": data["endpoint"],
            "port": data["port"],
            "vus": data["vus"],
            "p05_ms": latency["p05"],
            "p25_ms": latency["p25"],
            "median_ms": latency["median"],
            "average_ms": latency["average"],
            "p75_ms": latency["p75"],
            "p95_ms": latency["p95"],
            "p99_ms": latency["p99"],
            "failure_pct": data["failure_rate"] * 100,
            "requests": data["requests"],
            "rps": data["requests_per_second"],
            "timestamp": data["timestamp"],
        })

    return sorted(rows, key=lambda row: (row["endpoint"], row["vus"]))


def write_csv(rows, output_path: Path):
    if not rows:
        return

    with output_path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)


def endpoint_rows(rows, endpoint):
    return sorted(
        [row for row in rows if row["endpoint"] == endpoint],
        key=lambda row: row["vus"],
    )


def plot_latency(rows, endpoint, output_dir):
    data = endpoint_rows(rows, endpoint)

    labels = [str(row["vus"]) for row in data]
    positions = list(range(1, len(data) + 1))

    stats = []

    for row in data:
        stats.append({
            "label": str(row["vus"]),
            "whislo": row["p05_ms"],
            "q1": row["p25_ms"],
            "med": row["median_ms"],
            "q3": row["p75_ms"],
            "whishi": row["p95_ms"],
            "fliers": [],
        })

    fig, ax = plt.subplots(figsize=(12, 6))

    ax.bxp(
        stats,
        positions=positions,
        widths=0.5,
        showfliers=False,
    )

    ax.scatter(
        positions,
        [row["average_ms"] for row in data],
        marker="x",
        label="Average",
    )

    ax.scatter(
        positions,
        [row["p99_ms"] for row in data],
        marker=".",
        label="p99",
    )

    ax.set_xticks(positions)
    ax.set_xticklabels(labels)

    ax.set_xlabel("Virtual users")
    ax.set_ylabel("Latency (ms)")
    ax.set_title(f"{endpoint} latency vs load")

    ax.legend()
    ax.grid(True, alpha=0.3)

    fig.tight_layout()
    fig.savefig(
        output_dir / f"{endpoint}-latency.png",
        dpi=150,
    )
    plt.close(fig)


def plot_failure_rate(rows, endpoint, output_dir):
    data = endpoint_rows(rows, endpoint)

    labels = [str(row["vus"]) for row in data]
    positions = list(range(1, len(data) + 1))

    fig, ax = plt.subplots(figsize=(10, 5))

    ax.scatter(
        positions,
        [row["failure_pct"] for row in data],
    )

    ax.set_xticks(positions)
    ax.set_xticklabels(labels)

    ax.set_xlabel("Virtual users")
    ax.set_ylabel("Failed requests (%)")
    ax.set_title(f"{endpoint} request failure rate")

    ax.grid(True, alpha=0.3)

    fig.tight_layout()
    fig.savefig(
        output_dir / f"{endpoint}-failure-rate.png",
        dpi=150,
    )
    plt.close(fig)


def plot_rps(rows, endpoint, output_dir):
    data = endpoint_rows(rows, endpoint)

    labels = [str(row["vus"]) for row in data]
    positions = list(range(1, len(data) + 1))

    fig, ax = plt.subplots(figsize=(10, 5))

    ax.scatter(
        positions,
        [row["rps"] for row in data],
    )

    ax.set_xticks(positions)
    ax.set_xticklabels(labels)

    ax.set_xlabel("Virtual users")
    ax.set_ylabel("Requests / second")
    ax.set_title(f"{endpoint} throughput vs load")

    ax.grid(True, alpha=0.3)

    fig.tight_layout()
    fig.savefig(
        output_dir / f"{endpoint}-requests-per-second.png",
        dpi=150,
    )
    plt.close(fig)


def main():
    base_dir = Path(__file__).resolve().parent
    results_dir = base_dir / "results"
    plots_dir = results_dir / "plots"

    plots_dir.mkdir(parents=True, exist_ok=True)

    rows = load_results(results_dir)

    if not rows:
        raise SystemExit("No k6 result JSON files found.")

    write_csv(
        rows,
        results_dir / "all-results.csv",
    )

    endpoints = sorted({
        row["endpoint"]
        for row in rows
    })

    for endpoint in endpoints:
        plot_latency(
            rows,
            endpoint,
            plots_dir,
        )

        plot_failure_rate(
            rows,
            endpoint,
            plots_dir,
        )

        plot_rps(
            rows,
            endpoint,
            plots_dir,
        )


if __name__ == "__main__":
    main()
