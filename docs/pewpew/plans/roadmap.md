# Pewpew Roadmap (Draft)

## Phase 0: Preflight (no behavior change)
- Confirm fork/patch workflow (diff-from-`tmp/paper-1.21.8` only).
- Re-verify 1.21.8 tick order, world load/unload flow, and datapack function triggers.
- Record plugin callback points and main-thread boundaries.
- Establish baseline correctness and performance tests.

## Phase 1: Coordinator scaffolding (feature-flagged)
- Add WorldTickCoordinator with a no-op pass-through mode (flag off by default).
- Add per-world instrumentation (timings, queue depth, stall detection).
- Add integration tests: tick order unchanged, world isolation, no deadlocks.

## Phase 2: Per-world TickThread pool (opt-in)
- Implement fixed `TickThread` pool and barrier.
- Keep main thread isolated during the parallel phase.
- Enforce safe world load/unload at barrier points with generation-id invalidation.

## Phase 3: Snapshots + targeted async
- Implement SnapshotManager for read-only tasks.
- Add commit queues for main-thread plugin/event dispatch.
- Convert one safe subsystem to compute+commit (smallest surface area first).

## Phase 4: Expand async coverage
- Add async pathfinding (AcquirePoi only) and selected sensors using snapshots.
- Tighten perf regression thresholds and add scenario coverage.

## Phase 5: Hardening and polish
- Add debug/trace tooling, watchdogs, and safety kill switches.
- Document operational guidance and plugin compatibility notes.
