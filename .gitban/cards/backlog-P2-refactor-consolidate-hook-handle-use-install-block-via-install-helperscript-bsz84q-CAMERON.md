
# Consolidate hook-handle-use install block via Install-HelperScript

**Type:** refactor | **Tier:** standalone tech-debt (follow-on to `xuloxu`)

## Refactoring Overview & Motivation

* **Refactoring Target:** The `hook-handle-use.ps1` / `hook-handle-use.sh` / `notify.sh` install block in `install.ps1` (lines ~336-367), immediately below the three refactored call-sites that `xuloxu` converted to `Install-HelperScript` calls.
* **Code Location:** `install.ps1` lines ~336-367.
* **Refactoring Type:** Extract Method (extension) — consolidate the remote-branch's three `try { Invoke-WebRequest ... } catch { Write-Host ... }` one-liners into three `Install-HelperScript` calls. The local branch's three `Copy-Item` calls already fit the helper's contract.
* **Motivation:** `xuloxu` landed `Install-HelperScript` and converted three copy-or-download call-sites above this block. The `hook-handle-use` block carries a very similar copy-or-download shape but was not consolidated because its local branch uses a single `Test-Path` gate for three `Copy-Item` calls (rather than the per-script `Test-Path` that `Install-HelperScript` assumes). Reviewer-1 on `xuloxu` flagged it as three trivial helper calls away from consolidation.
* **Business Impact:** Eliminates the last copy-or-download duplication in `install.ps1` so future adapter installs have a single idiomatic path. Shrinks the surface area that must stay consistent across all six helper scripts that this installer lays down.
* **Scope:** One file (`install.ps1`, ~30 lines consolidated to ~15 lines). Possibly one Pester test file (`tests/adapters-windows.Tests.ps1` or equivalent) if the existing structural assertions need the same trivial updates `xuloxu` made for the first three helpers.
* **Risk Level:** Low — behaviour-preserving refactor, covered by existing structural Pester tests.
* **Related Work:** Generated from reviewer-1 finding L1 on `xuloxu` (step 4c of TTSNATIVE). The originating card landed `Install-HelperScript` and the first three call-sites; this card extends the pattern to the adjacent `hook-handle-use` block.

**Required Checks:**
- [x] **Refactoring motivation** clearly explains why this change is needed.
- [x] **Scope** is specific and bounded (not open-ended "improve everything").
- [x] **Risk level** is assessed based on code criticality and usage.

---

## Pre-Refactoring Context Review

- [ ] Existing code reviewed and behavior fully understood (`install.ps1` lines ~336-367 — the `hook-handle-use` + `notify.sh` install block).
- [ ] Test coverage reviewed — structural Pester assertions for `hook-handle-use.ps1`, `hook-handle-use.sh`, `notify.sh` in `tests/adapters-windows.Tests.ps1` (same pattern xuloxu updated for `win-play.ps1`, `win-notify.ps1`, `tts-native.ps1`).
- [ ] Documentation reviewed — inline comments around the install block.
- [ ] Style guide reviewed — match the existing `Install-HelperScript` call-site style from xuloxu (named params, backtick line-continuation).
- [ ] Dependencies reviewed — callers are only inside `install.ps1`.
- [ ] Usage patterns reviewed — the `Test-Path` outer gate currently branches on whether ANY one of the three local sources exists; the helper's per-script `Test-Path` would be equivalent if all three are present in a repo checkout.
- [ ] Previous refactoring attempts reviewed — `xuloxu` introduced the helper.

| Review Source | Link / Location | Key Findings / Constraints |
| :--- | :--- | :--- |
| **Existing Code** | `install.ps1` lines ~336-367 | Single outer `Test-Path $hookHandleUsePs1Source` gate chooses copy-vs-download for all three scripts. Helper assumes per-script `Test-Path`. |
| **Test Coverage** | `tests/adapters-windows.Tests.ps1` | Same structural pattern xuloxu updated: file exists at `$installDir/<name>`, no `ExecutionPolicy Bypass` string. Assertion count must stay identical. |
| **Documentation** | `install.ps1` inline comments | Comment `# Install hook-handle-use scripts (for /peon-ping-use command)` should be preserved at the first of the three call-sites. |
| **Style Guide** | `xuloxu` refactored call-sites (lines ~316-334) | Match the same named-param + backtick style. |
| **Dependencies** | Callers inside `install.ps1` | Sequential flow, no concurrency concerns. |
| **Usage Patterns** | Install flow | Each helper is optional — failure warns, doesn't throw. `Install-HelperScript` already preserves this. |
| **Previous Attempts** | `xuloxu` | First three helpers consolidated. This card extends. |

---

## Refactoring Strategy & Risk Assessment

**Refactoring Approach:**
* Option (a) — **preferred**: Refactor the `hook-handle-use` remote branch into three `Install-HelperScript` calls with the outer `Test-Path` gate left intact. Smaller, safer than generalising the helper to accept a list of triples.
* Option (b) — **rejected**: Generalise `Install-HelperScript` to accept an array of `@{Name; LocalSource; RemoteUrl}` hashtables. Larger API change, adds complexity that only benefits this one callsite, and risks regressing the three xuloxu call-sites that are already landed and reviewed.

**Incremental Steps:**
1. Verify the existing Pester structural assertions for `hook-handle-use.ps1`, `hook-handle-use.sh`, `notify.sh` match the pattern xuloxu adapted for the first three helpers. Expected: same assertion shape.
2. Replace the three remote-branch `try { Invoke-WebRequest ... } catch { Write-Host ... }` blocks with three `Install-HelperScript` calls, keeping the outer `if (Test-Path $hookHandleUsePs1Source)` / `else` structure intact. The `if` branch keeps the three `Copy-Item` calls (they differ from the helper's copy path by not being `-Force`'d identically and by having a conditional on `notify.sh`).
3. Actually: both branches could be consolidated to three `Install-HelperScript` calls without the outer gate, because the helper's internal `Test-Path` on `LocalSource` already handles the local-vs-remote choice per-script. Prefer that shape if the Pester assertions stay green.
4. Update any Pester structural assertions if the refactor changes the installed-file layout (it shouldn't — behaviour-preserving).
5. Full Pester suite must remain green with identical assertion count.

**Risk Mitigation:**
* Risk: `notify.sh` is conditional (`if (Test-Path $notifyShSource)`) in the local branch only — not in the remote branch. Mitigation: inspect the remote-branch equivalent for `notify.sh`; if it is unconditional, the helper's per-script `Test-Path` resolves the discrepancy cleanly.
* Risk: Breaking the outer `Test-Path` gate semantic that says "if the ps1 source exists, assume all three are local". Mitigation: per-script `Test-Path` inside the helper is strictly safer — no regression possible.

**Rollback Plan:**
* Git revert. This is a single-file refactor with no state change.

**Success Criteria:**
* All `tests/adapters-windows.Tests.ps1` Pester tests pass with identical assertion count pre- and post-refactor.
* `install.ps1` lines ~336-367 replaced by three `Install-HelperScript` calls (~15 lines).
* No behavioural change — all six helpers land in `~/.local/bin/peon-ping/scripts/` on both local and one-liner install paths.

---

## Refactoring Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Pre-Refactor Test Suite** | Existing structural Pester assertions for `hook-handle-use.ps1`, `hook-handle-use.sh`, `notify.sh`. | - [ ] Comprehensive tests exist before refactoring starts. |
| **Baseline Measurements** | Pester assertion count pre-refactor (run `Invoke-Pester -Path tests/adapters-windows.Tests.ps1` and note the `Passed` count). | - [ ] Baseline metrics captured. |
| **Incremental Refactoring** | Three `Install-HelperScript` calls replace the `if/else` block. | - [ ] Refactoring implemented incrementally. |
| **Documentation Updates** | Inline `# Install hook-handle-use scripts` comment preserved; no external docs touched. | - [ ] Documentation updated. |
| **Code Review** | Gitban reviewer. | - [ ] Code reviewed. |
| **Performance Validation** | n/a — install-time only. | - [ ] Performance validated. |
| **Staging Deployment** | Manual smoke test: fresh `install.ps1 -Packs peon` on Windows, verify all six helpers land. | - [ ] Refactored code validated in staging environment. |
| **Production Deployment** | Ticked by release runbook, not by executor. | - [ ] Production deployment successful. |

---

## Safe Refactoring Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Establish Test Safety Net** | Existing Pester structural assertions cover all three target scripts. | - [ ] Comprehensive tests exist covering current behavior. |
| **2. Run Baseline Tests** | `Invoke-Pester -Path tests/adapters-windows.Tests.ps1` pre-refactor. | - [ ] All tests pass before any refactoring begins. |
| **3. Capture Baseline Metrics** | Pester `Passed`/`Failed`/`Skipped` counts. | - [ ] Baseline metrics captured. |
| **4. Make Smallest Refactor** | Replace the `hook-handle-use` block with three `Install-HelperScript` calls. | - [ ] Smallest possible refactoring change made. |
| **5. Run Tests (Iteration)** | Pester post-refactor; assertion count must be identical. | - [ ] All tests pass after refactoring change. |
| **6. Commit Incremental Change** | One commit: `refactor(install.ps1): consolidate hook-handle-use install via Install-HelperScript`. | - [ ] Incremental change committed. |
| **7. Repeat Steps 4-6** | Single-step refactor; no further iteration. | - [ ] All incremental refactoring steps completed. |
| **8. Update Documentation** | Inline comment preserved; no external docs. | - [ ] All documentation updated. |
| **9. Style & Linting Check** | PowerShell syntax check (`Test-Path`, param style). | - [ ] Code passes linting. |
| **10. Code Review** | Gitban reviewer flow. | - [ ] Changes reviewed. |
| **11. Performance Validation** | n/a. | - [ ] Performance validated. |
| **12. Deploy to Staging** | Manual smoke test on real Windows install. | - [ ] Refactored code validated in staging environment. |
| **13. Production Deployment** | Release runbook. | - [ ] Gradual production rollout. |

#### Refactoring Implementation Notes

**Refactoring Techniques Applied:**
* Extract Method (extension) — apply `Install-HelperScript` to three additional call-sites.

**Design Patterns Introduced:**
* None new — extends the helper introduced by `xuloxu`.

**Code Quality Improvements:**
* `install.ps1` lines ~336-367 (~30 lines) collapsed to three named-param helper calls (~15 lines).
* Eliminates the last copy-or-download duplication in `install.ps1`.

**Before/After Comparison:**
```powershell
# Before (install.ps1 ~336-367)
if (Test-Path $hookHandleUsePs1Source) {
    Copy-Item -Path $hookHandleUsePs1Source -Destination $hookHandleUsePs1Target -Force
    Copy-Item -Path $hookHandleUseShSource -Destination $hookHandleUseShTarget -Force
    $notifyShSource = Join-Path $ScriptDir "scripts\notify.sh"
    if (Test-Path $notifyShSource) {
        Copy-Item -Path $notifyShSource -Destination (Join-Path $scriptsDir "notify.sh") -Force
    }
} else {
    try { Invoke-WebRequest -Uri "$RepoBase/scripts/hook-handle-use.ps1" -OutFile $hookHandleUsePs1Target -UseBasicParsing -ErrorAction Stop }
    catch { Write-Host "  Warning: Could not download hook-handle-use.ps1" -ForegroundColor Yellow }
    # ...two more identical try/catch blocks...
}

# After
Install-HelperScript -Name 'hook-handle-use.ps1' `
    -LocalSource (Join-Path $ScriptDir "scripts\hook-handle-use.ps1") `
    -RemoteUrl   "$RepoBase/scripts/hook-handle-use.ps1" `
    -DestDir     $scriptsDir

Install-HelperScript -Name 'hook-handle-use.sh' `
    -LocalSource (Join-Path $ScriptDir "scripts\hook-handle-use.sh") `
    -RemoteUrl   "$RepoBase/scripts/hook-handle-use.sh" `
    -DestDir     $scriptsDir

Install-HelperScript -Name 'notify.sh' `
    -LocalSource (Join-Path $ScriptDir "scripts\notify.sh") `
    -RemoteUrl   "$RepoBase/scripts/notify.sh" `
    -DestDir     $scriptsDir
```

---

## Refactoring Validation & Completion

| Task | Detail/Link |
| :--- | :--- |
| **Code Location** | `install.ps1` lines ~336-367 (refactored), `tests/adapters-windows.Tests.ps1` (assertions preserved). |
| **Test Suite** | Pester green, identical assertion count pre/post. |
| **Baseline Metrics (Before)** | 30-line `if/else` copy-or-download block. |
| **Final Metrics (After)** | Three `Install-HelperScript` calls, ~15 lines. |
| **Performance Validation** | n/a — install-time only. |
| **Style & Linting** | PowerShell syntax check passes. |
| **Code Review** | Gitban reviewer flow. |
| **Documentation Updates** | Inline comment preserved; no external docs touched. |
| **Staging Validation** | Manual smoke test on real Windows host. |
| **Production Deployment** | Release runbook. |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Further Refactoring Needed?** | No — `install.ps1` copy-or-download duplication fully eliminated after this card. |
| **Design Patterns Reusable?** | `Install-HelperScript` is now the idiomatic install path for any future helper. |
| **Test Suite Improvements?** | n/a — existing structural assertions are sufficient. |
| **Documentation Complete?** | Inline comment preserved. |
| **Performance Impact?** | n/a. |
| **Team Knowledge Sharing?** | n/a — solo maintainer. |
| **Technical Debt Reduced?** | Yes — last install.ps1 copy-or-download duplication gone. |
| **Code Quality Metrics Improved?** | Line count reduced, single idiomatic helper path. |

### Completion Checklist

- [ ] Comprehensive tests exist before refactoring (existing Pester structural assertions).
- [ ] All tests pass before refactoring begins (Pester baseline captured).
- [ ] Baseline metrics captured (Pester assertion count).
- [ ] Refactoring implemented incrementally (single commit).
- [ ] All tests pass after each refactoring step (Pester green post-refactor, identical assertion count).
- [ ] Documentation updated (inline comment preserved).
- [ ] Code passes style guide validation (PowerShell syntax).
- [ ] Code reviewed by at least 2 team members (gitban reviewer; solo project — reviewer agent is the second reviewer).
- [ ] No performance regression (install-time only).
- [ ] Refactored code validated in staging environment (manual smoke test on real Windows host).
- [ ] Production deployment successful with monitoring (ticked by release runbook, not by executor).
- [ ] Code quality metrics improved (line count reduced).
- [ ] Rollback plan documented and tested (git revert).

---

## Notes

Source: reviewer-1 finding L1 on `xuloxu`. Router inbox: `.gitban/agents/planner/inbox/TTSNATIVE-xuloxu-planner-1.md`.

Routed to backlog (not TTSNATIVE sprint) per explicit user guidance: the TTSNATIVE sprint is near closeout (only `gvleuv` remains) and this is cross-cutting install.ps1 hygiene that doesn't need to block closeout. Pick up post-sprint.
