# Paper Optimization Plan (Main-Thread, Vanilla-Preserving)

## Goal
Create a Paper fork focused on **main-thread optimizations** that preserve vanilla behavior by default. Any behavior-changing optimizations must be opt-in and clearly documented.

## Repo Setup (1.21.11)
- Gradle wrapper: 9.3.0
- Java toolchain: 21
- paperweight userdev: 2.0.0-SNAPSHOT
- Dev bundle: 1.21.11-R0.1-SNAPSHOT
- Sources extracted:
  - `tmp/paper-sources/paper-server-1.21.11`
  - `tmp/paper-sources/vanilla-server-1.21.11`
- Build command: `./gradlew build`
- Extract command: `./scripts/extract-paper-sources.sh -v 1.21.11 -o tmp/paper-sources`

## Near-Term Patching Plan (Repo-Specific)
- Build a short candidate list of hot loops by scanning the extracted Paper sources:
  - `tmp/paper-sources/paper-server-1.21.11/net/minecraft/world/entity/ai/`
  - `tmp/paper-sources/paper-server-1.21.11/net/minecraft/world/entity/ai/sensing/`
  - `tmp/paper-sources/paper-server-1.21.11/net/minecraft/world/level/pathfinder/`
  - `tmp/paper-sources/paper-server-1.21.11/net/minecraft/server/level/`
- For each candidate, capture:
  - Current call frequency and per-tick cost (Spark or counters)
  - Allocation hot spots (JFR or allocation profiling)
  - Required invariants to keep behavior identical
- Prioritize 3-5 changes for Phase 1 and note expected wins vs risk.

## Baseline (Before Any Patches)
- Capture CPU flamegraphs / Spark profiles under representative load (same seed, mob counts, farms).
- Record tick breakdown (entity ticking, AI/brain, fluids, block entities, chunk spawning, random ticks).
- Capture per-entity counts (mob counts, villager counts, active chunks, block entities).
- Establish regression suite: startup, basic mob AI behavior, villager trading, iron farm, crop farm.

## Primary Bottlenecks (Observed / Expected)
1. **Entity ticking** (Mob/LivingEntity AI and movement)
2. **Brain behavior evaluation** (startEachNonRunningBehavior + tickSensors)
3. **Pathfinding** (createPath + Node evaluation)
4. **Fluids** (fluid ticks, flow updates)
5. **Block entities** (tickable block entities)
6. **Chunk spawning / random ticks**
7. **Block-state access patterns** (hot loops that call getBlockState in scans)

## Where to Look (Paper Sources)
AI/Brain/Sensors:
- `net/minecraft/world/entity/ai/Brain.java`
- `net/minecraft/world/entity/ai/sensing/Sensor.java`
- `net/minecraft/world/entity/ai/sensing/*Sensor.java`
- `net/minecraft/world/entity/ai/memory/NearestVisibleLivingEntities.java`
- `net/minecraft/world/entity/ai/behavior/*`
- `net/minecraft/world/entity/ai/goal/GoalSelector.java`

Entity Tick Flow:
- `net/minecraft/world/entity/LivingEntity.java`
- `net/minecraft/world/entity/Mob.java`
- `net/minecraft/server/level/ServerLevel.java` (tick flow)

Pathfinding:
- `net/minecraft/world/entity/ai/navigation/*`
- `net/minecraft/world/level/pathfinder/*`

Chunk / Block-State Access:
- `net/minecraft/world/level/Level.java`
- `net/minecraft/world/level/LevelAccessor.java`
- `net/minecraft/world/level/chunk/LevelChunk.java`
- `net/minecraft/world/level/chunk/LevelChunkSection.java`
- `net/minecraft/world/level/chunk/PalettedContainer.java`

Fluids / Block Entities:
- `net/minecraft/world/level/Level.java`
- `net/minecraft/world/level/block/entity/BlockEntity.java`
- `net/minecraft/world/level/tick/` (tick lists)

Spawning / Random Ticks:
- `net/minecraft/world/level/NaturalSpawner.java`
- `net/minecraft/server/level/ServerChunkCache.java`

## Optimization Focus Areas (Vanilla-Preserving)

### 1) Sensor / Brain Micro-Optimizations (Main Thread)
Target: reduce per-tick allocations and costly scans while keeping outcomes identical.
- Replace “sort then pick” with “single pass select nearest” where only nearest is needed.
- Avoid repeated `getEntitiesOfClass` allocations by reusing lists (local pools) or using fastutil lists.
- Replace streams in hot loops with indexed loops (Paper already does this in some places).
- Minimize boxing by using primitive maps/arrays where possible.
- Consider changing `NearestVisibleLivingEntities` caching map to use entity id (int) instead of identity hash.

Candidate files:
- `NearestLivingEntitySensor.java` (sort vs single-pass nearest)
- `NearestItemSensor.java` (already optimized, but check predicate order)
- `PiglinSpecificSensor.java`, `HoglinSpecificSensor.java` (repellent scans, list building)
- `NearestVisibleLivingEntities.java` (line-of-sight cache map)

### 2) Brain Memory Storage Improvements
Target: reduce HashMap overhead in `Brain.memories`.
- Consider array-backed storage keyed by registry ID (requires careful mapping).
- Cache lookup indices per Brain instance to avoid repeated registry lookups.
- Keep API behavior identical; only internal storage changes.

Candidate files:
- `Brain.java`

### 3) Pathfinding Cost Reduction (Same Behavior)
Target: reduce allocation, reduce duplicate state checks, and avoid redundant work.
- Reuse Node / NodeEvaluator structures with pooling.
- Reduce allocation of neighbor lists (preallocate, reuse arrays).
- Avoid repeated block-state lookups for the same position within a single path evaluation.
- Consider short-circuiting path recomputation when entity/target has not moved beyond thresholds (vanilla-equivalent if thresholds are 0).

Candidate files:
- `PathFinder.java`
- `PathNavigation.java`
- `NodeEvaluator` subclasses

### 4) Block-State Access in Hot Loops
Target: reduce per-call overhead without changing results.
- Avoid `new BlockPos` allocations; use `BlockPos.MutableBlockPos` in loops.
- Read chunk sections once when scanning contiguous regions (reduce repeated `getBlockState`).
- Use direct palette access for bulk scans where safe (preserve results).

Candidate files:
- Sensors that scan blocks (`findClosestMatch`, repellent checks)
- `NaturalSpawner` loops

### 5) Tick List / Fluid / Block Entity Micro-Optimizations
Target: reduce overhead in tick scheduling and block entity ticking.
- Replace iteration patterns that allocate per tick.
- Reduce redundant lookups for block entities.
- Micro-optimizations only; no changes to tick order.

Candidate files:
- `Level.java`, `ServerLevel.java`
- `world/level/tick/` classes

## Critical Notes / Risk Management
- **Do not** run AI or sensors off-thread without a full snapshot + revalidation model; the current world and Brain state are not thread-safe.
- Ensure all behavior-preserving changes are strictly equivalent in order and output.
- Add a config flag for any behavior changes (default off).
- Keep changes small and layered so they can be bisected.

## Patch Phases

### Phase 0: Measurement and Hotspot Confirmation
- Add lightweight counters for per-sensor and per-behavior cost.
- Run with realistic workloads; confirm biggest costs.

### Phase 1: Safe Micro-Optimizations (Low Risk)
- Remove avoidable allocations in sensors and behavior loops.
- Replace “sort + pick” with “single pass nearest” where equivalent.
- Use reusable mutable positions and lists.

### Phase 2: Data Structure Improvements (Medium Risk, Still Vanilla)
- Brain memory map replacement with array-backed storage.
- Line-of-sight cache map improvements in `NearestVisibleLivingEntities`.

### Phase 3: Pathfinding and Chunk Access Hot Loops
- Pool Node objects and reduce per-path allocations.
- Reduce duplicate block-state lookups inside pathfinding.

### Phase 4: Optional Behavior-Changing Optimizations (Opt-In)
- Sensor throttling by distance
- Static villager AI suppression
- Negative caching for behavior start conditions

## Verification / Test Plan
- Automated: start server, spawn villagers, run farms, compare output with baseline.
- Manual: trading, sleep schedules, panic behavior, iron farm rates.
- Regression: ensure no desync, no stuck AI, no reduced mob awareness.

## Deliverables for the Patch Repo
- Patch series with clear scope per commit (AI, pathfinding, chunk scans).
- A build profile doc mapping each change to measured impact.
- A config section for any non-vanilla behavior changes.
