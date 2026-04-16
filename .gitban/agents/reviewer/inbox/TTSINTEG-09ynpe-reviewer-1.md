---
verdict: APPROVAL
card_id: 09ynpe
review_number: 1
commit: 47ed0b3
date: 2026-03-28
has_backlog_items: false
---

# Review: TTSINTEG-09ynpe-reviewer-1

**Card:** 09ynpe -- step-5d-bats-test-for-speak-only-debug-log-emission
**Sprint:** TTSINTEG
**Commit:** 47ed0b3
**Review number:** 1

## Verdict: APPROVAL

## Summary

Two well-targeted BATS tests covering the PEON_DEBUG-gated diagnostic log in the speak-only TTS path. Directly addresses reviewer finding L1 from TTSINTEG-zxp2my-reviewer-1. No blockers.

## Analysis

**What was changed:** Two new `@test` blocks added to `tests/tts.bats` in a new section "Speak-only debug log emission (PEON_DEBUG gated)". Test 1 exports `PEON_DEBUG=1`, invokes `run_peon_tts` with `tts_mode=speak-only` and `tts_enabled=false`, then asserts the `[tts] speak-only mode but TTS unavailable` diagnostic appears on stderr. Test 2 unsets `PEON_DEBUG` and asserts the diagnostic is absent.

**Cross-reference with production code:** The tests exercise peon.sh lines ~4100-4102, the `speak-only` case branch where `_do_tts=false`. The `tts_enabled=false` parameter correctly causes `run_peon_tts` to write `"enabled": false` into the config, which makes the Python block set `TTS_ENABLED=false`, which makes `_do_tts` stay false. The `speak-only` branch then hits the `else` clause with the PEON_DEBUG guard. Both the positive and negative cases are covered.

**Test quality:**
- Both tests assert the correct behavioral side-effects: no sound played (`! afplay_was_called`), no TTS invoked (`! tts_was_called`), and stderr content checked via `$PEON_STDERR`.
- The positive/negative pair (PEON_DEBUG=1 vs unset) is the right pattern for testing a debug guard -- it confirms the gate works in both directions.
- Tests use existing helpers (`run_peon_tts`, `afplay_was_called`, `tts_was_called`, `$PEON_STDERR`) consistently with the rest of the test file.
- Placement in the file is logical -- after the suppression tests and before the backend resolution tests.

**TDD compliance:** This is a test-only card tracking a reviewer follow-up item. The production code already exists (commit fe25812). The card's purpose is to add missing test coverage for an existing path. TDD proportionality applies -- the tests are the deliverable here, and they are well-formed.

**Checkbox integrity:** All checked boxes on the card are truthful. The two test cases defined in the table match the two tests committed. The "CI validates on macOS" note is accurate -- BATS cannot run in a Windows worktree.

## Files Reviewed

- tests/tts.bats (22 lines added)
- tests/setup.bash (read for cross-reference, no changes)
- peon.sh lines ~4085-4110 (read for cross-reference, no changes)
