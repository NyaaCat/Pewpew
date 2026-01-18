# Sensor Precompute Plan (Draft)

## Integration points
- Brain.tick -> tickSensors is the entry point.
- Add an AsyncSensorService that can schedule precompute jobs before tickSensors.
- Results are committed on the main thread before behavior evaluation.

## Thread-safety notes
- Sensor uses shared static TargetingConditions updated per tick; do not use off-thread.
- Off-thread work must avoid Bukkit events, entity mutations, or chunk loads.
- Prefer read-only snapshots of nearby entities and block states.
- Off-thread results should use entity ids/positions, not live entity objects.

## Phase 1 candidates (entity-list precompute)
These can precompute a sorted candidate list off-thread, then filter/commit on the main thread.
- NearestLivingEntitySensor
  - Precompute: list of nearby LivingEntity ids + distances in follow-range AABB.
  - Main thread: resolve entities, construct NearestVisibleLivingEntities, set memories.
- PlayerSensor
  - Precompute: list of nearby player ids + distances.
  - Main thread: apply TargetingConditions (line-of-sight) and set memories.
- NearestItemSensor
  - Precompute: list of nearby item ids + distances.
  - Main thread: wantsToPickUp + line-of-sight and set memory.

Derived sensors benefit from the above without async work:
- NearestVisibleLivingEntitySensor and subclasses (VillagerHostilesSensor, AxolotlAttackablesSensor, FrogAttackablesSensor, BreezeAttackEntitySensor).
- WardenEntitySensor (uses NEAREST_LIVING_ENTITIES memory).
- VillagerBabiesSensor, GolemSensor, MobSensor (filter the cached lists).

## Phase 2 candidates (snapshot block scanning)
Require a RegionSnapshot or BlockView, but still read-only:
- HoglinSpecificSensor (nearest repellent scan).
- PiglinSpecificSensor (nearest repellent scan).
- SecondaryPoiSensor (block scan for secondary POIs).
- NearestBedSensor (POI + pathfinding; depends on async pathfinding readiness).

## Not safe for async (main-thread only)
- TemptingSensor (Bukkit targeting event).
- Sensors that read or mutate complex entity state during decision (keep on main thread until snapshot rules are defined).

## Commit strategy
- Use a SensorResult object to record memory updates (set/erase + values).
- Apply results on the main thread in the same order as vanilla sensors.
- If the entity moved or died after scheduling, discard results.
- If the candidate list is stale, rebuild synchronously.
