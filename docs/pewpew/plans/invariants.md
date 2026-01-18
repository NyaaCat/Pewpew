# Invariants and Safety Rules

## World and entity
- Single-writer per world: world mutations occur on the owning world `TickThread` during the parallel phase.
- Main thread does not touch world state while world tick threads are running.
- Preserve per-entity tick order within each world.
- World tick threads must be `TickThread` instances (pass TickThread checks).

## Chunk and block data
- Off-thread reads (non-world tick) must use snapshots or validated views.
- No off-thread chunk loads or ticket changes outside the owning world tick thread.
- Snapshot validation uses section/entity/POI versions.

## Commit and plugin API
- Bukkit events and plugin hooks execute on main thread via commit queues.
- No plugin API calls on worker threads unless explicitly documented as safe.
- Commit queues must preserve world iteration order and per-entity order.
- Datapack functions and plugin-driven spawns/mutations execute on the main thread; async work must queue a commit with the target world.

## World lifecycle and datapacks
- World load/unload occurs only at a barrier point (no world ticks in flight).
- Each world has a stable owner thread or a safe handoff protocol.
- Use a per-world generation id to discard stale async work after unload/reload.
- Datapack functions and triggers run on the main thread before world ticks.
- Inventory open requests immediately after cross-world teleport are ignored until the player has ticked once in the new world.
- Non-player portal travel is disabled while parallel world ticking is enabled.
- Chunk ticket updates/unloads run only on the owning world tick thread.

## Thread pool rules
- Threads are fixed and long-lived; no per-tick creation/destruction.
- Backpressure defers work to the next tick instead of synchronous fallback.

## Thread-local state
- `SaplingBlock.treeTypeRT`, `CraftEventFactory.sourceBlockOverrideRT`, and `CraftBlockEntityState.DISABLE_SNAPSHOT` must be cleared after use.
