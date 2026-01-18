# Performance Reports

## Worker pool microbenchmark
- Status: blocked (Gradle wrapper download blocked in sandbox; no network)
- Report file (once tests run): `paper/paper-server/build/reports/pewpew/worker-pool-perf.txt`
- 2026-01-17T17:54:44.736303082Z BaselineLoop iterations=1000000 duration_ns=2856302 ns_per_op=2 baseline_ns_per_op=2
- 2026-01-17T17:56:50.067813416Z CommitQueue.enqueueDrain iterations=20000 duration_ns=11869743 ns_per_op=593 baseline_ns_per_op=n/a
- 2026-01-17T17:56:51.236079971Z SnapshotManager.buildPublish iterations=50000 duration_ns=9274811 ns_per_op=185 baseline_ns_per_op=n/a
- 2026-01-17T17:56:52.847947625Z WorldTickCoordinator.dispatch iterations=10000 duration_ns=456354165 ns_per_op=45635 baseline_ns_per_op=n/a
- 2026-01-17T17:56:54.594379482Z WorldTickCoordinator.init iterations=1000000 duration_ns=23171822 ns_per_op=23 baseline_ns_per_op=n/a
- 2026-01-17T17:56:56.284130169Z BaselineLoop iterations=1000000 duration_ns=2752918 ns_per_op=2 baseline_ns_per_op=2

## Bench harness (bots + villagers + hostiles)
- Run config: 4 cells, 4 bots, seed 424242, warmup 2400 ticks, sample 6000 ticks, phase 2400 ticks.
- Stress tuning: 50 villagers + 50 hostiles per cell, job site rotation 20 ticks, hostile retarget 20 ticks, entity maintenance 100 ticks.
- Overall avgMspt: 46.40 vs baseline 50.61 (-8.31%), p95Mspt: 61.53 vs 70.50 (-12.71%).
- Day avgMspt: 48.62 vs 53.02 (-8.30%), night avgMspt: 44.86 vs 48.94 (-8.32%).
- Report file: `docs/pewpew/findings/perf-bench-report.md`.
