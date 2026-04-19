
# Fix peon-engine.Tests.ps1 timezone parsing failure

## Bug Overview & Context

* **Ticket/Issue ID:** Routed from reviewer-1 on `dpyzoo` (TTSNATIVE step 3) -- finding L4.
* **Affected Component/Service:** Windows Pester test harness (`tests/peon-engine.Tests.ps1`) and possibly the underlying harness module (`New-PeonTestEnvironment`) if the fix belongs in state-override datetime parsing rather than the test assertion.
* **Severity Level:** P1 -- silent time-bomb in the Windows Pester suite that fails intermittently depending on where the test runs (UTC CI agent vs. local developer in a non-UTC zone). Not production code, but it will confuse future executors.
* **Discovered By:** `dpyzoo` executor during broader regression sweep while implementing step 3 (Windows `tts-native.ps1`). Pre-existing defect, not introduced by that card.
* **Discovery Date:** 2026-04-18
* **Reporter:** reviewer-1 on `dpyzoo`

**Required Checks:**
* [ ] Ticket/Issue ID is linked above
* [ ] Component/Service is clearly identified
* [ ] Severity level is assigned based on impact

---

## Bug Description

### What's Broken

The `Harness: New-PeonTestEnvironment.accepts StateOverrides` Pester test (line ~112 of `tests/peon-engine.Tests.ps1`) compares two `[datetime]` values using `Should -Be`, but the LHS and RHS are parsed in different timezones. On a non-UTC host the comparison fails because `Should -Be` compares with timezone awareness.

### Expected Behavior

The test passes on any Windows host regardless of the local timezone. The state-override datetime round-trip is semantically timezone-stable: the value stored via `StateOverrides` comes back out equal to the value supplied.

### Actual Behavior

On a Windows host in a non-UTC timezone (e.g., `America/Denver` / UTC-07:00), the test fails with:

```
Expected 2025-12-31T17:00:00.0000000-07:00, but got 2026-01-01T00:00:00.0000000Z
```

The LHS `[datetime]"2026-01-01T00:00:00Z"` is parsed as a local `DateTime` in the developer's timezone (so `2025-12-31T17:00:00-07:00`), while the RHS round-trips through the harness as a UTC `DateTime` (`2026-01-01T00:00:00Z`). `Should -Be` compares with timezone awareness and the two values are not equal instances even though they refer to the same instant.

### Reproduction Rate

* [x] 100% -- Always reproduces on a non-UTC host.
* [ ] 75% - Usually reproduces
* [ ] 50% - Sometimes reproduces
* [ ] 25% - Rarely reproduces
* [ ] Cannot reproduce consistently

(Passes silently on UTC hosts, which is why the Windows CI agent -- if currently UTC -- has not caught it.)

---

## Steps to Reproduce

**Prerequisites:**
* Windows host set to a non-UTC timezone (e.g., `America/Denver`).
* PowerShell 5.1 or 7.x with Pester installed.
* Checkout of peon-ping `main`.

**Reproduction Steps:**

1. Confirm system timezone is non-UTC: `Get-TimeZone` shows `UTC-07:00` or similar.
2. Run `Invoke-Pester -Path tests/peon-engine.Tests.ps1 -TestName "Harness: New-PeonTestEnvironment.accepts StateOverrides"`.
3. Observe the failure shown above.

**Error Messages / Stack Traces:**

```
Expected 2025-12-31T17:00:00.0000000-07:00, but got 2026-01-01T00:00:00.0000000Z
```

---

## Environment Details

| Environment Aspect | Required | Value | Notes |
| :--- | :--- | :--- | :--- |
| **Environment** | Optional | Local developer workstation | Also reproducible on any non-UTC Windows CI agent. |
| **OS** | Optional | Windows 10/11 | Timezone-dependent, not OS-version-dependent. |
| **Browser** | Optional | n/a | n/a |
| **Application Version** | Optional | peon-ping `main` at the time of `dpyzoo`'s regression sweep | Pre-existing defect. |
| **Database Version** | Optional | n/a | n/a |
| **Runtime/Framework** | Optional | PowerShell 5.1 + Pester 5.x | Reproduces on PS 7.x as well. |
| **Dependencies** | Optional | Pester | `Should -Be` is the operator at issue. |
| **Infrastructure** | Optional | n/a | Local test harness only. |

---

## Impact Assessment

| Impact Category | Severity | Details |
| :--- | :--- | :--- |
| **User Impact** | None | Test harness only; not shipped to users. |
| **Business Impact** | Low | Wastes future executor time diagnosing a pre-existing silent failure. |
| **System Impact** | Low | Fails one Pester test on non-UTC hosts; does not affect peon-ping runtime. |
| **Data Impact** | None | No data involved. |
| **Security Impact** | None | No security implications. |

**Business Justification for Priority:**

P1 rather than P2 because the failure is intermittent on different hosts -- it will confuse future executors who see Pester red locally but green on CI (or vice versa). Left unfixed, it undermines trust in the Windows Pester suite.

---

## Documentation & Code Review

| Item | Applicable | File / Location | Notes / Evidence | Key Findings / Action Required |
|---|:---:|---|---|---|
| README or component documentation reviewed | yes | `CLAUDE.md` (Testing section), `tests/setup.bash` | Reviewed Windows test setup for any documented timezone assumption. Action: if none exists, consider adding a one-line note that the Pester harness must normalise datetimes to UTC before comparison. |
| Related ADRs (Architecture Decision Records) reviewed | no | n/a | No ADR on datetime handling in the test harness. |
| API documentation reviewed | no | n/a | Not an API-surface bug. |
| Test suite documentation reviewed | yes | `tests/peon-engine.Tests.ps1`, `tests/adapters-windows.Tests.ps1` | Confirmed other datetime comparisons in the Pester suite use `.ToUniversalTime()` or parse with `DateTimeStyles.AssumeUniversal` -- this harness test is the outlier. |
| IaC configuration reviewed (Terraform, CloudFormation, etc.) | no | n/a | No IaC surface. |
| New Documentation (Action Item) | N/A | **N/A** | After fix, add a one-line comment above the assertion explaining why `.ToUniversalTime()` (or equivalent) is required. |

---

## Root Cause Investigation

| Iteration # | Hypothesis | Test/Action Taken | Outcome / Findings |
| :---: | :--- | :--- | :--- |
| **1** | LHS `[datetime]"2026-01-01T00:00:00Z"` is parsed as local time, not UTC. | Run `([datetime]"2026-01-01T00:00:00Z").Kind` in PS on a UTC-07:00 host. | Confirmed -- returns `Local`, and the value is shifted to `2025-12-31T17:00:00-07:00`. |
| **2** | RHS round-trips as UTC. | Inspect the harness's state-override serialization. | Confirmed -- the harness stores UTC `DateTime` values; the round-trip result has `Kind = Utc`. |
| **3** | `Should -Be` compares `Kind` + instant, not just instant. | Pester docs + experiment on a non-UTC host. | Confirmed -- two `DateTime` values representing the same instant but with different `Kind` compare unequal. Root cause identified. |

---

### Hypothesis testing iterations

**Iteration 1:** LHS is parsed as local, not UTC

**Hypothesis:** `[datetime]"2026-01-01T00:00:00Z"` in PowerShell does not preserve the trailing `Z` (UTC marker) and is reduced to a local `DateTime`.

**Test/Action Taken:** On a UTC-07:00 Windows host, run `([datetime]"2026-01-01T00:00:00Z") | Format-List *`.

**Outcome:** Confirmed -- the result has `Kind = Local` and the wall-clock time is `2025-12-31T17:00:00`, i.e., PowerShell's implicit `[datetime]` cast normalises to local time.

---

**Iteration 2:** RHS is stored and retrieved as UTC

**Hypothesis:** The state-override plumbing in the harness serializes `DateTime` values as UTC ISO-8601 strings and deserializes with `Kind = Utc`.

**Test/Action Taken:** Inspect the harness module and print `$actual.Kind` after retrieval.

**Outcome:** Confirmed -- `$actual.Kind = Utc`. The round-trip is timezone-correct; the test's expectation side is the problem.

---

**Iteration 3:** `Should -Be` compares `Kind` + instant

**Hypothesis:** `Should -Be` on two `DateTime` values performs a strict equality check that considers both the instant and the `Kind`.

**Test/Action Taken:** Pester documentation review + experiment: compare `(Get-Date).ToUniversalTime()` vs `Get-Date` with `Should -Be` on a non-UTC host.

**Outcome:** Confirmed -- fails despite same instant, different `Kind`. Root cause: the LHS in `peon-engine.Tests.ps1` is `Kind = Local`, the RHS is `Kind = Utc`; `Should -Be` rejects the comparison.

---

### Root Cause Summary

**Root Cause:**

`[datetime]"2026-01-01T00:00:00Z"` in PowerShell is parsed in the local timezone (`Kind = Local`, wall-clock shifted by the local UTC offset), while the harness round-trips the value as `Kind = Utc`. `Should -Be` treats two `DateTime` values as unequal when their `Kind` differs, so the comparison fails on any non-UTC host even though both values refer to the same instant.

**Code/Config Location:**

`tests/peon-engine.Tests.ps1` line ~112 (`Harness: New-PeonTestEnvironment.accepts StateOverrides`).

**Why This Happened:**

The test was likely written on a UTC CI agent where both sides happen to parse to `Kind = Local` with the same wall-clock reading, so the `Should -Be` succeeded by accident. The failure mode only surfaces on non-UTC hosts, which is why `dpyzoo`'s broader regression sweep caught it rather than the card's own CI run.

---

## Solution Design

### Fix Strategy

Pick the option that best fits the surrounding test style. The three legitimate options are:

1. **Parse both sides as UTC explicitly.** Replace `[datetime]"2026-01-01T00:00:00Z"` with `[datetime]::Parse("2026-01-01T00:00:00Z", $null, [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal)`. Pros: surgical; no change to `Should` operator. Cons: verbose and easy to forget in future tests.
2. **Normalise both sides to UTC before comparison.** `$expected.ToUniversalTime() | Should -Be $actual.ToUniversalTime()`. Pros: short, readable, matches existing pattern elsewhere in the Pester suite. Cons: requires the test author to remember `.ToUniversalTime()` every time.
3. **Compare ISO-8601 round-trip strings.** `$expected.ToUniversalTime().ToString("o") | Should -BeLikeExactly $actual.ToUniversalTime().ToString("o")`. Pros: explicit and reads well in failure messages. Cons: heavier diff than (2).

**Recommendation:** option (2) -- it matches other datetime comparisons already in the Pester suite and is one line.

### Code Changes

* `tests/peon-engine.Tests.ps1` line ~112: change the `Should -Be` comparison to use `.ToUniversalTime()` on both sides.
* Add a one-line comment above the assertion: `# Normalise to UTC before comparison -- Should -Be compares Kind + instant.`
* If the root cause is better addressed in the harness itself (e.g., `New-PeonTestEnvironment` should reject `Kind = Local` state-override datetimes and force UTC at the boundary), prefer the harness fix and leave the test assertion simple. The executor chooses based on what the harness looks like.

### Rollback Plan

Single-line test change; `git revert` restores the flaky comparison. Because the defect is pre-existing and the test is not gating any runtime path, the rollback risk is purely "lose the fix again", not "break something new".

---

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Test** | Confirm current `Harness: New-PeonTestEnvironment.accepts StateOverrides` fails on a non-UTC host. | - [ ] A failing test that reproduces the bug is committed |
| **2. Verify Test Fails** | Pester output shows the `Expected ... but got ...` message on a non-UTC host. | - [ ] Test suite was run and the new test fails as expected |
| **3. Implement Code Fix** | Apply option (2) from Solution Design. | - [ ] Code changes are complete and committed |
| **4. Verify Test Passes** | Pester green on the same non-UTC host. | - [ ] The original failing test now passes |
| **5. Run Full Test Suite** | `Invoke-Pester -Path tests/` green on both the non-UTC developer host and the Windows CI agent. | - [ ] All existing tests still pass (no regressions) |
| **6. Code Review** | PR review confirms comment explains why `.ToUniversalTime()` is required. | - [ ] Code review approved by at least one peer |
| **7. Update Documentation** | Inline comment added above the assertion. | - [ ] Documentation is updated (DaC - Documentation as Code) |
| **8. Deploy to Staging** | n/a -- test-only change. | - [ ] Fix deployed to staging environment |
| **9. Staging Verification** | n/a -- test-only change. | - [ ] Bug fix verified in staging environment |
| **10. Deploy to Production** | n/a -- test-only change. | - [ ] Fix deployed to production environment |
| **11. Production Verification** | CI Windows Pester run is green. | - [ ] Bug fix verified in production environment |

### Test Code (Failing Test)

> Paste the **failing test code** here as the "definition" of the bug. This test should fail before the fix and pass after the fix.

```powershell
# Before (fails on non-UTC host):
It 'accepts StateOverrides' {
    $expected = [datetime]"2026-01-01T00:00:00Z"
    $env = New-PeonTestEnvironment -StateOverrides @{ last_played = $expected }
    $actual = (Get-PeonState -Path $env.StatePath).last_played
    $actual | Should -Be $expected
}

# After (timezone-stable):
It 'accepts StateOverrides' {
    # Normalise to UTC before comparison -- Should -Be compares Kind + instant.
    $expected = [datetime]::Parse("2026-01-01T00:00:00Z", $null, [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    $env = New-PeonTestEnvironment -StateOverrides @{ last_played = $expected }
    $actual = (Get-PeonState -Path $env.StatePath).last_played
    $actual.ToUniversalTime() | Should -Be $expected.ToUniversalTime()
}
```

---

## Testing & Verification

### Test Plan

| Test Type | Test Case | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| **Unit Test** | `Harness: New-PeonTestEnvironment.accepts StateOverrides` | Passes on non-UTC host. | - [ ] Pass |
| **Integration Test** | Full `Invoke-Pester -Path tests/peon-engine.Tests.ps1` | All tests green. | - [ ] Pass |
| **Regression Test** | Full `Invoke-Pester -Path tests/` on Windows CI agent | All tests green. | - [ ] Pass |
| **Edge Case 1** | Run the fixed test on a UTC host | Still passes. | - [ ] Pass |
| **Edge Case 2** | Run the fixed test on a UTC+12 host (cross-date-line) | Still passes. | - [ ] Pass |
| **Performance Test** | n/a | n/a | - [x] Pass |
| **Manual Test** | Cameron runs Pester locally (UTC-07:00) | Green. | - [ ] Pass |

### Verification Checklist

* [ ] Original bug is no longer reproducible on a non-UTC host.
* [ ] All new tests pass.
* [ ] All existing tests still pass (no regressions).
* [ ] Code review completed and approved.
* [ ] Documentation updated (inline comment).
* [ ] Staging environment verification complete (n/a -- test-only change).
* [ ] Production environment verification complete (CI Windows Pester run green).
* [ ] Monitoring shows healthy metrics (n/a -- test-only change).

---

## Regression Prevention

* [ ] **Automated Test:** The fixed test itself is the regression guard.
* [ ] **Integration Test:** n/a -- this is already an integration-ish harness test.
* [ ] **Type Safety:** Consider normalising datetime inputs to UTC inside `New-PeonTestEnvironment -StateOverrides` so future tests cannot hit this trap.
* [ ] **Linting Rules:** Not applicable -- PowerShell has no built-in lint for this class of bug.
* [ ] **Code Review Checklist:** Add "compare datetimes with `.ToUniversalTime()` or `DateTimeStyles.AssumeUniversal`" to the Windows Pester PR review checklist.
* [ ] **Monitoring/Alerting:** n/a -- test harness only.
* [ ] **Documentation:** Inline comment above the assertion explains the reason.

---

## Validation & Finalization

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | PR link at review time. |
| **Test Results** | `Invoke-Pester -Path tests/` green on non-UTC host and Windows CI. |
| **Staging Verification** | n/a -- test-only change. |
| **Production Verification** | CI Windows Pester run green. |
| **Documentation Update** | Inline comment added above the assertion. |
| **Monitoring Check** | n/a. |

### Follow-up gitban cards

| Topic | Action Required | Tracker | Gitban Cards |
| :--- | :--- | :--- | :--- |
| **Postmortem** | No -- P1 test harness defect, not a production incident. | this card | this card |
| **Documentation Debt** | Inline comment added; no other docs affected. | this card | this card |
| **Technical Debt** | Consider harness-level normalisation as a follow-up if the same trap recurs. | backlog if it recurs | n/a |
| **Process Improvement** | Add "compare datetimes with `.ToUniversalTime()`" to Windows Pester PR review checklist. | this card | this card |
| **Related Bugs** | None known. | n/a | n/a |

### Completion Checklist

* [ ] Root cause is fully understood and documented.
* [ ] Fix follows TDD process (failing test -> fix -> passing test).
* [ ] All tests pass (unit, integration, regression).
* [ ] Documentation updated (inline comment).
* [ ] No manual infrastructure changes.
* [ ] Deployed and verified (merged; CI green).
* [ ] Monitoring confirms fix is working (CI Windows Pester run green).
* [ ] Regression prevention measures added (review checklist).
* [ ] Postmortem completed (n/a -- P1).
* [ ] Follow-up tickets created for related issues (none).
* [ ] Associated ticket is closed.
