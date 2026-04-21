---
verdict: APPROVAL
card_id: w3ciyq
review_number: 1
commit: fb3c53d
date: 2026-04-18
has_backlog_items: false
---

# Review: TTSNATIVE step-4a follow-up tracker (w3ciyq)

## Summary

Scoped, high-quality follow-up batch. Five items declared in the Items block are all implemented, each backed by tests that exercise real behavior (not mocks), changes stay inside the 4a scope pin (scripts/tts-native.sh, tests/tts-native.bats, tests/tts-native.Tests.ps1, tests/setup.bash), and the commit is appropriately narrow at 257 insertions / 8 deletions across 4 code files.

## Gate 1: Completion claim

Aggregation-tier tracker card. Although the card lacks an explicit "Intent" / "Observable outcomes" block in the TTSINTEG standard shape, it is a planner-authored tracker template where the Items block itself acts as the observable outcome list — each appended item is a concrete, testable checkbox carrying its own acceptance criteria in the description, and the top-level Acceptance Criteria cover the aggregation-level properties ("every item resolved or ticketed", "no hidden test gaps", "no late appends"). This matches the aggregation-tier convention in planner/SKILL.md. Acceptable for this tier.

Checkbox integrity: all five Items are `[x]` with specific evidence in the Cycle-1 Work Log. Evidence is concrete (line numbers, test names, local Pester counts), not hand-waved. Pass.

## Gate 2: Implementation quality

### Item-by-item verification

**1. awk hardening (scripts/tts-native.sh)**

- `_speak_macos`, `_speak_piper`, `_speak_espeak_ng` now pass `rate`/`volume` via `awk -v r="$rate"` / `awk -v v="$volume"`.
- Inline comments reference card w3ciyq so the rationale is discoverable at the call site.
- Four canary-file BATS tests (`awk hardening: hostile rate on macOS ...`, same for espeak-ng rate, espeak-ng volume, and piper rate) assert the script exits 0 *and* the canary file is NOT created. This is exactly the right observable — proves the hostile string did not execute as awk code.
- Source-scan regression guard (`awk "[^"]*\$(rate|volume)`) prevents regression to the interpolation pattern.
- Defense-in-depth: rate/volume originate from `config.json` via `peon.sh`'s Python embed (`TTS_RATE=q(str(tts_rate))`). `q()` shell-escapes but the values still reach awk as positional args, so treating them as untrusted at the awk boundary is correct.

**2. L1 production-pipeline Pester test (tests/tts-native.Tests.ps1:384-434)**

- Spawns `powershell -Command "'hello' | & 'tts-native.ps1' -Voice ..."` which exercises the `ValueFromPipeline` binding path (what install.ps1's `Invoke-TtsSpeak` actually uses), not the `[Console]::IsInputRedirected` fallback the existing Invoke-TtsNativeDryRun helper covers.
- Proper assertions: `$trace.Spoke | Should -BeTrue` and `$trace.Text | Should -Be "hello"`. Not mockable — the trace file is written by the real process.
- Timeout guard (`WaitForExit(15000)` + `Kill`) and try/finally dispose are properly handled.

**3. L3 voice case-insensitivity Pester test (lines 446-470)**

- Weakest test in the batch. The assertions (`SelectVoiceCalled | Should -BeTrue`, `SelectedVoice | Should -Not -BeNullOrEmpty`) do not actually prove that an uppercase name resolved to the canonical installed voice — they only prove the voice-selection path ran. The inline comment openly acknowledges this ("We allow either the caller-provided uppercase form OR the canonical installed form").
- This is not a blocker: PowerShell's `-contains` operator is case-insensitive by definition and cannot silently regress without a language change, and the test still guards against someone swapping `-contains` for `-ccontains`. It does codify the behavioural expectation. But as a TDD contract for "case-insensitive matching", it is thin — the stronger assertion would be `$r.Trace.SelectedVoice | Should -Be $first` (canonical form). See FOLLOW-UP L1.

**4. SAPI5 spaced voice-name binding Pester tests (lines 482-501)**

- Two `It` cases covering "Microsoft David Desktop" and "Microsoft Zira Desktop". Asserts `Trace.RequestedVoice | Should -Be $spaced` verbatim.
- Correctly placed in `tts-native.Tests.ps1` per the card's scope pin (not `adapters-windows.Tests.ps1` which is 4c territory). Scope discipline confirmed.
- Strong assertion — proves the full `bash → powershell.exe -File ... -Voice "$voice"` arg pipeline preserves spaces, which was the exact unverified shape from the Zira-case coverage gap.

**5. setup.bash python3 PATH resolution (tests/setup.bash:1-15, 452, 469, 474, 613)**

- Resolves `$PEON_PY` via `command -v python3` with a `python` fallback; errors loudly with a friendly message if neither is present.
- Three hardcoded `/usr/bin/python3` call sites (`run_peon_tts`, a second invocation inside the same function for manifest speech_text injection, and `enable_debug_logging`) all updated to `"$PEON_PY"`.
- Guard via idempotent `if [ -z "${PEON_PY:-}" ]` so multi-sourcing is safe.
- Regression guard in `tests/tts-native.bats` scans the body of `run_peon_tts` and `enable_debug_logging` via awk state machine for any `/usr/bin/python3` reintroduction. Offender-capture with line numbers makes future failures diagnosable.
- Minor note: the `python` fallback could silently pick up Python 2 on some systems; given these JSON-manipulation invocations use only print() and json (2/3 compatible surface), this is acceptable in practice. Not a blocker.

### TDD discipline

Tests and production changes are in the same commit with tests that meaningfully exercise behavior (real canary files, real process invocations, real trace file I/O — not overmocked). The injection-containment tests in particular are textbook TDD — they would fail if the hardening regressed, and they are not reverse-engineered from the implementation (they assert on side effects, not internal state). Pass.

### Test plan execution

Card work log claims Pester 40/40 PASS locally and acknowledges BATS not run on the Windows dev host. Reviewer context note says BATS now 42/42 green locally after follow-up. Combined with the macOS CI running the full BATS suite on merge-back, the test plan is verified. Pass.

### Scope / dependencies

`git show` confirms only the four in-scope files changed (plus the executor log jsonl). No 4b/4c/4d files touched. Scope discipline clean.

### ADR compliance

ADR-001 (TTS backend architecture) does not mandate specific injection hardening but the change is consistent with the architectural posture (backends are invoked with untrusted config values; hardening belongs inside each backend). No new ADR needed for this hygiene work. Pass.

### Security

Defense-in-depth hardening. No new surface area introduced. Pass.

### Documentation as Code

Inline comments at each hardened call site reference the card ID so the rationale is discoverable. No user-facing docs need updates (rate/volume contract is unchanged). Pass.

## BLOCKERS

None.

## FOLLOW-UP (non-blocking)

**L1: Strengthen voice case-insensitivity Pester assertion**

The test at `tests/tts-native.Tests.ps1:446-470` asserts only that `SelectedVoice` is non-empty after calling with an uppercase voice name. To truly codify "uppercase resolves to canonical", the assertion should be:

```powershell
$r.Trace.SelectedVoice | Should -Be $first   # canonical form, not $upper
```

This would catch a regression where someone made the match case-sensitive (e.g., `-ccontains` swap) — the current weaker assertion would still pass if the fallback "default voice" path kicked in. One-line change, same file. Aggregation-tier follow-up for next sprint.

## Close-out actions

- Approve and move to `in_progress` (per reviewer skill: approved cards return to in_progress, not done — author closes out).
