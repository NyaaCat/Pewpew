# Pewpew

Pewpew is a Paper fork focused on main-thread performance and safe, deterministic parallelism.
It aims for per-world tick parallelism and snapshot-backed async AI/sensor/pathfinding work where safe.
The default behavior stays vanilla-compatible: plugins and datapacks run on the main thread, and
any behavior-changing optimizations are opt-in and documented.

## Documentation
- Project notes, plans, and findings live in `docs/pewpew/`.
- The current roadmap and invariants are in `docs/pewpew/plans/`.

## Patch workflow
- Make code changes in `paper-server/` (CraftBukkit/Paper) and `pewpew-server/src/minecraft/java` (NMS).
- Do not edit `pewpew-server/paper-patches` or `pewpew-server/minecraft-patches` directly.
- Export patches with `./gradlew rebuildAllServerPatches`.

## Build
- `./gradlew build`
- `./gradlew :pewpew-server:runDevServer`

## Benchmarking
- The bench plugin lives in `NyaaCat/pewpew-bench-plugin` (standalone repo).
- Build it there with `./gradlew jar` (publish `pewpew-api` to Maven local first if needed).
- Run the harness with `bash scripts/bench/run_benchmark.sh`.
- Reports are written to `docs/pewpew/findings/` and run directories are cleaned after completion.

## Threading policy (compatibility)
- Plugins and datapacks execute on the main thread by default.
- Any async compute must be snapshot-backed and committed on the main thread in world order.

## Thanks
Special thanks to Paper and SparklyPaper for the baseline work and inspiration behind this fork.
