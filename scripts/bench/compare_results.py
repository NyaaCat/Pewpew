#!/usr/bin/env python3
import json
import math
import sys
from pathlib import Path


def load(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def pct_delta(base, new):
    if base == 0:
        return 0.0
    return ((base - new) / base) * 100.0


def fmt(value):
    if isinstance(value, float):
        return f"{value:.2f}"
    return str(value)


def render_section(label, base, new):
    lines = [
        f"- {label} avgMspt: {fmt(new['avgMspt'])} (baseline {fmt(base['avgMspt'])}, delta {fmt(base['avgMspt'] - new['avgMspt'])}ms, {fmt(pct_delta(base['avgMspt'], new['avgMspt']))}%)",
        f"- {label} p95Mspt: {fmt(new['p95Mspt'])} (baseline {fmt(base['p95Mspt'])}, delta {fmt(base['p95Mspt'] - new['p95Mspt'])}ms, {fmt(pct_delta(base['p95Mspt'], new['p95Mspt']))}%)",
        f"- {label} avgTps: {fmt(new['avgTps'])} (baseline {fmt(base['avgTps'])}, delta {fmt(new['avgTps'] - base['avgTps'])})",
        f"- {label} avgVillagers: {fmt(new['avgVillagers'])} (baseline {fmt(base['avgVillagers'])})",
        f"- {label} avgHostiles: {fmt(new['avgHostiles'])} (baseline {fmt(base['avgHostiles'])})",
    ]
    return lines


def main():
    if len(sys.argv) != 4:
        print("usage: compare_results.py BASELINE_JSON COMPARE_JSON OUTPUT.md")
        return 1
    baseline_path = Path(sys.argv[1])
    compare_path = Path(sys.argv[2])
    output_path = Path(sys.argv[3])

    baseline = load(baseline_path)
    compare = load(compare_path)

    lines = []
    lines.append("# Pewpew Bench Report")
    lines.append("")
    lines.append("## Overall")
    lines.extend(render_section("overall", baseline, compare))
    lines.append("")
    lines.append("## Day")
    lines.extend(render_section("day", baseline["day"], compare["day"]))
    lines.append("")
    lines.append("## Night")
    lines.extend(render_section("night", baseline["night"], compare["night"]))
    lines.append("")
    lines.append(f"- Samples: baseline {baseline['samples']}, compare {compare['samples']}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
