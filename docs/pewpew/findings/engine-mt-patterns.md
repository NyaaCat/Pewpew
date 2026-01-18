# Engine Multi-Threading Patterns (Unreal and peers)

This is a condensed list of common patterns used by mature engines that we can adapt to Minecraft.

## Common patterns
- Single-writer main thread (game thread) with read-only worker tasks.
- Task graph / job system with explicit dependencies and short-lived tasks.
- Double-buffered or snapshot data for worker reads; main thread commits results.
- Command buffers for deferred writes (apply in deterministic order).
- Async pathfinding and navmesh queries with cancellation and version checks.
- AI evaluated as tasks (sensors, perception, scoring), with results applied on the game thread.
- Spatial partitioning (regions/tiles) to reduce contention and enable parallel work.
- Staged tick phases with barriers between read, compute, and write.

## Implications for Minecraft
- Preserve vanilla order by keeping the world as a single-writer system.
- Use snapshots or copy-on-write data for off-thread reads.
- Validate results against versioned world/entity state before commit.
- Keep Bukkit API main-thread by default; provide explicit safe async read APIs.
