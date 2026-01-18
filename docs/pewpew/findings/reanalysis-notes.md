# Reanalysis Notes (Paper 1.21.8)

## Status
- Prior 1.21.11 thread-safety notes are likely still applicable, but must be re-verified on 1.21.8 sources.
- Tick order and world lifecycle notes captured in `docs/pewpew/findings/tick-order-1.21.8.md`.
- CraftServer create/unload guard against ticking is commented out; must be enforced by our coordinator.

## Known blockers to verify
- PathNavigationRegion uses cached chunk arrays sourced from live chunk data; not safe off-thread.
- Pathfinding uses mutable per-mob caches (NodeEvaluator/PathFinder state) and cannot be shared.
- PalettedContainer reads are unsynchronized.
- Sensors update shared TargetingConditions each tick.

## Next checks
- Confirm chunk accessors used by PathNavigationRegion in 1.21.8.
- Confirm shared pathfinding caches (if any) in ServerLevel/pathfinder.
- Map all TickThread checks that will gate parallel world ticks.
