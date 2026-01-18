# Plugin Impact and API Plan

## Compatibility goals
- Keep existing Bukkit/Paper APIs on the main thread.
- Preserve event ordering and thread expectations for plugins.
- Route any off-thread world work through a main-thread commit queue before invoking plugins.

## Known incompatibilities (SparklyPaper findings)
- NoCheatPlus: movement checks and change tracker race when accessing cross-world block cache.
- MyPet: Warden mount teleport can crash on cross-world access.
- Citizens: sleeping NPCs can crash on cross-world bed lookups.

## Behavior changes to document
- Aikar Timings is unsafe under parallel ticking; use Spark instead.
- Non-player entities do not cross Nether/End portals while parallel ticking is enabled.
- Inventory open after cross-world teleport requires a 1-tick delay.
- Plugins must schedule cross-world teleports/loads on the main thread after ticks complete.

## New safe async capabilities (opt-in)
- ThreadSafeSnapshot API:
  - Read-only snapshot for block states, biomes, and entity positions.
  - Designed for async analytics, AI utilities, and path queries.
- Async task helpers:
  - Async tasks that only accept snapshot views.
  - Execute on the shared fixed worker pool (no plugin-created threads by default).
  - Explicit validation hooks when returning results to the main thread.

## Deprecations and removals
- Yasui plugin caching is no longer used; any required caching should move into Pewpew core.

## Migration guidance
- Document safe async patterns for plugin developers.
- Provide sample plugins that use snapshots instead of direct world access.
