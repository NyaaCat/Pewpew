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
- Upstream tracking: each version branch pins `paperRef` in `gradle.properties` to a specific Paper `main` commit.
- Before any `apply*Patches` task, clear generated outputs to avoid stale patch contexts:
  - `rm -rf paper-api paper-server pewpew-server/src/minecraft`
  - `rm -rf pewpew-server/minecraft-patches/resources`
- Stable approach (work in this repo using paperweight, like Paper/SparklyPaper):
  1) Clear generated directories first (commands above).
  2) Run `./gradlew applyAllPatches` (or `./gradlew applyPaperApiPatches` + `./gradlew :pewpew-server:applyAllServerPatches`) to regenerate `paper-api/` and `paper-server/`.
  3) Make changes in `paper-api/` or `paper-server/` (Minecraft changes live under `paper-server/src/minecraft`).
  4) Regenerate patches via the paperweight tasks (fixup or rebuild); do not hand-edit patch files.
  5) Verify with one of the build profiles below.
- Recommended verification profiles:
  - Fast patch/apply check: `./gradlew applyAllPatches && ./gradlew :pewpew-server:compileJava`
  - Full build check (CI parity): `./gradlew applyAllPatches && ./gradlew build`
  - Do not combine `applyAllPatches` and `build` in a single Gradle invocation; order is not guaranteed in one task graph.
- Pewpew patches must apply after all Paper patches (`./gradlew :pewpew-server:applyAllServerPatches`).
- New files become file patches (`pewpew-server/paper-patches/files` or `pewpew-server/minecraft-patches/sources`).
- `rebuildPaperServerFilePatches` may log a missing `src/main/resources/logo.png`; it is safe to ignore.

## Build
- Fast server compile: `./gradlew :pewpew-server:compileJava`
- Full project build: `./gradlew build`
- `./gradlew :pewpew-server:runDevServer`
- Production jar (mojmap paperclip): `./gradlew :pewpew-server:createMojmapPaperclipJar`
  - Output: `pewpew-server/build/libs/pewpew-paperclip-*-mojmap.jar`

## Benchmarking
- The bench plugin lives in `NyaaCat/PewpewBench` (standalone repo).
- Build it there with `./gradlew jar` (publish `paper-api` to Maven local first if needed).
- Run the harness with `bash scripts/bench/run_benchmark.sh`.
- Reports are written to `docs/pewpew/findings/` and run directories are cleaned after completion.

## Threading policy (compatibility)
- Plugins and datapacks execute on the main thread by default.
- Any async compute must be snapshot-backed and committed on the main thread in world order.

## Thanks
Special thanks to Paper and SparklyPaper for the baseline work and inspiration behind this fork.
