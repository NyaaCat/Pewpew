# Risks and Open Questions

## Technical risks
- World ticks on worker threads can violate plugin thread-affinity unless events/hooks are routed to main.
- Cross-world shared state (player list, scoreboard, global registries) may be touched from world ticks.
- Global static toggles (e.g., hopper move event flags) are per-world today and cannot be safely mutated in parallel.
- TickThread checks are coarse; wrong-thread access might slip through without extra guards.
- Commit queues can reorder effects if sequencing is not carefully enforced.
- World load/unload during parallel ticks can cause stale async work and invalid side effects.
- Datapack function ordering can be broken if not isolated from parallel world ticks.
- Aikar Timings is not safe under parallel world ticking; stack corruption can crash the server.
- Non-player portal travel is disabled during parallel ticks (behavior difference).
- Inventory open after world switch is gated; plugins must wait 1 tick after teleport.
- Chunk ticket updates and unloads must stay on the owning world tick thread.

## Performance risks
- Barriered ticks can increase worst-case latency; tick time may exceed 50ms under load.
- Snapshot/commit buffers add memory and copying overhead.
- Thread pool oversubscription on low-core machines can reduce overall throughput.
- Small workloads can regress when snapshot copy cost exceeds compute savings.

## Open questions
- Which parts of `ServerLevel.tick` can move off main without breaking plugins?
- What is the minimal commit surface (events, sounds, network, command hooks)?
- How to guarantee deterministic world iteration order under parallel execution?
- How to handle cross-world systems (advancements, scheduler, command functions)?
- Should we auto-disable timings when `WorldTickCoordinator` is enabled, or document only?
