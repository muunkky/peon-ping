---
verdict: APPROVAL
card_id: 7cb15g
review_number: 1
commit: f8a36b3
date: 2026-04-18
has_backlog_items: false
---

# Review: TTSNATIVE step 4d -- timezone parsing fix in `tests/peon-engine.Tests.ps1`

## Summary

Approved. The fix correctly diagnoses a cross-shell defect in Pester's `Should -Be` datetime comparison semantics and applies a surgical, timezone-stable normalisation that works on both PowerShell 5.1 and 7.x, on UTC and non-UTC hosts. Scope discipline is clean -- only `tests/peon-engine.Tests.ps1` was modified as declared. Inline comment documents the subtlety for future editors.

## Gate 1 -- Completion claim

The card is a bug-fix card (not a feature card), so the DoD Intent/Observables framing is relaxed. Equivalent structure is present and strong:

- "What's Broken / Expected / Actual" supplies unambiguous Intent.
- Reproduction steps, iterations-of-hypothesis, root-cause summary, and solution design are thorough and testable.
- TDD Implementation Workflow matrix and Verification Checklist act as Observables. The capstone-equivalent ("the fixed test passes on a non-UTC host on both PS 5.1 and PS 7.5") is checked with real evidence -- the executor gives specific pass/fail counts per shell/timezone combination and a concrete commit hash (`40a5496`).
- Unchecked items (code review approved, CI Windows Pester green) are correctly deferred until review and post-merge CI. No false checks.

Checkbox integrity is sound. Gate 1 passes.

## Gate 2 -- Implementation quality

### What the diff actually does

Single test `It "accepts StateOverrides"` at `tests/peon-engine.Tests.ps1:112`. One-line assertion becomes:

- Parse the expected string literal via `[datetime]::Parse("2026-01-01T00:00:00Z", InvariantCulture, AssumeUniversal | AdjustToUniversal)` -- yields `Kind=Utc` regardless of host timezone or PowerShell version.
- Keep the existing `[datetime]$state.last_stop_time` cast for the actual value, then normalise both sides with `.ToUniversalTime()` before `Should -Be`.
- Inline comment above the assertion explains the Kind-vs-instant comparison semantics of `Should -Be` for future editors.

### Root cause validated against the harness

I traced `Get-PeonState` in `tests/windows-setup.ps1:388-399` -- it reads `.state.json` via `Get-Content ... | ConvertFrom-Json`. That confirms the executor's claim about the cross-shell asymmetry:

- pwsh 7.x: `ConvertFrom-Json` auto-parses the ISO-8601 `Z` string to `[DateTime]` with `Kind=Utc`. The `[datetime]` cast of an already-DateTime value is a no-op, so `$actual.Kind = Utc`. The pre-fix RHS cast `[datetime]"2026-01-01T00:00:00Z"` produces `Kind=Local` with wall-clock shifted by the host offset. Different Kind, same instant -> `Should -Be` fails on non-UTC hosts.
- PowerShell 5.1: `ConvertFrom-Json` returns the field as `[string]`. Both sides reduce to `Kind=Local` via identical cast paths and compare equal by symmetry -- the defect is invisible.

The fix resolves both dimensions. On pwsh 7.x the UTC-parsed `$expected` is already `Kind=Utc`, and `$actual.ToUniversalTime()` is a no-op for the already-Utc value. On PowerShell 5.1 both sides get cast to `Kind=Local` then normalised by `.ToUniversalTime()` to equivalent Utc instants. Correct in all four shell x timezone cells.

### Quality observations

- **TDD compliance:** Pure bug-fix TDD -- the pre-existing test *is* the failing test; the fix changes the assertion so the same test passes across both shells. No new behavior, no new test needed. Proportionate to the change.
- **DaC (Documentation as Code):** The inline comment is well-placed, explains *why* not *what*, and names the specific Pester semantics future editors need to know. Appropriate.
- **DRY:** This is the only datetime comparison of this kind in the Pester suite today, so there is no duplication to abstract. If a second occurrence appears, a small helper (`Assert-DateTimeEqual`) would be warranted -- not this card's responsibility.
- **ADR alignment:** No datetime-handling ADR exists; none is needed for a single surgical test-file fix.
- **Scope discipline:** Only `tests/peon-engine.Tests.ps1` was modified in `40a5496`. The companion `f8a36b3` commit adds the executor profiling JSONL, which is infrastructure the reviewer tooling consumes -- legitimate. No drift into other files.
- **Commit message:** Clear, detailed, documents root cause, states verification matrix, and flags scope boundaries. Good citizen.

### Minor observations (non-blocking, not follow-up-worthy)

- The card claims "other datetime comparisons in the Pester suite use `.ToUniversalTime()` or parse with `DateTimeStyles.AssumeUniversal`" -- a ripgrep over `tests/` shows this is actually the only site using those patterns. The card overstated existing precedent. Does not affect the fix's correctness; flagging for future card-authoring accuracy.
- `$expected.ToUniversalTime()` on a Kind=Utc DateTime is a no-op, so the `.ToUniversalTime()` on the RHS is redundant given the `AdjustToUniversal` parse flag. Keeping it symmetric with `$actual.ToUniversalTime()` improves readability and defends against future edits that swap the parse strategy. Acceptable as-is.

## BLOCKERS

None.

## FOLLOW-UP

None.

## Close-out actions

- Card may move to `done` after post-merge Windows CI Pester run is green (the card's remaining unchecked items).
- Profiling log lands at `.gitban/agents/reviewer/logs/TTSNATIVE-7cb15g-reviewer-1.jsonl` per the reviewer skill.
