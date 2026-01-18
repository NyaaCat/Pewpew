# Test Automation Plan

## Goals
- Correctness tests run automatically on every build and in CI.
- A/B perf tests run via an explicit task in CI (not part of default builds).
- No human interaction required (no prompts, GUI, or manual steps).
- Build fails on correctness or performance regression.

## Test tiers
- Unit tests: fast, deterministic, no server bootstrap.
- Integration tests: headless server boot, scripted scenarios, deterministic seeds.
- Performance checks: smoke-level benchmarks with thresholds and compare to baseline.

## Automation requirements
- Provide Gradle tasks that run all tests in one command (e.g., `./gradlew check`).
- Provide a dedicated perf task (e.g., `./gradlew :pewpew-server:pewpewPerfAB`) for A/B runs.
- Use headless server runner with timeouts and log capture.
- Ensure tests clean up worlds/data directories automatically.
- Explicitly disable interactive prompts in test runs.

## Perf testing strategy
- Fixed seed, fixed scenario scripts, fixed entity counts.
- Capture key metrics: tick time, AI/pathfinding time, allocations.
- Set thresholds for acceptable variance; fail build on regression beyond threshold.
- Run A/B on the same machine and config: vanilla Paper vs Pewpew.
- Tag perf tests with `PewpewPerf`; tag Pewpew-only perf tests with `PewpewOnly`.
- Store both baselines and deltas in `docs/pewpew/findings/perf-report.md`.
- Baseline file path: `docs/pewpew/findings/perf-baseline.properties`.
- Use `-Dpewpew.perf.mode=baseline` for vanilla Paper; default mode compares against baseline.
- Use `-Dpewpew.perf.reportFile` to force a shared report location when running across repos.

## Bench harness (bots + villagers + hostiles)
- Mineflayer bots keep chunks loaded; default 10 bots and 10 cells (1 bot per cell).
- 40 villagers + 40 hostiles per cell, with job sites rotating every 20 ticks and hostile retargeting every 20 ticks.
- Day/night phases every 2400 ticks to exercise villager work schedules and natural spawning.
- Workstation layout + job-site rotation target AcquirePoi/Brain hot paths seen in profiler v23/v24.
- Entry point: `scripts/bench/run_benchmark.sh` (writes results to `docs/pewpew/findings/perf-bench-report.md`).
