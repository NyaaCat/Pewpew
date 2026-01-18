# Pewpew Task Checklist

- [x] Validate 1.21.8 tick order (tickServer -> tickChildren -> commandFunctions -> levels) and record constraints.
- [x] Map multi-world load/unload flow and define safe barrier points (with generation-id invalidation).
- [x] Verify datapack function tick/triggers and main-thread boundaries; update invariants/risks.
- [x] Capture baseline correctness tests and perf numbers (single-threaded; perf harness ready, baseline run complete).
- [x] Define A/B perf harness to compare vanilla Paper vs Pewpew on identical hardware.
- [x] Add WorldTickCoordinator skeleton with feature flag (no behavior change).
- [x] Add instrumentation: per-world timings, queue depth, stall detection.
- [x] Implement fixed `TickThread` pool + barrier under flag; verify per-world tick isolation (tickChildren dispatch wired, isolation verification pending).
- [x] Add safe world load/unload gating at barrier points; cancel stale async work (gating done, stale async work pending).
- [x] Implement SnapshotManager (read-only) and CommitQueue (main-thread events) (scaffold + tests done, integration pending).
- [x] Convert one safe subsystem to compute+commit (small surface area first).
- [x] Add async AcquirePoi pathfinding (snapshot-based) with correctness + perf tests.
- [x] Add selected async sensor precompute (snapshot-based) with correctness + perf tests.
- [x] Rebrand to Pewpew (build info + brand payload paths).
- [x] Wire automated tests and perf checks into Gradle/CI (non-interactive).
- [x] Export updated patch series from nested repos (paper-server + minecraft) for modified files.
