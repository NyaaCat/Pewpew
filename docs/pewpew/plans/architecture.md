# Pewpew Multi-Threading Architecture (Draft)

## Goals
- Preserve vanilla behavior by default (order, outcomes, timings).
- Scale across cores using per-world parallelism while keeping tick order deterministic.
- Keep Bukkit API behavior stable; async work must not call Bukkit directly.

## Core design
- Main thread is a scheduler during tick: dispatches work and waits at a barrier.
- Each world has a dedicated tick worker (a `TickThread`) that owns world mutation during the parallel phase.
- Off-thread compute that is not the world tick uses snapshots; results are queued for main-thread commit.
- Tick completion is synchronous: no deadlines or fallbacks; tick may exceed 50ms.

## Worker model (fixed pool)
- Fixed-size pool of `TickThread` workers for world ticks; threads are long-lived.
- Optional shared compute pool for read-only jobs (pathfinding, sensors).
- Stable world-to-thread assignment to reduce migration and cache churn.
- Bounded queues for compute pool; backpressure defers work to the next tick instead of sync fallback.

## Commit and ordering
- World tick threads record side effects that must run on the main thread (events, plugin hooks).
- Main thread drains per-world commit queues after all world ticks complete.
- Ordering: preserve per-world entity order and commit in the same world iteration order as vanilla.

## Tick phases (high level)
1) PreTick (main thread): scheduler heartbeats, build/update snapshots, enqueue per-world tick tasks.
2) Parallel World Tick (TickThreads): run world tick or staged compute against snapshots; record commit actions.
3) Commit/PostTick (main thread): apply queued actions in order, refresh snapshots, tick connection/network.

## Reliability controls
- Barrier at end of the parallel phase; tick advances only when all world tasks finish.
- Invalid async results are discarded and retried next tick; no same-tick fallback.

## Proposed components
- WorldTickCoordinator: owns thread pool, barriers, and per-world task dispatch.
- WorldTickRunner: executes `ServerLevel.tick` or staged compute for a single world.
- SnapshotManager: builds per-world snapshots at tick start, refreshes after commit.
- CommitQueue: thread-safe queue of main-thread actions per world (events, plugin hooks).

## Non-goals
- No Folia-style regionized ticking; per-world ticks + targeted async is the baseline.

## Compatibility and safety
- World mutation happens only on the owning world `TickThread` during the parallel phase.
- Main thread does not touch world state while world ticks are running.
- Any off-thread read not on a world `TickThread` uses snapshots.

## Parallel-world safeguards (SparklyPaper-derived)
- `TickThread` uses a per-world context to validate `ensureTickThread` calls; wrong-world access logs rich diagnostics.
- Mid-tick chunk-system tasks are deferred to the end of the tick when parallel ticking is enabled.
- Per-world `RedstoneWireTurbo` instances avoid cross-world shared state during redstone updates.
- Global CraftBukkit toggles moved to `ThreadLocal` (tree type, block spread source, snapshot disable).
- Chunk ticket updates/unloads only run on the owning world tick thread (`isTickThreadFor(world)`).
