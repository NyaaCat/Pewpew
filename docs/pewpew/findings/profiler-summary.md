# Profiler Summary (v23 and v24)

Inputs:
- tmp/profiler-v23.txt
- tmp/profiler-v24.txt

Note: stacks include cat.nyaa.yasui hooks (BlockStateCache, PathfindingCache, PoiSearchCache). Yasui will not be used going forward; treat these entries as hints for where caching helped.

## v23 highlights
- Server thread ~50.98ms, dominated by entity ticking.
- Hot path: Zombie.tick -> Mob.aiStep -> GoalSelector.tick -> MeleeAttackGoal.canUse -> PathNavigation.createPath -> PathFinder -> WalkNodeEvaluator.getNeighbors/getPathType...
- Pathfinding hits PathNavigationRegion.getBlockStateIfLoaded, showing heavy block state reads.

## v24 highlights
- Server thread ~73.71ms, entity tick ~36.95ms.
- Villager.tick -> Brain.tick -> startEachNonRunningBehavior -> AcquirePoi -> PathNavigation.createPath -> PathFinder.
- WalkNodeEvaluator.getCachedPathType and PathTypeCache in the hot chain.
- Yasui caches appear in PathNavigationRegion.getBlockStateIfLoaded and POI searches.

## Hot targets to inspect in Paper sources
- net/minecraft/world/entity/ai/Brain.java (tick, startEachNonRunningBehavior, tickSensors)
- net/minecraft/world/entity/ai/behavior/AcquirePoi.java
- net/minecraft/world/entity/ai/navigation/PathNavigation.java
- net/minecraft/world/level/pathfinder/PathFinder.java
- net/minecraft/world/level/pathfinder/WalkNodeEvaluator.java
- net/minecraft/world/level/PathNavigationRegion.java
