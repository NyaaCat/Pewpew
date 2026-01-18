# Tick Task Parallelism Analysis (1.21.8)

## Summary
The "ordered task distribution + batched commit" model only stays simple when tasks are pure compute.
Most vanilla tick work is read/write and order-sensitive, so preserving single-thread behavior requires
either sequential execution or heavy refactors (snapshots, staged state, deterministic commit queues).
That complexity is not lower than targeted parallelism.

## Practicality
Works well when:
- The task is read-only or can be expressed as compute + deterministic commit.
- Inputs can be captured as a snapshot with no mid-tick dependencies.
- Outputs are small and order-independent.

Struggles when:
- The task mutates world state that later tasks must observe in the same tick.
- The task calls plugins or dispatches events mid-tick.
- The task uses shared mutable caches (AI/pathfinding) or live chunk data.
- The task depends on RNG ordering or time-sensitive side effects.

## Reliability risks
- Read-after-write order: later tasks must see earlier writes; snapshotting hides this.
- RNG ordering: parallel execution changes random call order, altering behavior.
- Plugin expectations: Bukkit APIs are main-thread; off-thread execution breaks contracts.
- Global state: player list, scoreboard, scheduler, command functions are shared.
- Deadlocks and stalls: barriered ticks can block if any task hangs.
- Memory/GC pressure: snapshots and command buffers can be large per tick.

## What "batched commit" really implies
To keep vanilla semantics, you would need to:
- Capture read sets and write sets per task.
- Detect conflicts or serialize conflicting tasks in original order.
- Replay side effects (events, sounds, network) on the main thread in exact order.
This becomes a transactional system; it is not simpler than targeted parallelism.

## Better approaches (lower risk)
1) Per-world parallel ticks (coarse grain)
   - Tick each world on its own long-lived TickThread.
   - Main thread handles global work and runs a commit queue for plugin events.
   - Simpler than full task-level parallelism; scales with multiple worlds.

2) Targeted async compute (fine grain)
   - Use snapshots for pathfinding, sensors, and other read-heavy tasks.
   - Commit results on main thread next tick; no same-tick fallback.
   - Preserves semantics for most gameplay while reducing risk.

3) Region ownership model (advanced)
   - Not pursuing: Folia-style regionization is still incomplete and not drop-in compatible.
   - Keep per-world ticks + targeted async instead.

## Recommendation for Pewpew
Keep the model simple and reliable:
- Start with per-world TickThread parallelism behind a flag.
- Add snapshot-based async compute for pathfinding/sensors.
- Avoid fine-grained task parallelism until deterministic commit semantics are proven.

## Plugin compatibility (drop-in requirement)
- Bukkit/Paper APIs must remain main-thread; any plugin calls from world ticks must be routed to a main-thread commit queue.
- `Bukkit.isPrimaryThread` is tied to the main server thread; invoking plugins on worker threads will break expectations.
- Scheduler heartbeats, command dispatch, and plugin events must run in the same order as vanilla.

## Multi-world (dynamic load/unload)
- World creation/unload must happen at a safe barrier point (no world ticks in flight).
- Each world needs a stable owner thread or a safe handoff protocol.
- Use a per-world generation id so stale async tasks can be discarded after unload/reload.
- Commit queues must be flushed or canceled on unload to avoid stale side effects.

## Datapacks (functions and triggers)
- Function tick and triggers execute on the main thread before or after the parallel world tick phase.
- Functions can mutate world state; they must not overlap with world tick threads.
- Preserve the vanilla ordering: `commandFunctions` runs before level ticks.

## Snapshot performance tradeoffs
Potential gains:
- Offloads expensive read-heavy work from the main thread (pathfinding, sensors).
- Improves worst-case main-thread tick time under AI-heavy loads.

Potential costs:
- Snapshot creation is memory-bandwidth heavy; large regions can cost several MB per tick.
- Copying adds CPU and GC pressure; benefits depend on reuse and region size.
- Small workloads can regress (copy cost dominates compute cost).

Mitigations:
- Build snapshots only for tasks that are actually offloaded.
- Reuse snapshots across tasks within a tick; cache by (world, region, tick).
- Use section-level versioning to skip copying unchanged sections.
