#!/usr/bin/env python3
import argparse
import json
import os
from datetime import datetime, timezone

def read_cpu_model():
    try:
        with open("/proc/cpuinfo", "r", encoding="utf-8") as handle:
            for line in handle:
                if line.lower().startswith("model name"):
                    return line.split(":", 1)[1].strip()
    except OSError:
        return "unknown"
    return "unknown"

def read_mem_total_gib():
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as handle:
            for line in handle:
                if line.startswith("MemTotal:"):
                    parts = line.split()
                    if len(parts) >= 2:
                        kb = int(parts[1])
                        return kb / (1024 * 1024)
    except OSError:
        return 0.0
    return 0.0

def format_float(value, digits=2):
    return f"{value:.{digits}f}"

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--worlds", required=True)
    parser.add_argument("--players-per-world", type=int, required=True)
    parser.add_argument("--villagers-per-player", type=int, required=True)
    parser.add_argument("--warmup-ticks", type=int, required=True)
    parser.add_argument("--sample-ticks", type=int, required=True)
    parser.add_argument("--sample-interval", type=int, required=True)
    parser.add_argument("--seed", required=True)
    parser.add_argument("--duration-seconds", type=int, required=True)
    return parser.parse_args()

def main():
    args = parse_args()
    with open(args.summary, "r", encoding="utf-8") as handle:
        summary = json.load(handle)

    cpu_model = read_cpu_model()
    mem_gib = read_mem_total_gib()
    cores = os.cpu_count() or 0
    timestamp = datetime.now(timezone.utc).isoformat()

    worlds = " ".join(args.worlds.split())
    total_players = args.players_per_world * len(args.worlds.split())
    total_villagers = args.villagers_per_player * total_players

    lines = []
    lines.append("# Pewpew Multiworld Bench Report")
    lines.append("")
    lines.append(f"- Timestamp (UTC): {timestamp}")
    lines.append(f"- CPU model: {cpu_model}")
    lines.append(f"- CPU cores: {cores}")
    lines.append(f"- Memory: {format_float(mem_gib, 2)} GiB")
    lines.append("")
    lines.append("## Scenario")
    lines.append(f"- Worlds: {worlds}")
    lines.append(f"- Players per world: {args.players_per_world}")
    lines.append(f"- Total players: {total_players}")
    lines.append(f"- Villagers per player: {args.villagers_per_player}")
    lines.append(f"- Approx total villagers: {total_villagers}")
    lines.append(f"- Seed: {args.seed}")
    lines.append(f"- Warmup ticks: {args.warmup_ticks}")
    lines.append(f"- Sample ticks: {args.sample_ticks}")
    lines.append(f"- Sample interval ticks: {args.sample_interval}")
    lines.append(f"- Run duration seconds: {args.duration_seconds}")
    lines.append("")
    lines.append("## Results")
    lines.append(f"- Samples: {summary.get('samples', 0)}")
    lines.append(f"- Avg MSPT: {format_float(summary.get('avgMspt', 0.0))}")
    lines.append(f"- P95 MSPT: {format_float(summary.get('p95Mspt', 0.0))}")
    lines.append(f"- Avg TPS: {format_float(summary.get('avgTps', 0.0))}")
    lines.append(f"- Avg villagers: {format_float(summary.get('avgVillagers', 0.0))}")
    lines.append(f"- Avg hostiles: {format_float(summary.get('avgHostiles', 0.0))}")
    lines.append("")

    with open(args.output, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
        handle.write("\n")

if __name__ == "__main__":
    main()
