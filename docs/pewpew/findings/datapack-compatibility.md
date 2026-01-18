# Datapack Compatibility Notes

## NyaaWorks (tmp/NyaaWorks)
- Uses `minecraft:load` to run `nw:init` and `nc:init` and schedules recurring work (`nc:20gt_tick`, `nc:backup_tick`, `nw:slowtick`).
- Tick tag points at `nw:maintick`, which is currently empty; most work happens via scheduled functions and player interactions.
- Commands include `forceload`, `loot spawn`, block placement, and entity/tag operations.
- Compatibility requirement: function execution and scheduled callbacks must stay on the main thread with the correct world context (spawns and block updates are not safe off-thread).

## NyaaEnchants (tmp/NyaaEnchants)
- Uses `minecraft:load` to run `nel:init` and `minecraft:tick` to run `nel:maintick`, which delegates to `ne:maintick` and effect handlers.
- Heavily uses `summon` (item_display/interaction/area_effect_cloud), scheduled functions, predicates, and scoreboard state.
- Compatibility requirement: function execution must remain main-thread and preserve vanilla ordering; entity spawns and scheduled callbacks are not safe off-thread.

## Pewpew implications
- Datapack `load`, `tick`, and `schedule` functions must remain main-thread only.
- Per-world tick threads should not execute datapack logic; any async work must be snapshot-only with main-thread commits.
- World context must be explicit and preserved for spawns, block edits, and entity queries.
