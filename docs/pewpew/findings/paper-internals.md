# Paper Internals Notes (1.21.8)

## Tick pipeline (main thread)
- `MinecraftServer.tickServer` -> `tickChildren` is the core server loop.
- `tickChildren` runs: scheduler heartbeat, global region scheduler tick, per-entity task schedulers, processQueue, time updates, then loops all levels.
- The world loop sets `isIteratingOverLevels`, sets per-world flags (`hasPhysicsEvent`, `hasEntityMoveEvent`), calls `ServerLevel.tick`, then clears `explosionDensityCache`.
- After world ticks, connection/network tick runs.

## World tick structure
- `ServerLevel.tick` covers time/weather, block/fluid ticks, chunkSource tick, block events, entity tick list (`guardEntityTick` -> `tickNonPassenger`), then block entity ticks.
- `Level.tickBlockEntities` uses a mutable list of `TickingBlockEntity`.

## TickThread assertions
- The server thread is a `ca.spottedleaf.moonrise.common.util.TickThread` (created in `MinecraftServer.spin`).
- `TickThread` checks only validate thread type; `isTickThreadFor(...)` does not enforce per-world ownership.
- `ServerLevel.tickNonPassenger` and `Entity.setPosRaw` assert TickThread, so any parallel world tick must run on `TickThread` instances.

## Implications for parallel world ticks
- Parallel world tick threads must be `TickThread` instances; the main thread should avoid world mutations during the parallel phase.
- Cross-world/global work in `tickChildren` stays on the main thread before/after the world loop.
