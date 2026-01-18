# Task 4: AsyncPathService (AcquirePoi) - Design Notes

## Constraints
- Pathfinding must not read live chunks or shared caches off-thread.
- NodeEvaluator/PathFinder are not thread-safe; do not share instances.
- Mob state cannot be read off-thread without a snapshot or strict locking.
- AcquirePoi must preserve vanilla behavior; fallback to sync if async not safe/ready.

## Safe async approach (recommended)
1) Main thread:
   - Build `RegionSnapshot` for the path region.
   - Capture `MobPathSnapshot` (position, bbox dims, step height, pathfinding malus map, flags).
   - Collect POI targets on main thread (existing code path).
   - Record section + POI versions and entity position version for validation.
2) Worker thread:
   - Use a snapshot-backed navigation region (no live chunk reads).
   - Use per-task PathTypeCache; no shared caches.
   - Run pathfinding with a snapshot-aware NodeEvaluator (no live Mob reads).
3) Main thread commit:
   - Validate versions + entity position version.
   - If stale or late, recompute synchronously.

## Open implementation choice
- Option A: Create snapshot-aware `WalkNodeEvaluator` that uses `MobPathSnapshot` instead of `Mob`.
- Option B: Patch `PathFinder`/`NodeEvaluator` to accept a new `PathfindingContextSnapshot`.

## Next steps
- Decide between Option A or B.
- Implement snapshot evaluator and snapshot-backed PathNavigationRegion.
- Wire into AcquirePoi with feature flag and per-entity pending result tracking.
