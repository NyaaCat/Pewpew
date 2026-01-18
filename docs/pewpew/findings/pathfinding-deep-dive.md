# Pathfinding Deep Dive (1.21.8)

Note: the details below were captured on 1.21.11 and must be re-validated against 1.21.8 sources before implementation.

## Call chain (main thread)
- net/minecraft/world/entity/ai/behavior/AcquirePoi.findPathToPois
- net/minecraft/world/entity/ai/navigation/PathNavigation.createPath
  - constructs PathNavigationRegion around mob
- net/minecraft/world/level/pathfinder/PathFinder.findPath
  - uses NodeEvaluator (Walk/Flying/Water)
- net/minecraft/world/level/pathfinder/NodeEvaluator -> PathfindingContext
- net/minecraft/world/level/pathfinder/WalkNodeEvaluator
  - PathTypeCache, collision checks, block/fluids

## Key components and state
- PathNavigation
  - owns a PathFinder instance per mob (not thread-safe for concurrent use).
  - uses mob attributes and state (FOLLOW_RANGE, bounding box, flags).
- PathFinder
  - uses mutable BinaryHeap and Node[] neighbor buffer.
- NodeEvaluator / WalkNodeEvaluator
  - mutable caches: nodes map, pathTypesByPosCacheByMob, collisionCache.
  - reads block states, fluids, collision shapes.
- PathNavigationRegion
  - captures chunk array from Level.getChunkNow (may load or return empty).
  - exposes getBlockState / getFluidState from live chunks.
- PathfindingContext
  - uses ServerLevel.getPathTypeCache (shared, not thread-safe).

## Thread-safety hazards for async
- PathNavigationRegion uses live chunks and getChunkNow (non-thread-safe).
- PathTypeCache is a shared mutable cache (not thread-safe).
- NodeEvaluator uses live Mob (position, bounding box, flags) and calls mob.onPathfindingStart/Done.
- WalkNodeEvaluator uses mutable caches and collision checks.

## Implications
- Async pathfinding requires a read-only snapshot of chunk data and a per-task cache.
- Mob state used by pathfinding must be captured up front (snapshot) and validated before commit.
- Any path result must be validated against chunk/section versions and entity position.
