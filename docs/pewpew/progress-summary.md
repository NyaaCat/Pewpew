# Pewpew Progress Summary

## Completed work
- Rescanned `docs/pewpew` docs + SparklyPaper notes and integrated findings into plans and risks.
- Ported SparklyPaper parallel-world safety changes and fixes:
  - Per-world `TickThread` checks with richer diagnostics and hard-throw toggle.
  - ThreadLocal state for tree type, block-spread source override, and snapshot disable.
  - Per-world `RedstoneWireTurbo`.
  - Mid-tick chunk-system tasks gated when parallel ticking is enabled.
  - Cross-world inventory open guard + BaseContainerBlockEntity cross-world open rejection.
  - Non-player portal travel disabled under parallel ticking.
  - `MapIndex#getNextMapId` synchronized.
  - Chunk ticket updates/unloads now use `isTickThreadFor(world)`.
  - Sculk catalyst source override restored using threadlocal set/remove.
- Added tests:
  - `MapIndexConcurrencyTest` for unique IDs under concurrency.
  - `ThreadLocalIsolationTest` for tree type, block spread source override, and snapshot flags.
- Bench harness updates:
  - Default 10 bots and 10 cells (1 per bot), 20-tick job rotation/retarget, 100-tick maintenance.
  - Run duration now uses `BENCH_EXPECTED_TPS` (default 12) to avoid early stop under heavy load.
  - Bench plugin now writes summary on disable to avoid missing report when TPS is low.
- Docs updated:
  - `docs/pewpew/plans/architecture.md`, `docs/pewpew/plans/risks.md`, `docs/pewpew/plans/invariants.md`, `docs/pewpew/plans/plugin-impact.md`, `docs/pewpew/plans/testing.md`.
  - `docs/pewpew/findings/implementation-notes.md`, `docs/pewpew/GUIDELINES.md`, `docs/pewpew/README.md`.
  - Marked TASKS export step as done in `docs/pewpew/TASKS.md`.
- Patch export:
  - Ran `./gradlew rebuildAllServerPatches`.
  - Feature patches saved for server and minecraft.
  - Note: `rebuildPaperServerFilePatches` reported failure reading `src/main/resources/logo.png`.
- Repo/doc hygiene:
  - Moved planning and findings docs to `docs/pewpew` and `docs/PLAN.md`.
  - Added root `README.md` with build, patch, and benchmark guidance.
  - Updated perf report output paths to `docs/pewpew/findings`.
- Bench plugin reorg:
  - Extracted `bench-plugin` into `/home/phoenix/works/pewpew-bench-plugin` (standalone git repo).
  - Updated bench harness to build the external plugin and use per-run temp dirs with cleanup.
- Datapack review:
  - Cloned `NyaaWorks` and `NyaaEnchants` into `tmp/` and documented compatibility notes.
- Bench plugin updates:
  - Switched chunk pre-generation to a queued, one-chunk-per-tick worker before setup/start to avoid main-thread batch generation.
  - Multiworld setup now waits for queued chunk generation before declaring ready.
  - Village placement now pre-generates chunks per village before placement and starts benchmarking only after villages are placed.
  - Added chunk pregen logging controls and village preload radius config.
  - Multiworld marker now written after villages are placed and initial villagers are spawned; bots wait until then.
  - Sampling uses ticks since bench start; summary only writes after completion.
  - Bench stats log every ~5 seconds with mspt/villagers/hostiles.
  - Added a simple README and committed the bench plugin repo.
- Bench harness updates:
  - Multiworld benchmark script now runs baseline (Paper) first, then Pewpew, each in a fresh run directory.
  - Multiworld benchmark script now emits chunk pregen logs by default and exposes village/chunk pregen env overrides.
  - Bot run duration now accounts for village pregen + delay before bench start.
- Reviewed baseline log (`tmp/bench/runs/20260118-073831-196782-multiworld/baseline/server.log`) showing "That position is not loaded" during `place structure` in `PewpewBenchPlugin.placeVillage`.
- Latest multiworld logs (`tmp/bench/runs/20260118-075138-214039-multiworld`) no longer show "That position is not loaded".
- Bench plugin multiworld flow updated to wait for players before placing villages, force-load village chunks during placement, add post-village spawn delay, and spawn hostiles per player; multiworld config + docs updated to match.
- Bench plugin updated to remove chunk pregen, distribute players with 1s teleport spacing, place villages at player locations after distribution, then spawn villagers/hostiles post-delay; multiworld harness now uses teleport-delay config and shorter 5-minute sample defaults.
- Re-ran multiworld baseline + Pewpew benchmarks with player distribution flow (2700 sample ticks, expected TPS 15); summaries updated in `docs/pewpew/findings/` and run directories cleaned.
- Added damage cancellation for invulnerable villagers/players in bench plugin; re-ran multiworld benchmark and updated summaries (villager death logs no longer appear).

## Build / test status
- `./gradlew :pewpew-server:test` succeeded (warnings only).
- `./gradlew build` initially failed because `junit-platform-launcher` had no version; fixed by pinning `1.12.2` in root `build.gradle.kts`, then build succeeded.

## Bench / perf status
- `scripts/bench/run_benchmark.sh` succeeded and generated:
  - `docs/pewpew/findings/bench-baseline.json`
  - `docs/pewpew/findings/bench-compare.json`
  - `docs/pewpew/findings/perf-bench-report.md`
- Multiworld A/B run completed (logs under `tmp/bench/runs/20260118-075138-214039-multiworld`) and reports written:
  - `docs/pewpew/findings/multiverse-bench-summary-baseline.json`
  - `docs/pewpew/findings/multiverse-bench-report-baseline.md`
  - `docs/pewpew/findings/multiverse-bench-summary.json`
  - `docs/pewpew/findings/multiverse-bench-report.md`

## Planned next steps
1) Update perf summaries in `docs/pewpew/findings/perf-report.md` with new results if needed.
2) Investigate the `logo.png` file patch error from `rebuildPaperServerFilePatches` and decide if a patch update is required.
3) Re-run the multiworld benchmark if new parameters are needed.
