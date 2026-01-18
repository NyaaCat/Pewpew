# Implementation Notes (Reset)

These notes track significant changes and their patch export status.

- Patch authoring happens in `tmp/` against a fresh, patched Paper source; commit there and export patches via `git format-patch`.
- Copy the exported patch files into `pewpew-server/paper-patches` and `pewpew-server/minecraft-patches`.
- Pewpew patches apply after Paper patches (`./gradlew :pewpew-server:applyAllServerPatches`).
- Rebuild the full patch series only when intentionally refreshing (`./gradlew rebuildAllServerPatches`).

## Rebrand to Pewpew
- Default brand id/name now resolves to Pewpew via build info and manifest attributes.
- Generated patch: `pewpew-server/paper-patches/features/0001-Rebrand-to-Pewpew.patch`.

## WorldTickCoordinator scaffold
- Added `io.papermc.paper.pewpew.WorldTickCoordinator` (feature flag `pewpew.worldTickCoordinator`, no-op init).
- Wired `PaperBootstrap` to call `WorldTickCoordinator.get().init()` at startup.
- Added correctness tests (`WorldTickCoordinatorTest`) and perf report test (`WorldTickCoordinatorPerfTest`).
- Generated patch: `pewpew-server/paper-patches/features/0002-Add-WorldTickCoordinator-scaffold.patch`.

## A/B perf harness + instrumentation
- Added A/B perf utility (`PerfReport`) with baseline compare and report writing.
- Expanded coordinator instrumentation (per-world timing, queue depth, stall tracking) and snapshot API.
- Added correctness tests for metrics (`WorldTickCoordinatorMetricsTest`).
- Generated patch: `pewpew-server/paper-patches/features/0003-Add-perf-harness-and-coordinator-metrics.patch`.

## Perf test tagging + baseline loop
- Tagged correctness tests with `@Normal` so they run in the default suites.
- Tagged perf tests with `PewpewPerf`, and marked `WorldTickCoordinatorPerfTest` as `PewpewOnly`.
- Added `BaselineLoopPerfTest` and a report file override property.
- Added perf Gradle tasks in `pewpew-server/build.gradle.kts` (baseline/compare/AB).
- Generated patch: `pewpew-server/paper-patches/features/0004-Add-perf-test-tagging-and-baseline-loop.patch`.

## TickThread pool + barrier (feature-flagged)
- Added a fixed-size tick thread pool with configurable worker count.
- Added `dispatchWorldTicks` API with a barrier and failure propagation.
- Ensured workers are `TickThread` instances and bind a per-world context for isolation checks.
- Added `shutdownForTesting` and tests for off-thread vs inline execution.
- Generated patch: `pewpew-server/paper-patches/features/0005-Add-tick-thread-pool-and-barrier.patch`.

## World load/unload gating
- Track the active barrier and allow the main thread to wait for in-flight ticks.
- Gate world create/unload with `WorldTickCoordinator.awaitIdle()`.
- Invalidate world generation + clear snapshots/commits on unload to drop stale async work.
- Updated thread pool tests to exercise `awaitIdle`.
- Generated patch: `pewpew-server/paper-patches/features/0006-Gate-world-load-unload-on-tick-barrier.patch`.

## NMS tick dispatch integration
- Enabled NMS patching in the fork configuration.
- Added `WorldTickCoordinator` dispatch in `MinecraftServer.tickChildren` (feature-flagged), publish snapshots, and drain commit queues in world order.
- Added correctness/perf tests for dispatch metrics and overhead.
- Generated Minecraft patch: `pewpew-server/minecraft-patches/features/0001-Parallelize-world-tick-dispatch-via-coordinator.patch`.
- Generated server test patch: `pewpew-server/paper-patches/features/0007-Parallelize-world-tick-dispatch-via-coordinator.patch`.

## SnapshotManager + CommitQueue scaffold
- Added `SnapshotManager` and `CommitQueue` scaffolding for snapshot/commit phases.
- Added correctness tests and perf smoke checks for the new scaffolding.
- Integrated snapshots with generation ids; commit queues are per-world and drop stale generations.
- Generated patch: `pewpew-server/paper-patches/features/0008-Add-snapshot-manager-and-commit-queue-scaffolding.patch`.

## Async pathfinding + async sensors (work-in-progress export)
- Added snapshot-backed pathfinding classes:
  - `pewpew-server/minecraft-patches/sources/net/minecraft/world/entity/ai/behavior/AsyncAcquirePoi.java.patch`
  - `pewpew-server/minecraft-patches/sources/net/minecraft/world/level/pathfinder/MobPathSnapshot.java.patch`
  - `pewpew-server/minecraft-patches/sources/net/minecraft/world/level/pathfinder/SnapshotNodeEvaluator.java.patch`
  - `pewpew-server/minecraft-patches/sources/net/minecraft/world/level/pathfinder/SnapshotPathFinder.java.patch`
  - `pewpew-server/minecraft-patches/sources/net/minecraft/world/level/pathfinder/SnapshotPathNavigationRegion.java.patch`
  - `pewpew-server/minecraft-patches/sources/net/minecraft/world/level/pathfinder/SnapshotWalkNodeEvaluator.java.patch`
- Added async sensor precompute service and async pool:
  - `pewpew-server/paper-patches/files/src/main/java/io/papermc/paper/pewpew/AsyncSensorService.java.patch`
  - `pewpew-server/paper-patches/files/src/main/java/io/papermc/paper/pewpew/PewpewAsyncPool.java.patch`
- Added correctness tests for snapshots/sensors:
  - `pewpew-server/paper-patches/files/src/test/java/io/papermc/paper/pewpew/AsyncSensorServiceTest.java.patch`
  - `pewpew-server/paper-patches/files/src/test/java/io/papermc/paper/pewpew/SnapshotPathNavigationRegionTest.java.patch`
  - `pewpew-server/paper-patches/files/src/test/java/io/papermc/paper/pewpew/LevelChunkSectionVersionTest.java.patch`
- Pending export: modifications to existing classes (AcquirePoi, PathNavigation, sensors, LevelChunkSection, PathfindingContext, WorldTickCoordinator, CraftServer, CommitQueue, SnapshotManager, etc.) are still only in the nested git working trees and need to be exported into feature patches.

## SparklyPaper parallel-world safeguards (ported)
- TickThread: richer diagnostics, per-world thread checks, hard-throw toggle (`-Dpewpew.disableHardThrow`), and helper methods.
- CraftBukkit thread locals: `SaplingBlock.treeTypeRT`, `CraftEventFactory.sourceBlockOverrideRT`, and `CraftBlockEntityState.DISABLE_SNAPSHOT`.
- Chunk system: ticket updates/unloads now require `isTickThreadFor(world)`; mid-tick tasks deferred when parallel ticking is enabled.
- NMS safety checks: `ServerLevel.addPlayer/addEntity`, `EntityTickList`, `ServerWaypointManager`, `LevelChunk.setBlockState`, `Level.getBlockEntity/setBlockEntity`, `Level.getEntities`.
- Cross-world edge cases: inventory open gating after teleports; BaseContainerBlockEntity rejects cross-world opens; non-player portals disabled under parallel ticking.
- Redstone: per-world `RedstoneWireTurbo` to avoid shared mutable state.
- Map index: `MapIndex#getNextMapId` synchronized to avoid duplicates.
