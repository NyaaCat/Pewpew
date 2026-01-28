# Pewpew Bench Harness

This harness runs a vanilla Paper baseline against Pewpew using the same seed,
bot load, and bench plugin configuration.

Default scenario:
- 10 bots/players to keep chunks loaded.
- 10 cells by default (one per bot) unless `BENCH_CELLS` overrides it.
- 40 villagers + 40 hostiles per cell, with job sites rotating every 20 ticks.
- Day/night phases every 2400 ticks to exercise villager work + night mob AI.

Quick start:
- `bash scripts/bench/run_benchmark.sh`
- `bash scripts/bench/run_multiverse_benchmark.sh`

Environment overrides:
- `BENCH_BASELINE_REPO` (default: `/home/phoenix/works/pewpew-paper-baseline`)
- `BENCH_PLUGIN_REPO` (default: `/home/phoenix/works/pewpew-bench-plugin`)
- `BENCH_PLUGIN_API_COORDS` (override API coords for the bench plugin build)
- `BENCH_RUN_ID` (override the unique run directory name)
- `BENCH_KEEP_RUN_DIR=1` (keep the run directory for debugging)
- `BENCH_SKIP_PEWPEW_API_PUBLISH=1` (skip publishing `paper-api` to Maven local)
- `BENCH_SKIP_BASELINE=1` (skip baseline run if a baseline summary exists)
- `BENCH_BASELINE_SUMMARY` (path to an existing baseline summary when skipping baseline)
- `BENCH_NODE_BIN`, `BENCH_NPM_BIN` (override Node/npm binaries for mineflayer)
- `BENCH_DATAPACK_DIR` (install a datapack into each world for both runs)
- `BENCH_COMPARE_DATAPACK=1` (compare datapack off/on using Pewpew only)
- `BENCH_DATAPACK_ON_DIR`, `BENCH_DATAPACK_OFF_DIR` (per-run datapack dirs for compare mode)
- `BENCH_DATAPACK_FIX_ITEM_TAGS=1` (copy `tags/item` to `tags/items` after install)
- `BENCH_RELOAD_TIMEOUT`, `BENCH_RELOAD_SETTLE_SECONDS` (reload wait/settle timing)
- `BENCH_SEED`, `BENCH_CELLS`, `BENCH_BOT_COUNT`
- `BENCH_VILLAGERS_PER_CELL`, `BENCH_HOSTILES_PER_CELL`
- `BENCH_WARMUP_TICKS`, `BENCH_SAMPLE_TICKS`, `BENCH_PHASE_TICKS`
- `BENCH_SAMPLE_INTERVAL_TICKS`, `BENCH_JOB_ROTATE_TICKS`
- `BENCH_HOSTILE_RETARGET_TICKS`, `BENCH_ENTITY_MAINT_TICKS`
- `BENCH_EXPECTED_TPS` (controls run duration; defaults to 15)
- `BENCH_PEWPEW_JAVA_OPTS` (default: `-Dpewpew.asyncPathfinding=true -Dpewpew.asyncSensors=true`)
- `BENCH_PEWPEW_FEATURE_ASYNC_PATHFINDING` (default: `true`)
- `BENCH_PEWPEW_FEATURE_ASYNC_SENSORS` (default: `true`)
- `BENCH_PEWPEW_FEATURE_SPAWN_SNAPSHOT_CACHE` (default: `false`)
- `BENCH_PEWPEW_FEATURE_WORLD_TICK_COORDINATOR` (default: `false`)
- `BENCH_PEWPEW_FEATURE_WORLD_TICK_COORDINATOR_TESTING` (default: `false`)
- `BENCH_PEWPEW_FEATURE_ASYNC_POOL_TESTING` (default: `false`)
- `BENCH_PEWPEW_FEATURE_TICK_THREAD_HARD_THROW` (default: `true`)
- `BENCH_PEWPEW_ASYNC_POOL_WORKERS` (default: `-1` for default)
- `BENCH_PEWPEW_ASYNC_POOL_QUEUE_LIMIT` (default: `-1` for default)
- `BENCH_PEWPEW_ASYNC_PATH_MONSTER_SYNC_FALLBACK` (default: `true`)
- `BENCH_PEWPEW_WORLD_TICK_WORKERS` (default: `-1` for default)
- `BENCH_PEWPEW_WORLD_TICK_STALL_NANOS` (default: `50000000`)

Multiworld overrides (run_multiverse_benchmark.sh):
- `MULTIVERSE_JAR_URL` (defaults to Multiverse-Core 5.5.0)
- `BENCH_PLAYERS_PER_WORLD`, `BENCH_PLAYER_SPACING`
- `BENCH_VILLAGERS_PER_PLAYER`, `BENCH_HOSTILES_PER_PLAYER`
- `BENCH_VILLAGER_SPAWN_RADIUS`, `BENCH_HOSTILE_SPAWN_RADIUS`
- `BENCH_VILLAGER_SYNC_RADIUS`
- `BENCH_VILLAGE_OFFSET`, `BENCH_EFFECT_AMPLIFIER`
- `BENCH_EFFECT_DURATION_TICKS`, `BENCH_EFFECT_REFRESH_TICKS` (defaults: 24000/20)
- `BENCH_VILLAGER_MAINT_TICKS`, `BENCH_VILLAGE_PLACE_DELAY_TICKS`
- `BENCH_POST_VILLAGE_DELAY_TICKS`
- `BENCH_TELEPORT_DELAY_TICKS`

Profiling (run_multiverse_benchmark.sh):
- `BENCH_PROFILE=1` (enable async-profiler)
- `BENCH_PROFILE_TARGET` (`pewpew`, `baseline`, or `both`)
- `BENCH_PROFILE_EVENT` (default: `cpu`)
- `BENCH_PROFILE_DURATION` (seconds; defaults to sample duration)
- `BENCH_PROFILE_FORMAT` (default: `text`, mapped to `flat` output)
- `BENCH_PROFILE_ARGS` (extra async-profiler CLI args, e.g. `--all-user -i 1000000`)
- `BENCH_PROFILE_LOG_PATTERN` (log line that marks bench start)
- `BENCH_PROFILE_OUTPUT_DIR` (default: `docs/pewpew/findings/profiles`)
- `ASYNC_PROFILER_DIR` (default: `tmp/async-profiler-$ASYNC_PROFILER_VERSION`)
- `ASYNC_PROFILER_VERSION` (default: `4.2.1`), `ASYNC_PROFILER_ARCH` (passed to fetch script)

Stress profile notes:
- Job-site rotation forces villager AcquirePoi churn (pathfinding hot path).
- Hostile retargeting keeps pathfinding + sensing active around players.
- If you want one player per cell (max spread), set `BENCH_CELLS=10` (and adjust per-cell mob counts if needed).

Outputs:
- `docs/pewpew/findings/bench-baseline.json`
- `docs/pewpew/findings/bench-compare.json`
- `docs/pewpew/findings/perf-bench-report.md`
- `docs/pewpew/findings/multiverse-bench-summary.json`
- `docs/pewpew/findings/multiverse-bench-report.md`
- `docs/pewpew/findings/multiverse-bench-summary-datapack-off.json`
- `docs/pewpew/findings/multiverse-bench-summary-datapack-on.json`
- `docs/pewpew/findings/multiverse-bench-report-datapack-off.md`
- `docs/pewpew/findings/multiverse-bench-report-datapack-on.md`
