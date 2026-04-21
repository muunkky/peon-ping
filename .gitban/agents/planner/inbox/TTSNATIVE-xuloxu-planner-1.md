The reviewer flagged 3 non-blocking items, grouped into 3 cards below.
Create ONE card per group. Do not split groups into multiple cards.
The planner is responsible for deduplication against existing cards.
All cards go into the current sprint unless marked BLOCKED with a reason.

### Card 1: Consolidate hook-handle-use install block via Install-HelperScript (remote branch)
Sprint: TTSNATIVE
Files touched:
- install.ps1
- tests/install-windows.Tests.ps1 (or equivalent Pester coverage for the refactor)
Items:
- L1: Immediately below the three refactored call-sites (lines 336–367 of `install.ps1`), the `hook-handle-use.ps1` / `hook-handle-use.sh` / `notify.sh` install block carries a very similar copy-or-download shape — the local branch does three `Copy-Item`s under a single `Test-Path` guard on the `.ps1` source, while the remote branch does three separate `try { Invoke-WebRequest ... } catch { Write-Host ... }` one-liners. The remote branch is three trivial helper calls away from consolidation. Prefer Option (a): refactor the `hook-handle-use` remote branch into three `Install-HelperScript` calls with the outer `Test-Path` gate left intact (smaller, safer than generalising the helper to accept a list of triples). Keep behaviour-preserving — Pester suite must remain green with identical assertion count.

### Card 2: Stop defaulting refactor card template lifecycle-gate boxes to [x]
Sprint: TTSNATIVE
Files touched:
- .gitban card template for refactor cards (locate via `mcp__gitban__list_templates` / `mcp__gitban__read_template`)
Items:
- L2: The refactor card template ships Completion Checklist entries like `[x] Refactored code validated on a real Windows host via manual install smoke test` and `[x] Production deployment successful via normal release flow` pre-ticked. These describe lifecycle stages the executor cannot complete from within a worktree, creating a low-grade Gate 1 trap (ticked-but-not-done boxes). Suggested fix: default those rows to `[ ]` with an inline comment like `# ticked by release runbook, not by executor`, so the card-author must consciously either check them or leave them for the release flow. This is a template-level change, not a per-card fix.

### Card 3: Dispatcher should pass final-work commit hash (or both) to reviewer
Sprint: TTSNATIVE
Files touched:
- .claude/skills/dispatcher/ (dispatcher skill / orchestration code)
- possibly .claude/skills/reviewer/ prose if the contract is documented there
Items:
- L3: Dispatcher passed `d9a988f` as the commit hash for card xuloxu, but that is the profiling-log-only follow-up commit; the substantive refactor lived at `2d5faf3`. The reviewer had to walk the log to find the diff of interest. Dispatcher should pass the final-work commit (the HEAD at review time for the card's feature branch) or explicitly pass both the work commit and any trailing log/metadata commits. Minor orchestration polish that improves reviewer efficiency across all future cards.
