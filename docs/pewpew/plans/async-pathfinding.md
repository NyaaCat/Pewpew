# Async Pathfinding Plan (Draft)

## Goals
- Offload PathFinder computation to worker threads while preserving vanilla behavior.
- Ensure deterministic results by validating snapshot versions at commit time.
- Avoid chunk loads or world writes off-thread.
- Start with a narrow scope (villager AcquirePoi) before expanding.

## Snapshot model
### RegionSnapshot
- Built on the main thread per path request.
- Captures loaded chunks in a rectangular region around mob and targets.
- Stores per-section version numbers and references or copies of block state data.

### Snapshot contents (minimum)
- BlockState + FluidState per section (prefer immutable packed data, not live PalettedContainer).
- Heightmap data required by pathfinding (if accessed in evaluators).
- POI data only if a path request depends on POI (AcquirePoi); otherwise optional.
- Entity positions for target entity or target blocks.

## Validation scheme
- Maintain version counters:
  - ChunkSection block state version (increment on any block change).
  - POI section version (increment on POI add/remove/occupancy change).
  - Entity position/version (increment on move/teleport or remove).
- Snapshot records versions for all sections and targets used by the path.
- Commit checks:
  - Mob still alive, same dimension, same pathfinding flags.
  - Target position or target entity version unchanged.
  - All recorded chunk/POI versions unchanged.
- If any check fails: discard result and recompute synchronously on main thread.

## Async task flow
1) Main thread builds RegionSnapshot and PathTask request.
2) Worker thread runs PathFinder with a snapshot-backed BlockGetter.
3) Main thread applies result only if validation passes.
4) If task misses deadline (same tick) or validation fails, fallback to sync.

## Integration points
- PathNavigation.createPath -> AsyncPathService (gate by config).
- AsyncPathService maintains a fixed worker pool and bounded task queue.
- PathFinder instances are per-task (no shared state).

## Required adaptations
- Replace PathfindingContext to use a per-task PathTypeCache (never shared).
- Introduce a snapshot-backed PathNavigationRegion (no chunk loads).
- Capture Mob snapshot (position, bounding box, flags, follow range, malus).
- Call mob.onPathfindingStart/Done on main thread only (before schedule/after commit).
- Do not access ServerChunkCache.getChunkNow or ServerLevel.getPathTypeCache off-thread.

## Fallback behavior
- If snapshot is incomplete (missing chunks) -> sync path or null.
- If validation fails -> sync path in the same tick if possible.
- If worker deadline missed -> sync path or defer (configurable).
