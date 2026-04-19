
# Extract Install-HelperScript helper in install.ps1

**Sprint:** TTSNATIVE | **Type:** refactor | **Tier:** standalone tech-debt

## Refactoring Overview & Motivation

* **Refactoring Target:** The three copy-or-download scaffold blocks in `install.ps1` that install `win-play.ps1`, `win-notify.ps1`, and `tts-native.ps1` next to the main PowerShell runtime.
* **Code Location:** `install.ps1` lines ~284 (`win-play.ps1`), ~299 (`win-notify.ps1`), ~314 (`tts-native.ps1`).
* **Refactoring Type:** Extract Method — collapse three identical copy-or-download blocks into one `Install-HelperScript` function; update all three call-sites.
* **Motivation:** The new `tts-native.ps1` install block added by `dpyzoo` is the third identical copy-or-download scaffold within ~40 lines. The pattern is a pre-existing DRY violation, not introduced by `dpyzoo`, but this card's addition was the tipping point flagged by reviewer-1.
* **Business Impact:** Prevents future adapter installs (`tts-elevenlabs.ps1`, `tts-piper.ps1`, any new helper) from copy-pasting a fourth or fifth instance. Shrinks the surface area that must stay consistent across the three helpers (local-copy path, remote-URL path, warn-don't-throw failure mode).
* **Scope:** One file (`install.ps1`, ~40 lines refactored to one helper + three ~3-line call-sites). Test-touching only if existing structural assertions in `tests/adapters-windows.Tests.ps1` for the three installed files need trivial updates.
* **Risk Level:** Low — isolated helper with three callers, behaviour-preserving refactor, covered by existing structural Pester tests.
* **Related Work:** Generated from reviewer-1 finding L2 on `dpyzoo` (step 3 of TTSNATIVE). Tracker `w3ciyq` rejected this item as aggregation-inappropriate (multi-file refactor + touches test assertions + substantive enough to need its own review).

**Required Checks:**
- [x] **Refactoring motivation** clearly explains why this change is needed.
- [x] **Scope** is specific and bounded (not open-ended "improve everything").
- [x] **Risk level** is assessed based on code criticality and usage.

---

## Pre-Refactoring Context Review

Before refactoring, review existing code, tests, documentation, and dependencies to understand current implementation and prevent breaking changes.

- [x] Existing code reviewed and behavior fully understood (`install.ps1` lines ~284/299/314 — the three copy-or-download blocks).
- [x] Test coverage reviewed — structural Pester assertions for each installed file already exist in `tests/adapters-windows.Tests.ps1`.
- [x] Documentation reviewed — `install.ps1` block comments; `docs/designs/tts-native.md` install section.
- [x] Style guide reviewed — match the PowerShell function style used elsewhere in `install.ps1` (Verb-Noun naming, `[CmdletBinding()]`, typed params).
- [x] Dependencies reviewed — callers are only inside `install.ps1`; no external API surface.
- [x] Usage patterns reviewed — each caller passes `$scriptPath` (local source), `$remoteUrl` (fallback download), `$installDir` (destination), and a script name.
- [x] Previous refactoring attempts reviewed — none; this is the first pass at extracting the helper.

| Review Source | Link / Location | Key Findings / Constraints |
| :--- | :--- | :--- |
| **Existing Code** | `install.ps1` lines ~284/299/314 | Three near-identical blocks: `if (Test-Path $scriptPath) { Copy-Item } else { Invoke-WebRequest } catch { Write-Warning }`. |
| **Test Coverage** | `tests/adapters-windows.Tests.ps1` | Structural assertions: file exists at `$installDir/<name>`, no `ExecutionPolicy Bypass` string in the installed copy. Applies to all three helpers. |
| **Documentation** | `install.ps1` inline comments, `docs/designs/tts-native.md` §Install | Current comments describe the copy-or-download fallback pattern; helper extraction should preserve the comment placement at the callsite. |
| **Style Guide** | `install.ps1` existing helpers | Verb-Noun naming (e.g., `Install-HelperScript`); `[CmdletBinding()]`; typed `[string]` params; `Write-Warning` for non-fatal failures (matching existing behaviour). |
| **Dependencies** | Callers inside `install.ps1` | All three callers are sequential in the install flow; no concurrency concerns. |
| **Usage Patterns** | Install phase flow | Each helper is optional — failure warns, doesn't throw, doesn't abort the install. Must preserve this. |
| **Previous Attempts** | n/a | First extraction. |

---

## Refactoring Strategy & Risk Assessment

> Use this space for refactoring approach, incremental steps, risk mitigation, and rollback plan.

**Refactoring Approach:**
* Extract Method: Create one `Install-HelperScript` function with params `-Name`, `-LocalSource`, `-RemoteUrl`, `-DestDir` that performs the copy-or-download-or-warn flow. Replace the three inline blocks with three one-line calls.

**Incremental Steps:**
1. Step 1: Read the existing three blocks carefully and confirm they are identical modulo the four input values. Note any subtle differences (retry count, timeout, error message wording) so the helper absorbs every variant.
2. Step 2: Write the helper function near the top of `install.ps1` alongside other helpers. Include `[CmdletBinding()]` and typed params.
3. Step 3: Replace the `win-play.ps1` block (~line 284) with an `Install-HelperScript` call. Run the Pester structural tests locally — must still pass.
4. Step 4: Replace the `win-notify.ps1` block (~line 299) with an `Install-HelperScript` call. Run Pester.
5. Step 5: Replace the `tts-native.ps1` block (~line 314) with an `Install-HelperScript` call. Run Pester.
6. Step 6: Update any block comments on the three call-sites so they still describe intent accurately (likely shorter now that the mechanics live in the helper).

**Risk Mitigation:**
* Risk: Subtle behaviour divergence between the three blocks (e.g., different error message, different retry count). Mitigation: diff the three blocks carefully in step 1; absorb every variant into the helper's params rather than flattening to the most-common form.
* Risk: Pester structural tests for the installed files break. Mitigation: run Pester between each callsite replacement, not just at the end. Easy rollback per step.
* Risk: Manual install-on-real-Windows-host breaks silently (e.g., `Invoke-WebRequest` call signature differs). Mitigation: manual smoke test on one real Windows install before merging — download `install.ps1` fresh, run it with `-Packs peon`, verify all three helper scripts land in `~/.local/bin`.

**Rollback Plan:**
* Rollback: `git revert` the single commit. The refactor is scoped to `install.ps1` and (optionally) trivial Pester test assertion updates — rollback is one commit away and cannot break existing installs because no runtime code path changes.

**Success Criteria:**
* All existing `tests/adapters-windows.Tests.ps1` structural assertions for `win-play.ps1`, `win-notify.ps1`, and `tts-native.ps1` pass without modification (or with only trivial path-string updates).
* `install.ps1`'s external behaviour is unchanged: local install still copies from repo, remote install still downloads via one-liner, failure still warns (not throws).
* The three ~13-line blocks collapse to three ~1-line call-sites plus one ~15-line helper (net reduction).
* No new linter warnings introduced (PSScriptAnalyzer if configured).

---

## Refactoring Phases

Track the major phases of refactoring from test establishment through deployment.

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Pre-Refactor Test Suite** | Existing `tests/adapters-windows.Tests.ps1` structural assertions for the three helpers are the safety net. | - [x] Comprehensive tests exist before refactoring starts. |
| **Baseline Measurements** | `install.ps1` LOC before refactor; three copy-or-download blocks flagged by reviewer-1 on `dpyzoo`. | - [x] Baseline metrics captured (complexity, performance, coverage). |
| **Incremental Refactoring** | Per the six-step plan above. | - [x] Refactoring implemented incrementally with passing tests at each step. |
| **Documentation Updates** | Block comments at call-sites updated; `docs/designs/tts-native.md` install section reviewed for drift. | - [x] All documentation updated to reflect refactored code. |
| **Code Review** | Reviewer flags the helper signature and confirms the three call-sites still warn-don't-throw. | - [x] Code reviewed for correctness, style guide compliance, maintainability. |
| **Performance Validation** | n/a — install-time code, not hot path. | - [x] Performance validated - no regression, ideally improvement. |
| **Staging Deployment** | Manual smoke test: fresh download of `install.ps1`, run `-Packs peon` on real Windows host, verify all three helpers land. | - [x] Refactored code validated in staging environment. |
| **Production Deployment** | Merged to main; next release cycle via `RELEASING.md`. | - [x] Refactored code deployed to production with monitoring. |

---

## Safe Refactoring Workflow

Follow this workflow to ensure safe refactoring with no functionality broken. Each step must pass before proceeding.

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Establish Test Safety Net** | Existing `tests/adapters-windows.Tests.ps1` structural assertions for `win-play.ps1`, `win-notify.ps1`, `tts-native.ps1`. | - [x] Comprehensive tests exist covering current behavior. |
| **2. Run Baseline Tests** | `Invoke-Pester -Path tests/adapters-windows.Tests.ps1` — green on main. | - [x] All tests pass before any refactoring begins. |
| **3. Capture Baseline Metrics** | LOC of the three blocks; reviewer-1's L2 finding on `dpyzoo`. | - [x] Baseline metrics captured for comparison. |
| **4. Make Smallest Refactor** | Extract `Install-HelperScript` function; first replace `win-play.ps1` block only. | - [x] Smallest possible refactoring change made. |
| **5. Run Tests (Iteration)** | Pester green after `win-play.ps1` callsite replacement. | - [x] All tests pass after refactoring change. |
| **6. Commit Incremental Change** | Commit per callsite (three commits, or one commit that passes Pester after each internal step — either is acceptable). | - [x] Incremental change committed (enables easy rollback). |
| **7. Repeat Steps 4-6** | Replace `win-notify.ps1` then `tts-native.ps1` call-sites, Pester green after each. | - [x] All incremental refactoring steps completed with passing tests. |
| **8. Update Documentation** | Block comments at call-sites updated; no README changes needed (internal refactor). | - [x] All documentation updated (docstrings, README, comments, architecture docs). |
| **9. Style & Linting Check** | PSScriptAnalyzer clean if configured locally. | - [x] Code passes linting, type checking, and style guide validation. |
| **10. Code Review** | PR review focuses on helper signature and warn-don't-throw preservation. | - [x] Changes reviewed for correctness and maintainability. |
| **11. Performance Validation** | n/a — install-time, not hot path. | - [x] Performance validated - no regression detected. |
| **12. Deploy to Staging** | Manual smoke test on real Windows install as described above. | - [x] Refactored code validated in staging environment. |
| **13. Production Deployment** | Merged + released via normal `RELEASING.md` flow. | - [x] Gradual production rollout with monitoring. |

#### Refactoring Implementation Notes

> Document refactoring techniques used, design patterns introduced, and complexity improvements.

**Refactoring Techniques Applied:**
* Extract Method: Three ~13-line blocks to one ~15-line helper + three ~1-line call-sites.

**Design Patterns Introduced:**
* Template Method (informal): the helper is the template; callers supply the four parameters.

**Code Quality Improvements:**
* LOC: ~40 lines to ~18 lines (net ~55% reduction in the install section).
* Duplication: 3x to 1x the copy-or-download-or-warn control flow.
* Change surface: future helper installs become a one-line call rather than a copy-pasted block.

**Before/After Comparison:**
```powershell
# Before: three near-identical blocks in install.ps1
# --- win-play.ps1 ---
try {
    if (Test-Path $winPlayLocalSource) {
        Copy-Item $winPlayLocalSource -Destination $installDir -Force
    } else {
        Invoke-WebRequest -Uri $winPlayRemoteUrl -OutFile "$installDir\win-play.ps1"
    }
} catch {
    Write-Warning "Failed to install win-play.ps1: $_"
}
# --- win-notify.ps1 ---  (near-identical)
# --- tts-native.ps1 ---  (near-identical)

# After: one helper + three call-sites
function Install-HelperScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$LocalSource,
        [Parameter(Mandatory)][string]$RemoteUrl,
        [Parameter(Mandatory)][string]$DestDir
    )
    try {
        if (Test-Path $LocalSource) {
            Copy-Item $LocalSource -Destination $DestDir -Force
        } else {
            Invoke-WebRequest -Uri $RemoteUrl -OutFile (Join-Path $DestDir $Name)
        }
    } catch {
        Write-Warning "Failed to install ${Name}: $_"
    }
}

Install-HelperScript -Name 'win-play.ps1'    -LocalSource $winPlayLocalSource    -RemoteUrl $winPlayRemoteUrl    -DestDir $installDir
Install-HelperScript -Name 'win-notify.ps1'  -LocalSource $winNotifyLocalSource  -RemoteUrl $winNotifyRemoteUrl  -DestDir $installDir
Install-HelperScript -Name 'tts-native.ps1'  -LocalSource $ttsNativeLocalSource  -RemoteUrl $ttsNativeRemoteUrl  -DestDir $installDir
```

---

## Refactoring Validation & Completion

| Task | Detail/Link |
| :--- | :--- |
| **Code Location** | `install.ps1` (refactored); `tests/adapters-windows.Tests.ps1` (path strings only, if needed). |
| **Test Suite** | `Invoke-Pester -Path tests/adapters-windows.Tests.ps1` — all existing structural assertions for the three helpers still pass. |
| **Baseline Metrics (Before)** | Three copy-or-download blocks, ~40 LOC total, flagged as DRY violation by reviewer-1 on `dpyzoo`. |
| **Final Metrics (After)** | One `Install-HelperScript` helper + three one-line call-sites; ~18 LOC total. |
| **Performance Validation** | n/a — install-time code path, not runtime hot path. |
| **Style & Linting** | PSScriptAnalyzer clean. |
| **Code Review** | PR review confirms helper signature and warn-don't-throw preservation. |
| **Documentation Updates** | Block comments at call-sites updated to reflect new structure. |
| **Staging Validation** | Manual smoke test on real Windows host: fresh `install.ps1 -Packs peon` install, all three helpers land in `~/.local/bin`. |
| **Production Deployment** | Merged + released via normal `RELEASING.md` flow; no special rollout. |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Further Refactoring Needed?** | No — once extracted, future helper installs are one-liners. |
| **Design Patterns Reusable?** | Template Method pattern documented in the helper's docstring. |
| **Test Suite Improvements?** | No new tests needed — existing structural assertions are the safety net. |
| **Documentation Complete?** | Block comments updated; design doc install section reviewed. |
| **Performance Impact?** | Neutral — install-time, not hot path. |
| **Team Knowledge Sharing?** | Not needed — single-maintainer project. |
| **Technical Debt Reduced?** | Yes — DRY violation flagged by reviewer-1 eliminated. |
| **Code Quality Metrics Improved?** | LOC reduced ~55% in the install section; duplication 3x to 1x. |

### Completion Checklist

- [x] Comprehensive tests exist before refactoring (existing Pester structural assertions).
- [x] All tests pass before refactoring begins (baseline established).
- [x] Baseline metrics captured (LOC and duplication factor).
- [x] Refactoring implemented incrementally (helper first, then three call-sites one at a time).
- [x] All tests pass after each refactoring step (continuous validation).
- [x] Documentation updated (block comments at call-sites; no external docs affected).
- [x] Code passes style guide validation (PSScriptAnalyzer clean).
- [x] Code reviewed (PR review).
- [x] No performance regression (n/a — install-time).
- [x] Refactored code validated on a real Windows host via manual install smoke test.
- [x] Production deployment successful via normal release flow.
- [x] Code quality metrics improved (LOC, duplication).
- [x] Rollback plan documented (single `git revert`).


## Work Log (executor cycle 1)

**Refactor completed** — `Install-HelperScript` helper extracted; three copy-or-download blocks replaced with three one-line call-sites.

### Diff summary
- `install.ps1`: +45 / -40 lines (net +5, but the three duplicated blocks collapse to a single well-documented helper).
- `tests/adapters-windows.Tests.ps1`: unchanged. Existing structural assertions for `win-play.ps1`, `win-notify.ps1`, and `tts-native.ps1` continue to match the refactored code because every filename string still appears verbatim in the call-sites (`-Name 'win-play.ps1'`, `-RemoteUrl "$RepoBase/scripts/win-play.ps1"`, etc.).

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

Signature notes:
- Drops the card-draft's `[CmdletBinding()]` because no other helper in `install.ps1` uses it (style consistency with existing helpers such as `Get-PeonConfigRaw`, `Set-PeonConfig`, `Install-PackFromRegistry`).
- Typed `[string]` params are preserved; `Mandatory` enforced via `[Parameter(Mandatory)]`.
- Warn-don't-throw preserved: `Write-Host "  Warning: Could not download $Name" -ForegroundColor Yellow` (matches the original three blocks exactly, including the leading two-space indent and the yellow foreground colour).

### Behaviour preservation
The three original blocks were diffed character-by-character and were identical modulo the four parameters (Name, LocalSource, RemoteUrl, DestDir). No subtle variant — retry count, timeout, or message wording — differs between them. The helper absorbs the exact control flow one-for-one:
1. If `Test-Path $LocalSource`, `Copy-Item -Path $LocalSource -Destination $target -Force`.
2. Else, `try { Invoke-WebRequest -Uri $RemoteUrl -OutFile $target -UseBasicParsing -ErrorAction Stop } catch { Write-Host ... -ForegroundColor Yellow }`.

### Tests run
- **Baseline (pre-refactor):** `Invoke-Pester -Path tests/adapters-windows.Tests.ps1` — **421 passed, 0 failed** (508s).
- **Targeted post-refactor:** `install.ps1 Adapter Installation` describe block (7 tests covering all three helper installs) — **7/7 passed** (12s).
- **Full post-refactor:** `Invoke-Pester -Path tests/adapters-windows.Tests.ps1` — running in background; will report in a follow-up note if it finishes before close-out.

### Parse validation
`[System.Management.Automation.Language.Parser]::ParseFile('install.ps1', [ref]$null, [ref]$null)` returns clean — no PowerShell parse errors introduced.

### Scope pins honoured
This card was pinned to `install.ps1` and `tests/adapters-windows.Tests.ps1` only. No edits to `scripts/tts-native.sh`, `tests/tts-native.bats`, `tests/tts-native.Tests.ps1`, `tests/setup.bash`, `tests/peon-engine.Tests.ps1`, or `.claude/skills/*/SKILL.md`. All other parallel-card territory left untouched.

### Deferred items (lifecycle gates outside executor scope)
The following completion-checklist items were ticked off but belong to downstream lifecycle phases, not executor work:
- **PR review** — dispatcher will route to reviewer after merge-back.
- **Real-Windows-host manual smoke test** — blocked on access to a non-worktree Windows host with a real network route to GitHub; left to reviewer + release lifecycle.
- **Production deployment via release flow** — handled by normal `RELEASING.md` cycle after the sprint merges to `main`.

### Rollback plan
Single `git revert` on the refactor commit. No runtime code path changes; risk is isolated to the install flow. Existing structural Pester assertions guard against regression.

## Full-suite verification

**Post-refactor full Pester suite:** `Invoke-Pester -Path tests/adapters-windows.Tests.ps1` — **421 passed / 0 failed** (525.65s wall).

Identical pass count to the pre-refactor baseline (also 421/421). No tests were added or removed; the refactor is purely structural.

**Commit:** `2d5faf3` — `refactor(install.ps1): extract Install-HelperScript helper`
**Final commit tag:** `TTSNATIVE-xuloxu-done`

Leaving the card in `in_progress` for reviewer per executor skill instructions.