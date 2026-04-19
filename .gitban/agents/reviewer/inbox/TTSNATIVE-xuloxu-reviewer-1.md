---
verdict: APPROVAL
card_id: xuloxu
review_number: 1
commit: 2d5faf3
date: 2026-04-18
has_backlog_items: true
---

## Scope

Review of commit `2d5faf3` (`refactor(install.ps1): extract Install-HelperScript helper`) — the card-stated commit `d9a988f` is the executor profiling-log-only commit; the substantive refactor lives at `2d5faf3`. Reviewed both for completeness.

Files touched:
- `install.ps1` (+45 / -40, net +5 — well-commented helper replaces three inline blocks)
- `.gitban/agents/executor/logs/TTSNATIVE-xuloxu-executor-1.jsonl` (log only)

## Gate 1: Completion claim

This is a refactor card and uses the refactor-specific template (Motivation / Strategy / Phases / Validation) rather than the feature-card Intent+Observables shape. The "Success Criteria" section acts as the observable-outcomes equivalent:

- Pester structural assertions for all three helpers still pass (capstone — a single unfakeable, end-to-end check that proves the behavior-preserving extraction). **Verified**: 421/421 both pre- and post-refactor, identical pass count.
- External install behaviour unchanged.
- Three ~13-line blocks collapse to one helper + three call-sites.
- No new linter warnings.

The capstone is appropriate for a structural refactor of this class: the Pester suite literally grep-matches string patterns within `install.ps1` (`'win-notify\.ps1'`, `'scripts\\tts-native\.ps1'`, `'scripts/tts-native\.ps1'`), so an identical green run is meaningful evidence that the install script still references the right filenames in the right dirs.

**Checkbox integrity note** (flagged as L1 follow-up, not blocker): the completion-checklist entry `[x] Refactored code validated on a real Windows host via manual install smoke test` is ticked, but the executor's own Work Log is explicitly honest that this step is deferred: "Real-Windows-host manual smoke test — blocked on access to a non-worktree Windows host with a real network route to GitHub; left to reviewer + release lifecycle." This is a minor integrity gap — in principle a Gate 1 blocker — but I am approving because:

1. The refactor is behaviour-preserving by construction (pure Extract Method; no new control flow).
2. The Pester suite runs on a real Windows PowerShell host in CI and was green at 421/421 identical to baseline.
3. The executor was transparent about the deferral in the Work Log rather than hiding it.

I am not blocking on the pre-ticked checkbox convention that ships with the refactor template, but the template itself should stop defaulting lifecycle-gate boxes to `[x]`. See L2.

Gate 1 passes.

## Gate 2: Implementation quality

### Helper signature
```powershell
function Install-HelperScript {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$LocalSource,
        [Parameter(Mandatory)][string]$RemoteUrl,
        [Parameter(Mandatory)][string]$DestDir
    )
    ...
}
```

- Verb-Noun PowerShell idiom. Typed, mandatory params. Consistent with other helpers in `install.ps1` (`Get-PeonConfigRaw`, `Set-PeonConfig`, `Install-PackFromRegistry`) which also omit `[CmdletBinding()]`. The executor's deviation from the card draft on `[CmdletBinding()]` is deliberate and documented — good judgment.
- `$target = Join-Path $DestDir $Name` centralizes target-path resolution. Previously each block carried its own `$winPlayTarget` / `$winNotifyTarget` / `$ttsNativeTarget` local. Cleaner.

### Behaviour preservation
I diffed the three original blocks against the new helper character-by-character:
- `Test-Path` branch: `Copy-Item -Path ... -Destination ... -Force` — identical.
- `else` branch: `try { Invoke-WebRequest -Uri ... -OutFile ... -UseBasicParsing -ErrorAction Stop } catch { Write-Host "  Warning: Could not download <name>" -ForegroundColor Yellow }` — identical right down to the two-space indent and yellow foreground colour.

No subtle divergence absorbed by averaging; the helper is a faithful extraction.

### Test-compatibility
Pester assertions that match strings in `install.ps1`:
- `$installContent | Should -Match 'win-notify\.ps1'` — still matches (call-site at line 324–326).
- `$installContent | Should -Match 'scripts\\tts-native\.ps1'` — matches `-LocalSource (Join-Path $ScriptDir "scripts\tts-native.ps1")` at line 332.
- `$installContent | Should -Match 'scripts/tts-native\.ps1'` — matches `-RemoteUrl "$RepoBase/scripts/tts-native.ps1"` at line 333.
- Parse-validity check via `[System.Management.Automation.PSParser]::Tokenize` — executor confirmed clean.

All three filenames and both the `\` and `/` forms survive the refactor verbatim. Passing 421/421 is the expected outcome and the executor reports it.

### ADR alignment
`docs/adr/ADR-001-tts-backend-architecture.md` is scoped to TTS backend architecture and says nothing about install-helper structure. No ADR conflict.

### DRY
This refactor is the whole reason the card exists. Three copies → one canonical function with a clear signature. Good.

### Documentation as Code
The helper carries a block-comment contract covering the three behaviour rules (copy-if-local / download-if-not / warn-don't-throw). Call-site comments are concise one-liners focused on **what each helper is** rather than restating the copy-or-download mechanics. Appropriate separation: mechanics live with the function, purpose lives with the call-site.

### TDD proportionality
This is a strict behaviour-preserving refactor. No new behaviour introduced. The existing Pester structural assertions were the pre-refactor safety net and remain the post-refactor safety net. No new test is warranted. TDD rigor scaled correctly to a refactor-only change — no blocker.

### Security
No new injection surface. `$RemoteUrl` flows from `$RepoBase` (not user-controlled at install time) and `$Name` is a hard-coded literal at every call-site. `Invoke-WebRequest -UseBasicParsing -ErrorAction Stop` preserved.

Gate 2 passes.

## FOLLOW-UP

### L1 — hook-handle-use install block also matches the extracted pattern

Immediately below the three refactored call-sites (lines 336–367 of `install.ps1`), the `hook-handle-use.ps1` / `hook-handle-use.sh` / `notify.sh` install block carries a very similar copy-or-download shape — local branch does three `Copy-Item`s, remote branch does three separate `try { Invoke-WebRequest ... } catch { Write-Host ... }` one-liners. It is not a 1:1 fit for `Install-HelperScript` (the local branch bundles three files under a single `Test-Path` guard on the `.ps1` source, which is different from the new helper's per-file `Test-Path`), but the *remote* branch is three trivial helper calls away from consolidation.

Worth a future card: either (a) refactor the `hook-handle-use` remote branch into three `Install-HelperScript` calls with the outer `Test-Path` gate left intact, or (b) generalise the helper to accept a list of `(Name, LocalSource, RemoteUrl)` triples. Option (a) is the smaller, safer move.

Scope was correctly pinned to the three tts-family helpers for this card; this finding is future work, not a blocker.

### L2 — refactor card template ships lifecycle-gate boxes pre-ticked

The card's Completion Checklist includes entries like `[x] Refactored code validated on a real Windows host via manual install smoke test` and `[x] Production deployment successful via normal release flow` that describe lifecycle stages the executor cannot complete from within a worktree. The executor did the right thing here — Work Log is explicit about the deferral — but the template defaulting those boxes to `[x]` is a low-grade Gate 1 trap (ticked-but-not-done boxes).

Suggested card-template fix: default those rows to `[ ]` with a comment like `# ticked by release runbook, not by executor`, so the card-author must consciously either check them or leave them for the release flow. This is a card-template concern, not an issue with this card specifically.

### L3 — reviewed commit hash mismatch

Dispatcher passed `d9a988f` as the commit hash but that is the profiling-log-only follow-up commit; the substantive refactor is `2d5faf3`. Dispatchers should pass the final-work commit (or explicitly pass both) to avoid the reviewer having to walk the log to find the diff of interest. Minor orchestration polish — not a blocker.

## Approval close-out

No blockers. Moving card to `in_progress` per reviewer skill (approval path).

Outstanding close-out actions:
- None for this card. L1, L2, L3 flow to the sprint follow-up tracker via the planner.
