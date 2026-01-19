# Production World Optimization Plan (v6 profiles)

## Context
- Profiles captured with 16 bots on production copy `tmp/benchworld/v6`.
- Baseline profile: `tmp/bench/prod-profile-20260119-163445-benchworld/off/profile-off.txt`
- Pewpew-on profile: `tmp/bench/prod-profile-20260119-163445-benchworld/on/profile-on.txt`

## Key hotspots (from profiles)
- Natural spawning dominates: `NaturalSpawner.spawnForChunk` ~33-34% of samples.
- Spawn path is block-state heavy:
  - `Level.getBlockStateIfLoadedAndInBounds` ~10.6-11.6%
  - `LevelChunk.getBlockStateFinal` ~10-10.8%
  - `PalettedContainer.get` ~7.1-7.6%
  - `PalettedContainer.readPalette` ~2.5-2.6%
- Biome lookup still hot: `LevelReader.getBiome`/`BiomeManager.getBiome` ~5.5% (off), `SpawnSnapshotLevelReader.getBiome` ~3.0% (on).
- Player distance checks in spawn loops: `EntityGetter.getNearestPlayer` ~3.6-4.2%.
- Block entity tick ~7-8%, with hoppers ~3.3%.

## Optimization principles
- Attack slow low-level primitives first (block-state access, palette reads, biome access).
- Keep behavior identical by default; any behavior change is opt-in.
- Verify each change with A/B profiling on the same world copy and bot setup.

## Plan of record

### 1) Spawn block-state access fast path (start here)
Goal: bypass `Level.getBlockStateIfLoadedAndInBounds` and `LevelChunk.getBlockStateFinal` for spawn loops.
Steps:
- Use spawn snapshot access for `getBlockStateIfLoadedAndInBounds` and `isLoadedAndInBounds` in `NaturalSpawner.spawnCategoryForPosition`.
- Ensure snapshot reads hit cached palette arrays (avoid `PalettedContainer.readPalette` slow path).
- If needed, introduce a lightweight `SectionSnapshot` inside `SpawnChunkSnapshot` that reads `BitStorage` + palette directly using a precomputed palette array.
Files:
- `pewpew-server/src/minecraft/java/net/minecraft/world/level/NaturalSpawner.java`
- `pewpew-server/src/minecraft/java/net/minecraft/world/level/chunk/PalettedContainer.java`
Success criteria:
- Reduced samples in `Level.getBlockStateIfLoadedAndInBounds` and `LevelChunk.getBlockStateFinal`.
- `PalettedContainer.readPalette` share drops (copy path uses fast palette arrays).

### 2) Spawn biome lookup cache
Goal: reduce `BiomeManager.getBiome` cost in spawn loops.
Steps:
- Extend `SpawnChunkSnapshot` to cache noise biomes for spawn positions within the chunk.
- Ensure `SpawnSnapshotLevelReader.getBiome` returns cached values for positions within the snapshot.
Files:
- `pewpew-server/src/minecraft/java/net/minecraft/world/level/NaturalSpawner.java`
Success criteria:
- `SpawnSnapshotLevelReader.getBiome` samples drop in on-profile.

### 3) Nearest player distance precompute
Goal: avoid repeated `EntityGetter.getNearestPlayer` scans per spawn candidate.
Steps:
- For each spawning chunk, precompute nearest player distance (or nearest player position) once via `NearbyPlayers`.
- Pass the computed distance into the inner spawn loop and use it for `isRightDistanceToPlayerAndSpawnPoint`.
Files:
- `pewpew-server/src/minecraft/java/net/minecraft/world/level/NaturalSpawner.java`
- `pewpew-server/src/minecraft/java/ca/spottedleaf/moonrise/common/misc/NearbyPlayers.java`
Success criteria:
- `EntityGetter.getNearestPlayer` samples drop in spawn path.

### 4) Block entity tick cost reduction (hoppers first)
Goal: reduce `LevelChunk.getBlockState` usage inside block entity ticks.
Steps:
- Cache block state in `BlockEntity` and invalidate on block update.
- In hopper tick, early-bail on locked/full/empty states before expensive operations.
Files:
- `pewpew-server/src/minecraft/java/net/minecraft/world/level/block/entity/BlockEntity.java`
- `pewpew-server/src/minecraft/java/net/minecraft/world/level/block/entity/HopperBlockEntity.java`
Success criteria:
- `LevelChunk.getBlockState` share drops under `BoundTickingBlockEntity.tick`.

### 5) Validation + profiling
Goal: ensure each change provides real gains and preserves behavior.
Steps:
- Re-run the same production world profile after each step.
- Record delta on the targeted low-level functions.
- Keep a running A/B report in `docs/pewpew/findings/`.

