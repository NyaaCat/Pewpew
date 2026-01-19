# Pewpew Progress Summary

## Completed work
- Restored clean patch-rebuild state by aborting stray `git am` sessions in `paper-server` and `pewpew-server/src/minecraft/java`.
- Regenerated Pewpew patch series from patched sources and fixed patch numbering/renames.
- Added commit-queue support to `WorldTickCoordinator` and synchronized `MapIndex#getNextMapId`.
- Restored CraftBukkit thread-local safety: sapling tree type, source block override, and block-entity snapshot disable; updated Sculk catalyst and CraftBlock usages.
- Re-applied patches and verified `./gradlew build` succeeds after test fixes.
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
- Ran multiworld A/B tests (all-on, all-off, path-only, sensors-only) using baseline summary reuse; async pathfinding is the main regression (+24% mspt, -15% TPS vs baseline), async sensors adds a small hit (~+2% mspt).
- Added async-profiler fetch script and bench harness hooks (profiling gated by env vars); defaults now target async-profiler 4.2.1 with text output (mapped to flat), versioned install directory, and format-aware file extension. Harness now resolves the server JVM PID via run directory before profiling and routes profiler stdout/stderr to a per-run log.
- Async pathfinding/sensors optimizations:
  - AsyncAcquirePoi now skips duplicate pending requests, checks async queue capacity before snapshot work, builds target sets without streams, and reuses a thread-local SnapshotPathFinder/evaluator.
  - AsyncSensorService now snapshots distances once and sorts snapshots directly to reduce allocations.
  - Added `settings.async-pathfinding-max-pending` in `pewpew.yml` (maps to `pewpew.asyncPathfinding.maxPending`).
- Profiling:
  - Captured itimer and cpu profiles (cpu used `--all-user`) at `docs/pewpew/findings/profiles/profile-cpu-pewpew-cpu.txt` plus earlier itimer outputs.
- A/B results after optimizations (ab2):
  - all-on: avgMSPT 76.89 (+15.0%), avgTPS 13.09 (-10.3%)
  - path-only: avgMSPT 74.78 (+11.8%), avgTPS 13.42 (-8.1%)
  - sensors-only: avgMSPT 66.45 (-0.6%), avgTPS 14.72 (+0.8%)
  - optional test: async workers=2 worsened regression (avgMSPT 80.68, -13.1% TPS).
- Attempted PathTypeCache size/reuse tuning (ab3) regressed; changes were reverted.
- Synced patch files for async changes and config wiring:
  - Regenerated `AsyncSensorService` and `AsyncAcquirePoi` file patches from current sources.
  - Added `PewpewConfig` file patch and feature patch to init it in `PaperBootstrap` and `CraftServer`.
- Undid accidental full patch rebuild; removed regenerated patch series and kept only intended changes.
- Adopted SparklyPaper 1.21.8 → 1.21.11 perf patches:
  - Block entity ticker removal optimization (`BlockEntityTickersList` + Level removal path).
  - Skip `ServerEntity` delta check when movement unchanged.
  - Per-world MSPT tracking and `/mspt` world breakdown.
- Committed each patch file separately and moved branch to `version/1.21.8`.
- Updated root `README.md` with the minimal patch workflow and the safe-to-ignore `logo.png` warning.
- Bench harness now can capture `jcmd` system properties and thread snapshots (Pewpew async/tick threads) via `BENCH_THREAD_SNAPSHOT=1`.
- Normalized SparklyPaper-derived patch files (block entity tickers, ServerEntity delta, per-world MSPT) and removed obsolete patch-context fix.
- Fixed Pewpew config + MSPT command patch headers; `:pewpew-server:applyAllServerPatches` now succeeds.
- Updated patch workflow docs to use tmp-based patched sources and to apply Pewpew patches after Paper patches.
- Verified per-world ticking is gated by `pewpew.yml` feature flags (defaults disabled in bench harness) and is enabled via `PewpewConfig` system properties at startup.
- World tick workers now use `TickThread` to satisfy tick-thread checks when per-world ticking is enabled.
- Reviewed async AI flow: `AsyncAcquirePoi` snapshots chunk sections per request (`SnapshotPathNavigationRegion.capture` copies `LevelChunkSection.states`), so snapshot churn is likely the regression; full entity tick off-thread is impractical without major world-write isolation.
- Added a per-tick section cache for async pathing snapshots and wired `AsyncAcquirePoi` to reuse cached section copies per world tick.
- Made `RedstoneWireTurbo` thread-local to avoid cross-world concurrency when per-world ticking is enabled.
- Started reviewing SparklyPaper 1.21.8→1.21.11 patch diffs; changes so far appear to be API event additions and safety checks (no new perf candidates identified yet).
- Re-ran singleworld bench with async pathfinding on + sensors off (cache enabled): avgMSPT 49.59 vs baseline 49.02 (+1.18%); regression reduced from prior +11.8%.
- Multiworld run with world tick coordinator enabled crashed in chunk system (`LevelTicks.addContainer` AIOOB in fastutil); crash report saved at `tmp/bench/runs/multiverse-worldtick-on-3-multiworld/pewpew/crash-reports/crash-2026-01-18_18.52.42-server.txt`.
- Reworked async pathfinding to a general PathNavigation-level async service:
  - Added `AsyncPath`/`AsyncPathService` (snapshot-based) and wired PathNavigation to schedule async pathing.
  - Added pending-path handling in AI behaviors/sensors/goals to avoid treating async results as unreachable.
  - Removed AcquirePoi async hook and replaced with pending-aware path handling.
  - Added patch files `0012-Async-path-service-plumbing.patch` and `0013-Handle-async-path-pending.patch`; removed old `0012-Use-AsyncAcquirePoi-when-enabled.patch`.
- Investigated world tick coordinator CPU usage: bench logs show `world-tick-coordinator` enabled but workers set to `default`; if JVM reports 2 CPUs, default workers becomes 1 (availableProcessors - 1), resulting in single-core usage. Next step: confirm availableProcessors in test VM and set `settings.world-tick-coordinator-workers` (or `BENCH_PEWPEW_WORLD_TICK_WORKERS`) to >= number of active worlds.
- Updated `scripts/bench/run_multiverse_benchmark.sh` to auto-pick `world-tick-coordinator-workers` when enabled and unset, using min(nproc, world count) with a floor of 2 when >1 CPU.
- Reworked world-tick coordinator dispatch to pin each world to a stable worker thread with dynamic worker scaling and dedicated-world preferences; added `settings.world-tick-coordinator-dedicated-worlds` to `pewpew.yml` and a stability test.
- Bench harness now writes `world-tick-coordinator-dedicated-worlds` in `pewpew.yml` (configurable via `BENCH_PEWPEW_WORLD_TICK_DEDICATED_WORLDS`).
- Single-world bench harness now writes `world-tick-coordinator-dedicated-worlds` in `pewpew.yml`.

## Build / test status
- `./gradlew build` succeeds (warnings about deprecated APIs only).
- `./gradlew :pewpew-server:applyAllServerPatches` succeeds after patch regeneration.

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
1) Re-run per-world ticking A/B benchmarks (baseline vs world-tick-coordinator enabled) and capture logs showing feature flags + tick thread usage.
2) Measure async pathfinding regression again to validate PathNavigation-level async pathing + pending handling; iterate if regression persists.
3) Investigate remaining redstone anomalies under parallel ticking (identify suspect patches; confirm tick-thread invariants).
4) Finish SparklyPaper 1.21.8→1.21.11 diff review to confirm whether any additional perf patches are worth porting.
5) Decide how to handle cleanup of `tmp/cleanup/paper-1.21.8` (deletion blocked by policy).
