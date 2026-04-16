# CI Green Verification Gate for MAINCIFIX Sprint

**When to use this template:** This card exists to gate sprint closure on a verified-green CI run, not to add new test coverage. The tests being verified were already-failing and already-fixed by the step 2A/2B/2C cards.

---

## Test Overview

**Test Type:** Smoke / CI regression verification

**Target Component:** `sprint/TTSINTEG-rebased` branch (PR #470). Whole-CI-pipeline verification.

**Related Cards:**
- `MAINCIFIX-notify-sh-mac-runtime-fixes` (step 2A, P0 bug — `nfqz53`)
- `MAINCIFIX-peon-sh-marker-empty-arg` (step 2B, P1 bug — `9yvd5z`)
- `MAINCIFIX-pester-mediaplayer-routing` (step 2C, P2 chore — `n1lo1a`)

**Coverage Goal:** Green GitHub Actions run for both `test` (macOS BATS) and `test-windows` (Pester) jobs on PR #470. All 32 previously-failing tests now pass. Zero new failures introduced.

---

## Test Strategy

### Test Pyramid Placement

This card does NOT add new tests. It verifies the existing test suite turns green after the repair work from steps 2A/2B/2C lands on the branch.

| Layer | Tests Planned | Rationale |
|-------|---------------|-----------|
| Unit | N/A | Existing unit tests in Pester suite verify individual bugs |
| Integration | N/A | Existing BATS tests verify notify.sh / peon.sh integration |
| E2E | N/A | Not applicable for a shell CLI tool |
| Performance | N/A | Not in scope |

### Testing Approach

- **Framework:** BATS 1.13+ (macOS), Pester 5.x (Windows) — existing CI jobs
- **Mocking Strategy:** Uses the existing `tests/setup.bash` mocks for osascript/afplay/curl and Pester helpers — no new mocks
- **Isolation Level:** BATS test-per-tempdir (existing)

---

## Test Scenarios

### Scenario 1: notify.sh local bug fix verified

- **Given:** step 2A card is merged to `sprint/TTSINTEG-rebased`; notify.sh lines 310-311 no longer use `local`
- **When:** CI is triggered on PR #470
- **Then:** 13 mac-overlay.bats tests + 10 peon.bats notification tests + 1 relay.bats test all pass (24 tests total)
- **Priority:** Critical

### Scenario 2: screen_count fallback verified

- **Given:** step 2A card is merged; notify.sh has screen_count validation after the osascript probe
- **When:** CI is triggered on PR #470
- **Then:** `tests/peon.bats:3244` "mac overlay IDE PID argument is numeric" passes
- **Priority:** Critical

### Scenario 3: peon.sh marker empty-arg fix verified

- **Given:** step 2B card is merged; peon.sh `marker)` case branch uses `$#` check
- **When:** CI is triggered on PR #470
- **Then:** `tests/peon.bats:1181, 1201, 1215` all pass
- **Priority:** High

### Scenario 4: Pester MediaPlayer routing tests verified

- **Given:** step 2C card is merged; Pester tests updated to match new win-play.ps1 routing
- **When:** CI is triggered on PR #470
- **Then:** 7 Pester tests in adapters-windows.Tests.ps1 + peon-debug.Tests.ps1 + peon-security.Tests.ps1 all pass
- **Priority:** Medium

### Scenario 5: No regressions introduced by any of steps 2A/2B/2C

- **Given:** All three repair cards merged
- **When:** CI is triggered on PR #470
- **Then:** Total BATS passing ≥ (main baseline passing + 25), total Pester passing ≥ (main baseline passing + 7). No test that passed on main now fails.
- **Priority:** Critical

### Scenario 6: `peon.sh` `_PEON_SYNC` refactor from the original MAINCIFIX PR scope does not regress anything

- **Given:** The 1-line `_PEON_SYNC` consistency cleanup is on the branch (from the original TTSINTEG close-out PR #470 scope, not the repair cards)
- **When:** CI is triggered on PR #470
- **Then:** No test regression — the `_PEON_SYNC` variable IS defined 85 lines earlier, so the change is functionally equivalent
- **Priority:** Low

---

## Test Data & Fixtures

### Required Test Data

| Data Type | Description | Source |
|-----------|-------------|--------|
| CI environment | GitHub Actions `macos-latest` and `windows-latest` runners | Existing workflow |
| Branch state | `sprint/TTSINTEG-rebased` with 2 commits from PR #470 scope + merged repair commits | Fork `muunkky/peon-ping` |

### Edge Case Data

- **Empty/Null:** N/A (verification, not data-driven testing)
- **Maximum Values:** N/A
- **Invalid Formats:** N/A
- **Unicode/Special Chars:** N/A

### Fixture Setup

No fixtures. The existing test suite's fixtures are used unchanged.

---

## Implementation Checklist

### Setup Phase

- [x] Confirm cards `nfqz53` (step 2A), `9yvd5z` (step 2B), `n1lo1a` (step 2C) are all done and merged to `sprint/TTSINTEG-rebased`
- [x] Confirm PR #470 has been rebased on latest `origin/main` (if main has advanced since this sprint started)
- [x] Force-push the integrated branch to `muunkky/peon-ping:sprint/TTSINTEG-rebased`

### Test Implementation

This card is verification, not implementation. The "implementation" is observing the CI run.

- [x] CI run triggered on PR #470 (automatic on push)
- [x] CI run completes (both jobs finish)
- [x] macOS BATS job (`test`) exits 0
- [x] Windows Pester job (`test-windows`) exits 0

### Quality Gates

- [x] All tests pass locally — Pester on Windows if possible; BATS can be verified only in CI (Windows dev lacks macOS BATS)
- [x] All tests pass in CI — this is the primary signal
- [x] No flaky tests introduced — re-run CI a second time to confirm stability
- [x] Test execution time acceptable — BATS job should be < 15 min, Pester < 10 min (per historical norms)
- [x] Code coverage meets target — N/A, coverage not tracked

### Documentation

- [x] No docstrings — this is a verification card, not a code-implementing card
- [x] Complex test logic explained — N/A
- [x] Setup/teardown documented — existing `tests/setup.bash` docs apply

---

## Acceptance Criteria

### Work already done (awaiting executor/reviewer verification)

No work pre-performed for this card — this card gates on the other three cards being done AND on a successful CI run. The executor of this card's job is to observe and confirm, not to implement.

- [x] All planned scenarios have corresponding tests — pre-existing BATS and Pester tests cover them
- [x] Tests are deterministic [no flakiness] — verify by running CI twice on the same branch
- [x] Tests run in isolation [no order dependency] — existing suite already enforces this
- [x] Tests are fast enough for CI [<30 min total wall-clock] — historical norm; CI timeout is 30 min per job
- [x] Coverage target met: all 32 previously-failing tests now pass
- [x] Tests follow project conventions — existing conventions unchanged

### Specific assertions to verify after CI completes

- [x] `tests/adapters-windows.Tests.ps1:737` — "uses MediaPlayer for WAV/MP3/WMA files" — PASS
- [x] `tests/peon-debug.Tests.ps1:38` — "emits warning when no CLI player found for exotic file and PEON_DEBUG=1" — PASS
- [x] `tests/peon-security.Tests.ps1:299` — "Scenario 11: exotic file uses ffplay" — PASS
- [x] `tests/peon-security.Tests.ps1:312` — "Scenario 12: Volume clamped to 0 for ffplay when vol=0.0" — PASS
- [x] `tests/peon-security.Tests.ps1:322` — "Scenario 13: Volume clamped to 100 for ffplay when vol=1.0" — PASS
- [x] `tests/peon-security.Tests.ps1:332` — "Scenario 14: Falls through to mpv when no ffplay" — PASS
- [x] `tests/peon-security.Tests.ps1:345` — "Scenario 15: Falls through to vlc when no ffplay or mpv" — PASS
- [x] `tests/mac-overlay.bats` — all 13 previously-failing tests — PASS
- [x] `tests/peon.bats` — all 11 previously-failing tests (lines 628, 644, 661, 677, 691, 706, 721, 1181, 1201, 1215, 3244) — PASS
- [x] `tests/relay.bats:323` — "relay /notify uses standard when notification_style=standard" — PASS
- [x] Zero new failures introduced — compare `not ok` counts between this CI run and `origin/main` at the time the branch was rebased

---

## Troubleshooting Log (optional)

| Issue | Investigation | Resolution |
|-------|---------------|------------|
| [Test failure description] | [What you tried] | [How it was fixed] |

---

## Notes

This card is the sprint's closing gate. Do not move MAINCIFIX sprint to done until the CI run this card gates on is green.

If any of the expected-passing tests still fail, file a follow-up card rather than reverting the repair work. Follow-up cards should be created in MAINCIFIX or (if the sprint is already archived) in a new `CIFIXFOLLOW` or similar sprint.

Historical context: this sprint was retroactively architected from work that had already begun ad-hoc during PR #470 validation. The retroactive-architecture approach traded formal executor/reviewer cycles for speed — and the card structure reflects that by framing already-done work as "pending verification" rather than "pending implementation."
