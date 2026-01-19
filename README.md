# Pewpew

Pewpew is a Paper fork focused on main-thread performance and safe, deterministic parallelism.
It aims for per-world tick parallelism and snapshot-backed async AI/sensor/pathfinding work where safe.
The default behavior stays vanilla-compatible: plugins and datapacks run on the main thread, and
any behavior-changing optimizations are opt-in and documented.

## Documentation
- Project notes, plans, and findings live in `docs/pewpew/`.
- The current roadmap and invariants are in `docs/pewpew/plans/`.

## Patch workflow
- Do not edit `pewpew-server/paper-patches` or `pewpew-server/minecraft-patches` directly.
- Work in `tmp/` with a fresh, patched Paper source:
  1) Clone upstream Paper at the target version and run `./gradlew applyPatches`.
  2) Apply Pewpew changes on top of the patched sources and commit locally.
  3) Generate patches via `git format-patch` (or equivalent).
  4) Copy the patch files into `pewpew-server/paper-patches` or `pewpew-server/minecraft-patches`.
- Pewpew patches must apply after all Paper patches (`./gradlew :pewpew-server:applyAllServerPatches`).
- Use the smallest rebuild task possible; only run `rebuildAllServerPatches` when intentionally refreshing the full series.
- New files become file patches (`pewpew-server/paper-patches/files` or `pewpew-server/minecraft-patches/sources`).
- `rebuildPaperServerFilePatches` may log a missing `src/main/resources/logo.png`; it is safe to ignore.

## Build
- `./gradlew build`
- `./gradlew :pewpew-server:runDevServer`
- Production jar (mojmap paperclip): `./gradlew :pewpew-server:createMojmapPaperclipJar`
  - Output: `pewpew-server/build/libs/pewpew-paperclip-*-mojmap.jar`

## Benchmarking
- The bench plugin lives in `NyaaCat/pewpew-bench-plugin` (standalone repo).
- Build it there with `./gradlew jar` (publish `paper-api` to Maven local first if needed).
- Run the harness with `bash scripts/bench/run_benchmark.sh`.
- Reports are written to `docs/pewpew/findings/` and run directories are cleaned after completion.

## Threading policy (compatibility)
- Plugins and datapacks execute on the main thread by default.
- Any async compute must be snapshot-backed and committed on the main thread in world order.

## Thanks
Special thanks to Paper and SparklyPaper for the baseline work and inspiration behind this fork.
