# Production Config Audit v4 (Full Reset + Re-optimize)

Date: 2026-02-08
Server: 8 physical cores / 16 logical cores, dedicated to pewpew only.
Heavy usage: many entities, redstone machines, farms, villager trading halls.
Approach: Reset all non-seed/non-auth values to vanilla/Paper defaults, then re-optimize each with code-verified reasoning.

## Frozen Scope (Do Not Touch)

- All `seed-*` values in spigot.yml
- Auth/proxy: `online-mode`, `enforce-secure-profile`, `proxies.*`, `velocity.*`
- Server identity: `level-seed`, `level-name`, `level-type`, `server-port`, `server-ip`

## Hard Constraints (User-Specified)

| Setting | Value | Reason |
|---------|-------|--------|
| `redstone-implementation` | ALTERNATE_CURRENT | VANILLA causes severe lag |
| `tick-inactive-villagers` | false | Trading hall optimization |
| `restrict-player-reloot` | false | Intentional gameplay design |
| `auto-replenish` | true | Intentional gameplay design |
| `generate-flat-bedrock` | true | Server policy |
| `lootables.refresh-min` | 2h | Server policy |
| `async-pathfinding-monster-sync-fallback` | false | Proven to negate async benefit |

---

## 1. bukkit.yml

All values at vanilla defaults. No changes needed.

| Key | Default | Final | Code Reference |
|-----|---------|-------|----------------|
| spawn-limits.monsters | 70 | 70 | `CraftSpawnCategory.getConfigNameSpawnLimit()` |
| spawn-limits.animals | 10 | 10 | Same |
| spawn-limits.water-animals | 5 | 5 | Same |
| spawn-limits.water-ambient | 20 | 20 | Same |
| spawn-limits.water-underground-creature | 5 | 5 | Same |
| spawn-limits.axolotls | 5 | 5 | Same |
| spawn-limits.ambient | 15 | 15 | Same |
| ticks-per.animal-spawns | 400 | 400 | `CraftSpawnCategory.getConfigNameTicksPerSpawn()` |
| ticks-per.monster-spawns | 1 | 1 | Same |
| ticks-per.autosave | 6000 | 6000 | 5 min, standard |
| chunk-gc.period-in-ticks | 600 | 600 | 30s, standard |
| connection-throttle | 4000 | 4000 | Velocity handles rate limiting |

---

## 2. server.properties

| Key | Vanilla | Old | New | Code Reference | Reasoning |
|-----|---------|-----|-----|----------------|-----------|
| view-distance | 10 | 8 | **10** | `DedicatedServerProperties.java:102` | Restore vanilla. Moonrise chunk system is efficient. Visual range matters for player experience. |
| simulation-distance | 10 | 10 | 10 | `DedicatedServerProperties.java:103` | Vanilla. Must keep for farms/redstone. Lower = farms break outside range. |
| network-compression-threshold | 256 | -1 | **-1** | `DedicatedServerProperties.java:105`, `ServerLoginPacketListenerImpl.java:146` | Keep disabled. Velocity proxy handles compression. Double-compression wastes CPU. |
| max-chained-neighbor-updates | 1000000 | 1000000 | 1000000 | `CollectingNeighborUpdater.java:57,65` | Vanilla safety limit for redstone chains. |
| entity-broadcast-range-percentage | 100 | 100 | 100 | `DedicatedServer.java:734-740` | Vanilla. Scaling factor = trackingDistance * percentage / 100. |
| sync-chunk-writes | true | false | **false** | `DedicatedServerProperties.java` patch | Paper forces off. Async writes = better tick times. |
| max-tick-time | 60000 | 60000 | 60000 | `ServerWatchdog.java:40` | Watchdog timeout. Don't change. |
| spawn-protection | 16 | 3 | **3** | `DedicatedServer.java:515-540` | Server-specific, keep. |
| pause-when-empty-seconds | -1 | -1 | -1 | `MinecraftServer.java:994-1004` | Disabled. Farms must tick when server empty. |

---

## 3. spigot.yml

### Global Settings

| Key | Default | Old | New | Code Reference | Reasoning |
|-----|---------|-----|-----|----------------|-----------|
| netty-threads | 4 | 8 | **4** | `SpigotConfig.java:199` | Restore default. Velocity handles networking. 4 threads sufficient for backend connections. |

### Entity Activation Range

Controls whether entities get full AI or simplified inactive ticking. `ActivationRange.java:154-158`

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| animals | 32 | 32 | 32 | Default. Passive mobs tick fully within 32 blocks. |
| monsters | 32 | 32 | 32 | Default. Hostile AI within 32 blocks. |
| raiders | 64 | 64 | 64 | Default. Larger range prevents raid progression issues. |
| misc | 16 | 16 | 16 | Default. Items/XP/arrows. |
| water | **16** | 32 | **16** | Restore default. Water mob AI at 32 wastes CPU in oceans. `SpigotWorldConfig.java:192` |
| villagers | 32 | 32 | 32 | Default. With tick-inactive-villagers=false, this is the ONLY range where villagers function. |
| flying-monsters | 32 | 32 | 32 | Default. |

### Wake-Up Inactive

Periodically activates inactive entities for brief full ticking. Code: `ActivationRange.java` `checkInactiveWakeup`. With tick-inactive-villagers=false, villager wake-up settings are irrelevant (villagers are completely frozen outside activation range, not inactive-ticked).

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| animals-max-per-tick | 4 | 2 | **4** | Restore default. Animals are low-cost when awakened. |
| animals-every | 1200 | 2400 | **1200** | Restore default (60s). |
| animals-for | 100 | 40 | **100** | Restore default (5s). Needed for breeding/grass eating. |
| monsters-max-per-tick | 8 | 4 | **8** | Restore default. |
| monsters-every | 400 | 800 | **400** | Restore default (20s). |
| monsters-for | 100 | 40 | **100** | Restore default (5s). Needed for targeting/navigation. |
| villagers-max-per-tick | 4 | 2 | **4** | Restore default. N/A with tick-inactive-villagers=false. |
| villagers-every | 600 | 1200 | **600** | Restore default. N/A. |
| villagers-for | 100 | 40 | **100** | Restore default. N/A. |
| flying-monsters-max-per-tick | 8 | 4 | **8** | Restore default. |
| flying-monsters-every | 200 | 400 | **200** | Restore default (10s). |
| flying-monsters-for | 100 | 40 | **100** | Restore default (5s). |

### Villager-Specific

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| villagers-work-immunity-after | 100 | 100 | 100 | Default (5s). Extra ticks when working at stations. |
| villagers-work-immunity-for | 20 | 20 | 20 | Default (1s). Duration of work immunity. |
| villagers-active-for-panic | true | true | true | Default. Villagers always active during zombie attack. |
| **tick-inactive-villagers** | true | false | **false** | **USER CONSTRAINT.** Villagers frozen outside 32 blocks. `Villager.java:279-282` |
| ignore-spectators | false | true | **true** | Keep optimization. Spectators shouldn't activate entity AI. |

### Entity Tracking Range

Controls entity visibility distance (network packets). `SpigotWorldConfig.java:246-260`, `ChunkMap.TrackedEntity`, `TrackingRange.java`

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| players | 128 | 64 | **128** | Restore default. Players must see each other at full range. |
| animals | 96 | 64 | **96** | Restore default. |
| monsters | 96 | 64 | **96** | Restore default. |
| misc | 96 | 48 | **32** | Optimize. Items/XP/arrows visible at 32 is enough. |
| display | 128 | 128 | 128 | Default. Display entities for builds. |
| other | 64 | 64 | 64 | Default. |

### Merge Radius

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| exp | -1 | -1 | -1 | Paper handles XP merge. `SpigotWorldConfig.java:143` |
| item | 0.5 | 0.5 | 0.5 | Default. `SpigotWorldConfig.java:138` |

### Hopper (Spigot)

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| hopper-transfer | 8 | 8 | 8 | Vanilla rate. `SpigotWorldConfig.java:268` |
| hopper-check | 1 | 1 | 1 | Vanilla. `SpigotWorldConfig.java:272` |
| hopper-amount | 1 | 1 | 1 | Vanilla. 1 item per transfer. |
| hopper-can-load-chunks | false | false | false | Prevent chunk loading by hoppers. |

### Other Spigot

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| mob-spawn-range | 8 | 8 | 8 | Vanilla. `SpigotWorldConfig.java:177` |
| item-despawn-rate | 6000 | 6000 | 6000 | 5 minutes vanilla. |
| arrow-despawn-rate | 1200 | 1200 | 1200 | 60s default. |
| trident-despawn-rate | 1200 | 1200 | 1200 | Default. |
| nerf-spawner-mobs | false | false | false | Vanilla. |
| max-tnt-per-tick | 100 | 100 | 100 | Default. |
| max-tick-time.tile | 50 | 50 | 50 | Default. |
| max-tick-time.entity | 50 | 50 | 50 | Default. |

---

## 4. paper-global.yml

### Chunk System

| Key | Default | Old | New | Code Reference | Reasoning |
|-----|---------|-----|-----|----------------|-----------|
| gen-parallelism | default | default | default | `GlobalConfiguration.java:227-248` | "default" = parallel gen enabled. |
| io-threads | -1 | -1 | -1 | `MoonriseCommon.adjustWorkerThreads()` | Auto. |
| worker-threads | -1 | -1 | -1 | Same | Auto = (16/2)/2 = 4 chunk workers. |

### Chunk Loading

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| player-max-chunk-send-rate | 75.0 | 75.0 | 75.0 | Default. `GlobalConfiguration.java:43` |
| player-max-chunk-load-rate | 100.0 | 100.0 | 100.0 | Default. `GlobalConfiguration.java:50` |
| player-max-chunk-generate-rate | -1.0 | -1.0 | -1.0 | Unlimited. Default. |
| auto-config-send-distance | true | true | true | Default. Matches client settings. |
| player-max-concurrent-chunk-loads | 0 | 0 | 0 | Auto. Default. |
| player-max-concurrent-chunk-generates | 0 | 0 | 0 | Auto. Default. |

### Misc

| Key | Default | Old | New | Code Reference | Reasoning |
|-----|---------|-----|-----|----------------|-----------|
| max-joins-per-tick | 5 | 3 | **5** | `GlobalConfiguration.java:346`, `Connection.java:580` | Restore default. Velocity handles rate-limiting. |
| region-file-cache-size | 256 | 256 | 256 | `GlobalConfiguration.java:350`, `RegionFileStorage.java:113` | Default. |
| compression-level | default | default | default | `GlobalConfiguration.java:355` | Default. |
| lag-compensate-block-breaking | true | true | true | Adjusts block break timing for lag. |
| prevent-negative-villager-demand | false | false | false | Vanilla demand. `MerchantOffer.java:147` |

### Player Auto-Save

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| rate | -1 | -1 | -1 | Uses global autosave. `MinecraftServer.java:1540` |
| max-per-tick | auto (-1) | 2 | **-1** | Restore auto. Auto = 10 or 20. `GlobalConfiguration.java:311-317` |

### Scoreboards

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| save-empty-scoreboard-teams | true | true | true | Default. |

---

## 5. paper-world-defaults.yml

### Entities - Armor Stands

| Key | Default | Old | New | Code Reference | Reasoning |
|-----|---------|-----|-----|----------------|-----------|
| do-collision-entity-lookups | true | true | **false** | `ArmorStand.java` | Armor stand collision lookups are expensive. Rarely needed in survival. Not noticeable to players. |
| tick | true | true | true | `ServerLevel.java` | Keep for plugin compat. |

### Entities - Spawning

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| per-player-mob-spawns | true | true | true | Essential Paper optimization. |
| count-all-mobs-for-spawning | false | false | false | Default. Only counts nearby mobs. |
| despawn-range-shape | ELLIPSOID | ELLIPSOID | ELLIPSOID | Default. |

### Entity Per Chunk Save Limit (OPTIMIZATION)

Default is -1 (unlimited). Set limits to prevent chunk bloat from projectile/xp accumulation.
Code: `ChunkEntitySlices.java`, `EntityStorage.java`, `EntityType.java`

| Entity | Default | Old | New | Reasoning |
|--------|---------|-----|-----|-----------|
| arrow | -1 | -1 | **16** | Prevent arrow accumulation |
| ender_pearl | -1 | -1 | **16** | Prevent pearl buildup |
| experience_orb | -1 | -1 | **16** | XP orb cleanup on save |
| fireball | -1 | -1 | **8** | Rarely need more |
| small_fireball | -1 | -1 | **8** | Same |
| snowball | -1 | -1 | **16** | Cleanup |

### Alt Item Despawn Rate (OPTIMIZATION)

Enables faster despawn for common farm byproducts. Code: `ItemEntity.java` checks `altItemDespawnRate`.

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| enabled | false | false | **false** | Keep disabled per user request. |
| cobblestone | 300 | 300 | 300 | Default example entry. |

### Entities - Behavior

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| experience-merge-max-value | -1 | -1 | -1 | Unlimited merge. Default. |
| stuck-entity-poi-retry-delay | 200 | 300 | **200** | Restore default. `Behavior.java:336` |
| zombies-target-turtle-eggs | true | true | true | Vanilla. |
| nerf-pigmen-from-nether-portals | false | false | false | Vanilla. |

### Environment

| Key | Default | Old | New | Code Reference | Reasoning |
|-----|---------|-----|-----|----------------|-----------|
| optimize-explosions | false | true | **true** | `ServerExplosion.java:758` | Keep. Paper explosion cache. Zero gameplay difference. |
| generate-flat-bedrock | false | true | **true** | `OptionallyFlatBedrockConditionSource.java:49` | **USER CONSTRAINT.** |
| fire-tick-delay | 30 | 30 | 30 | `FireBlock.java` | Default. |
| portal-search-radius | 128 | 128 | 128 | Default. |
| portal-create-radius | 16 | 16 | 16 | Default. |

### Misc

| Key | Default | Old | New | Code Reference | Reasoning |
|-----|---------|-----|-----|----------------|-----------|
| redstone-implementation | VANILLA | ALTERNATE_CURRENT | **ALTERNATE_CURRENT** | `RedStoneWireBlock.java:373,396,426` | **USER CONSTRAINT.** |
| alternate-current-update-order | HORIZONTAL_FIRST_OUTWARD | HORIZONTAL_FIRST_OUTWARD | HORIZONTAL_FIRST_OUTWARD | `WireHandler.java` |
| update-pathfinding-on-block-update | true | true | **false** | `PathNavigation.java` | **OPTIMIZATION.** Mobs recalculate paths on every block change. Very expensive on redstone/piston servers. Mobs still pathfind normally on regular schedule. |
| shield-blocking-delay | 5 | 5 | 5 | Vanilla. |

### Hopper (Paper)

| Key | Default | Old | New | Code Reference | Reasoning |
|-----|---------|-----|-----|----------------|-----------|
| cooldown-when-full | true | true | true | `HopperBlockEntity.java` | Adds cooldown when output full. |
| disable-move-event | false | true | **false** | `MinecraftServer.java:1719` | Restore default. Disabling breaks chest-locking plugins (InventoryMoveItemEvent is suppressed). |
| ignore-occluding-blocks | false | false | false | Default. |

### Lootables

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| auto-replenish | false | true | **true** | **USER CONSTRAINT.** |
| restrict-player-reloot | true | false | **false** | **USER CONSTRAINT.** |
| refresh-min | 12h | 2h | **2h** | **USER CONSTRAINT.** |
| refresh-max | 2d | 2d | 2d | Default. |
| reset-seed-on-fill | true | true | true | Default. |

### Chunks

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| auto-save-interval | default | default | default | Uses bukkit autosave. |
| max-auto-save-chunks-per-tick | 24 | 24 | 24 | Default. `PaperHooks.java` |
| prevent-moving-into-unloaded-chunks | false | true | **true** | Keep. Prevents sync chunk loads from player movement. |
| delay-chunk-unloads-by | 10s | 10s | 10s | Default. |

### Collisions

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| max-entity-collisions | 8 | 8 | 8 | Default. `LivingEntity.java` |

### Tick Rates

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| grass-spread | 1 | 1 | 1 | Default. `SpreadingSnowyDirtBlock.java` |
| container-update | 1 | 1 | 1 | Default. `ServerPlayer.java` |
| mob-spawner | 1 | 1 | 1 | Default. `BaseSpawner.java` |
| wet-farmland | 1 | 1 | 1 | Default. `FarmBlock.java` |
| dry-farmland | 1 | 1 | 1 | Default. `FarmBlock.java` |
| villager.secondarypoisensor | 40 | 40 | 40 | Default. `Sensor.java` |
| villager.validatenearbypoi | -1 | -1 | -1 | Default = vanilla rate. `Behavior.java` |

### Fixes

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| fix-items-merging-through-walls | false | true | **true** | Keep. Prevents items merging through walls. `ItemEntity.java:264-267` |
| disable-unloaded-chunk-enderpearl-exploit | false | true | **true** | Keep. Prevents pearl exploit. |
| split-overstacked-loot | true | true | true | Default. |

### Scoreboards

| Key | Default | Old | New | Reasoning |
|-----|---------|-----|-----|-----------|
| allow-non-player-entities-on-scoreboards | true | true | true | Default. |

---

## 6. pewpew.yml

### Features (all kept as production values)

| Key | Default | Final | Code Reference | Reasoning |
|-----|---------|-------|----------------|-----------|
| async-pathfinding | false | **true** | `AsyncPathService.java` | Offloads pathfinding to async pool. |
| async-sensors | false | **true** | `AsyncSensorService.java` | Offloads sensor calculations. |
| spawn-snapshot-cache | false | **true** | `NaturalSpawner.java:75` | Caches chunk snapshots for spawning. |
| world-tick-coordinator | false | **true** | `WorldTickCoordinator.java` | Parallel world ticking. |
| tick-thread-hard-throw | true | true | Default. Thread safety enforcement. |

### Settings

For 8 physical / 16 logical cores, thread allocation:
- Main thread: 1
- World tick coordinator: up to 15 (capped by world count)
- Async pool (pathfinding/sensors): 8
- Moonrise chunk workers: 4 (auto)
- Netty: 4
- Oversubscription: ~2x, acceptable since most threads are idle/IO-bound.

| Key | Default | Old | New | Code Reference | Reasoning |
|-----|---------|-----|-----|----------------|-----------|
| async-pool-workers | -1 (auto=8) | 8 | **8** | `PewpewAsyncPool.java:53-57` | Auto = cores/2 = 8. Optimal. |
| async-pool-queue-limit | -1 | 4096 | **4096** | `PewpewAsyncPool.java:58` | Generous queue for burst loads. |
| async-pathfinding-max-pending | -1 | 2048 | **2048** | `AsyncPathService.java:250-253` | Higher than auto (workers*32=256). Keeps pipeline fed under heavy mob counts. |
| async-pathfinding-monster-sync-fallback | true | false | **false** | `AsyncPathService.java:85-96` | **USER CONSTRAINT.** Skip sync fallback when saturated. |
| world-tick-coordinator-workers | -1 (auto=15) | 15 | **15** | `WorldTickCoordinator.java:317-323` | Auto = cores-1 = 15. Capped by world count. |
| world-tick-coordinator-stall-threshold-nanos | 50000000 | 50000000 | 50000000 | Default 50ms monitoring threshold. |
| world-tick-coordinator-dedicated-worlds | [] | [v5,v6,vx] | [minecraft:v5,minecraft:v6,minecraft:vx] | `WorldTickCoordinator.java:339` | Fixed namespace prefix to match runtime key format. |

---

## Summary of All Changes from Current Production

### Restored to Defaults (15 changes)
1. `server.properties` view-distance: 8 → **10**
2. `spigot.yml` netty-threads: 8 → **4**
3. `spigot.yml` water activation range: 32 → **16**
4. `spigot.yml` wake-up animals: max=2,every=2400,for=40 → **4,1200,100**
5. `spigot.yml` wake-up monsters: max=4,every=800,for=40 → **8,400,100**
6. `spigot.yml` wake-up villagers: max=2,every=1200,for=40 → **4,600,100**
7. `spigot.yml` wake-up flying: max=4,every=400,for=40 → **8,200,100**
8. `spigot.yml` entity-tracking-range.players: 64 → **128**
9. `paper-global.yml` max-joins-per-tick: 3 → **5**
10. `paper-global.yml` player-auto-save.max-per-tick: 2 → **-1** (auto)
11. `paper-world-defaults.yml` creative-arrow-despawn-rate: '20' → **default**
12. `paper-world-defaults.yml` stuck-entity-poi-retry-delay: 300 → **200**
13. `paper-world-defaults.yml` scoreboards.allow-non-player-entities-on-scoreboards: already true
14. `paper-global.yml` scoreboards.save-empty-scoreboard-teams: already true
15. `pewpew.yml` dedicated-worlds: fixed namespace prefix

### New Optimizations (4 changes)
1. `spigot.yml` entity-tracking-range misc: → **32** (items/arrows)
2. `paper-world-defaults.yml` armor-stands.do-collision-entity-lookups → **false**
3. `paper-world-defaults.yml` entity-per-chunk-save-limit → **set limits**
4. `paper-world-defaults.yml` update-pathfinding-on-block-update → **false**

### Reverted to Default (plugin compat)
1. `paper-world-defaults.yml` hopper.disable-move-event: true → **false** (锁箱子插件需要 InventoryMoveItemEvent)
2. `spigot.yml` entity-tracking-range animals/monsters: 48 → **96** (restore default)
3. `paper-world-defaults.yml` alt-item-despawn-rate: enabled → **false** (不开启)

### Preserved Optimizations (existing, code-verified)
1. optimize-explosions: true (`ServerExplosion.java:758`)
2. prevent-moving-into-unloaded-chunks: true (`ServerGamePacketListenerImpl.java`)
4. fix-items-merging-through-walls: true (`ItemEntity.java:264-267`)
5. disable-unloaded-chunk-enderpearl-exploit: true
6. redstone-implementation: ALTERNATE_CURRENT (`RedStoneWireBlock.java`)
7. tick-inactive-villagers: false (`Villager.java:279-282`)
8. ignore-spectators: true
9. All pewpew async features enabled
