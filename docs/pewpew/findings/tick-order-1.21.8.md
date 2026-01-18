# Tick Order + Lifecycle Notes (1.21.8)

## Tick order (MinecraftServer)
Source: `tmp/paper-1.21.8/paper-server/patches/sources/net/minecraft/server/MinecraftServer.java.patch`

- `tickServer`:
  - Starts watchdog + spark tick.
  - Increments `tickCount`, ticks `tickRateManager`.
  - Calls `tickChildren(hasTimeLeft)`.
  - Post-tick: `runAllTasks()`, spark tasks, ServerTickEndEvent, tallying.

- `tickChildren` order:
  1) `server.getScheduler().mainThreadHeartbeat()`
  2) GlobalRegionScheduler tick + per-entity task schedulers (Folia API)
  3) `commandFunctions` -> `getFunctions().tick()`
  4) processQueue runnables
  5) time updates per world
  6) world loop (`for ServerLevel : getAllLevels`) with `isIteratingOverLevels` guard
  7) `tickConnection()`

Implication: datapack function tick runs on main thread before any world ticks.

## World load/init order (createLevels/loadWorld0)
Source: same patch file (`MinecraftServer.loadWorld0` and `initWorld`).

- `addLevel(serverLevel)` happens before `initWorld(...)`.
- `WorldInitEvent` fires inside `initWorld` before chunks are generated.
- After `prepareLevels(...)` and `entityManager.tick()`, `WorldLoadEvent` fires.
- `isIteratingOverLevels` is toggled during ticks; world creation during tick should be blocked.

## World create/unload (CraftServer)
Source: `tmp/paper-1.21.8/paper-server/src/main/java/org/bukkit/craftbukkit/CraftServer.java`

- `createWorld`:
  - Adds `ServerLevel` via `console.addLevel(serverLevel)` before `initWorld(...)`.
  - Calls `prepareLevels(...)`, then `WorldLoadEvent`.
  - The guard `!console.isIteratingOverLevels` is commented out (Paper - Cat - Temp disable).

- `unloadWorld`:
  - The guard `!console.isIteratingOverLevels` is commented out.
  - Calls `WorldUnloadEvent`, saves (optional), closes chunk source + entity manager, then `console.removeLevel`.

Implication: we must add a hard barrier check to prevent create/unload while world ticks are running.
Candidate barrier points: pre-tick (before dispatch) and post-tick (after join) on the main thread.
Generation-id invalidation should be owned by the coordinator and incremented on add/remove.

## Datapack functions and scheduling
- `getFunctions().tick()` runs before the world loop each tick.
- ScheduleCommand uses per-world scheduled events (`serverLevelData.overworldData().getScheduledEvents()`), so function scheduling is world-scoped in Paper.

## Constraints for parallel world ticks
- Any world load/unload must happen at a barrier point (outside the world loop).
- Datapack functions and triggers must remain on main thread and stay ordered before world ticks.
- Plugin callbacks during world tick must be routed to main thread in the same tick order.
