# Baseline Tests (1.21.8)

## Current test harness
- `pewpew-server` uses `paper-server` test sources.
- `tasks.test` includes `**/**TestSuite.class`, excludes tag `Slow`, and runs headless.
- Correctness baseline command: `./gradlew :pewpew-server:test`
  - Reported run: BUILD SUCCESSFUL (config cache stored, tasks up-to-date).
- Perf A/B command: `./gradlew :pewpew-server:pewpewPerfAB`

## Performance baseline
- Added perf harness with tagged tests.
- `BaselineLoopPerfTest` (`PewpewPerf`) provides a stable baseline sample.
- `WorldTickCoordinatorPerfTest` is `PewpewOnly` and does not require a baseline entry.
- `WorldTickCoordinatorDispatchPerfTest` is `PewpewOnly` and reports dispatch overhead.
- `SnapshotManagerPerfTest` and `CommitQueuePerfTest` are `PewpewOnly` and report scaffolding overhead.
- A/B baselines must compare vanilla Paper vs Pewpew on the same machine and config.
- The latest test run succeeded, but the local machine is low power; do not use it as a reference baseline.

## A/B perf baseline workflow
- Run baseline on a vanilla Paper checkout that includes the perf harness tests.
- `./gradlew :pewpew-server:pewpewPerfBaseline -Dpewpew.perf.mode=baseline`
- `./gradlew :pewpew-server:pewpewPerfCompare` (default mode compares against baseline)
- Set `-Dpewpew.perf.baselineFile` and `-Dpewpew.perf.reportFile` to share files across repos.
- Use the same hardware, JVM, and configs for both runs.

## Attempts
- `./gradlew :pewpew-server:test` failed: Gradle wrapper lock under `/home/phoenix/.gradle` is not writable.
- Re-run with `GRADLE_USER_HOME=/home/phoenix/Code/Java/pewpew/.gradle-user` failed: network socket operation not permitted while downloading Gradle 9.3.
- User-run `./gradlew :pewpew-server:test` succeeded later (config cache stored, tasks up-to-date).
