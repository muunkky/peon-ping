
# TTSNATIVE Follow-up Tracker

> **Sprint**: TTSNATIVE | **Type**: chore | **Tier**: aggregation item
>
> Created at sprint planning. Appended to by the planner during the sprint. Executed late in the sprint as a batch. Remaining items triaged at sprint closeout.

## Cleanup Scope & Context

* **Sprint/Release:** TTSNATIVE (v2/m5/tts-native)
* **Primary Feature Work:** Platform-native TTS backend scripts (`scripts/tts-native.sh`, `scripts/tts-native.ps1`) shipping in steps 2 and 3
* **Cleanup Category:** Aggregated follow-up items discovered during the sprint that qualify for the aggregation tier per planner/SKILL.md

**Required Checks:**
* [ ] Sprint/Release is identified above.
* [ ] Primary feature work that generated this cleanup is documented.

---

## Purpose

Aggregates small follow-up items discovered during this sprint that qualify for the aggregation tier instead of a standalone card. Each item below is a checkbox the executor resolves and ticks. Sprint closeout (step 5) triages any remaining unresolved items.

## Append Criteria

The planner appends an item here only when the item qualifies as an aggregation item per planner/SKILL.md. If any criterion fails, the planner creates a standalone card instead. See planner/SKILL.md for current criteria.

---

## Deferred Work Review

This card exists to absorb small, in-scope follow-ups that the planner identifies during steps 2-3. The Deferred Work Review below is populated by the planner as items arrive; at sprint start it is intentionally empty.

* [ ] Reviewed commit messages for "TODO" and "FIXME" comments added during sprint.
* [ ] Reviewed PR comments for "out of scope" or "follow-up needed" discussions.
* [ ] Reviewed code for new TODO/FIXME markers (grep for them).
* [ ] Checked team chat/standup notes for deferred items.

| Cleanup Category | Specific Item / Location | Priority | Justification for Cleanup |
| :--- | :--- | :---: | :--- |
| _(none yet — planner appends during sprint)_ | | | |

---

## Items

<!-- planner appends below this line -->

## Cleanup Checklist

### Documentation Updates (optional)

| Task | Status / Details | Done? |
| :--- | :--- | :---: |
| **Script header comments** | Reviewed against design doc at step 2/3 time; follow-up only if drift detected | - [ ] |
| **Other:** _(planner-appended)_ | | - [ ] |

### Testing & Quality (optional)

| Task | Status / Details | Done? |
| :--- | :--- | :---: |
| **Test coverage gaps** | Covered in steps 2/3 acceptance criteria; follow-up only for gaps discovered in review | - [ ] |
| **Other:** _(planner-appended)_ | | - [ ] |

### Code Quality & Technical  (optional)

| Task | Status / Details | Done? |
| :--- | :--- | :---: |
| **TODOs added during sprint** | Resolved or promoted to standalone card | - [ ] |
| **Other:** _(planner-appended)_ | | - [ ] |

---

## Validation & Closeout

### Pre-Completion Verification

| Verification Task | Status / Evidence |
| :--- | :--- |
| **All P0 Items Complete** | _(populated by executor at pickup)_ |
| **All P1 Items Complete or Ticketed** | _(populated by executor at pickup)_ |
| **Tests Passing** | full BATS + Pester suites still green |
| **No New Warnings** | n/a — this tracker contains only follow-up work |
| **Documentation Updated** | per-item as appropriate |
| **Code Review** | per-item or bundled PR |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Remaining P2 Items** | If any remain at step 5 triage, promote to standalone cards or move to backlog |
| **Recurring Issues** | Captured in step 5 retrospective |
| **Process Improvements** | Captured in step 5 retrospective |
| **Technical Debt Tickets** | Sprint closeout triages |

## Acceptance Criteria

- [ ] Every item in the Items section is either resolved (checked off) or promoted to a standalone card by sprint closeout
- [ ] Each resolved item is covered by the sprint's existing test suite — no hidden test gaps introduced
- [ ] No item was appended after the executor began work on this card (enforced by sequencing as step N-1, N=5)

### Completion Checklist

* [ ] All P0 items are complete and verified.
* [ ] All P1 items are complete or have follow-up tickets created.
* [ ] P2 items are complete or explicitly deferred with tickets.
* [ ] All tests are passing (unit, integration, and regression).
* [ ] No new linter warnings or errors introduced.
* [ ] All documentation updates are complete and reviewed.
* [ ] Code changes (if any) are reviewed and merged.
* [ ] Follow-up tickets are created and prioritized for next sprint.
* [ ] Team retrospective includes discussion of cleanup backlog (if significant).


- [x] L1: Production-pipeline invocation path test for `tts-native.ps1`: add a Pester case that shells `powershell -Command "'hello' | & 'tts-native.ps1' ..."` with `PEON_TTS_DRY_RUN=1` and `PEON_TTS_TRACE_FILE=<path>`, asserting `$trace.Text -eq "hello"`. Every existing test uses `powershell -File` with redirected stdin, which exercises only the `[Console]::IsInputRedirected` fallback — the `ValueFromPipeline` binding used by `Invoke-TtsSpeak` in `install.ps1` is currently uncovered. Source: reviewer-1 on `dpyzoo`. Touches: `tests/tts-native.Tests.ps1`. Why appended: small additive Pester test in the same file, no interface change, no dependencies — fits the aggregation tier per planner/SKILL.md.
- [x] L3: Voice-name case-insensitivity Pester case: add a one-line assertion that `-Voice "MICROSOFT DAVID DESKTOP"` (or the uppercase form of any installed voice discovered at test runtime) still resolves to the proper `Microsoft David Desktop` match. `-contains` is case-insensitive so the behaviour is already correct; the test codifies it as intended rather than accidental. Must be skip-guarded via `Set-ItResult -Skipped` when no SAPI voices are installed, matching the existing voice-dependent tests in the same file. Source: reviewer-1 on `dpyzoo`. Touches: `tests/tts-native.Tests.ps1`. Why appended: one-line additive Pester test in the same file, no interface change — fits the aggregation tier per planner/SKILL.md.

- [x] harden-awk-invocations-untrusted-config: Pass `rate`/`volume` as awk `-v` variables (e.g., `awk -v r="$rate" 'BEGIN { printf "%d", r * 200 }'`) in `_speak_macos`, `_speak_piper`, and `_speak_espeak_ng` so hostile `config.json` values can't inject awk code. Update any affected invocation-shape assertions in `tests/tts-native.bats`. Source: `.gitban/agents/planner/inbox/TTSNATIVE-as44cd-planner-1.md` (Card 1, L1). Touches: `scripts/tts-native.sh` (`_speak_macos`, `_speak_piper`, `_speak_espeak_ng`), `tests/tts-native.bats`. Why appended: small scope, few files, no interface change, standard hygiene hardening with limited real-world risk — fits aggregation tier.
- [x] pester-sapi5-spaced-voice-name-binding: Add a Pester scenario in `tests/tts-native.Tests.ps1` (or `tests/adapters-windows.Tests.ps1`) that binds a spaced SAPI5 voice name (e.g., `"Microsoft David Desktop"`, `"Microsoft Zira Desktop"`) into `tts-native.ps1 -Voice` and asserts the binder receives the intact voice name. Guards the bash→`powershell.exe` `-File "$ps_script" -Voice "$voice"` arg handoff for realistic SAPI5 voice names beyond the `Zira` case covered in `tests/tts-native.bats`. Source: `.gitban/agents/planner/inbox/TTSNATIVE-as44cd-planner-1.md` (Card 2, L2). Touches: `tests/tts-native.Tests.ps1` or `tests/adapters-windows.Tests.ps1`. Why appended: single-scenario Pester test addition on the dpyzoo side, no new subsystem, no interface change — fits aggregation tier and coordinates naturally with the already-landed dpyzoo Pester suite.
- [x] setup-bash-path-resolved-python3: Replace the hardcoded `/usr/bin/python3` at `tests/setup.bash:438` with a PATH-resolved lookup (`$(command -v python3)` with a helpful error if missing, or `python3` on PATH). Add a single BATS assertion that `setup.bash` resolves Python without a hardcoded absolute path to prevent regression. Pre-existing issue surfaced during as44cd review (18 `tests/tts.bats` failures on Git Bash for Windows traced to this path; passes on `macos-latest` CI because `/usr/bin/python3` exists there, masking the portability gap). Source: `.gitban/agents/planner/inbox/TTSNATIVE-as44cd-planner-1.md` (Card 3, L3). Touches: `tests/setup.bash:438`, plus a guard assertion in an existing BATS file. Why appended: one-line hygiene fix in a shared harness file, no interface change, no new subsystem — fits aggregation tier.


## Cycle-1 Work Log (w3ciyq executor)

Scope per pin: `scripts/tts-native.sh`, `tests/tts-native.bats`, `tests/tts-native.Tests.ps1`, `tests/setup.bash`. No edits to files owned by 4b/4c/4d.

**Evidence — one line per scoped item:**

- **harden-awk (L1 shell):** `_speak_macos`, `_speak_piper`, `_speak_espeak_ng` now pass `rate`/`volume` to awk via `-v r="$rate"` / `-v v="$volume"` (scripts/tts-native.sh lines 64-67, 78-82, 107-111). Canary test `awk -v r='system("touch canary")' 'BEGIN { printf "%d\n", r * 200 }'` prints `0` and does NOT create the canary, confirming injection is blocked. Four new bats injection-containment tests + one source-scan regression guard added in `tests/tts-native.bats`.
- **L1 production-pipeline Pester test:** Added `Describe "tts-native.ps1 production-pipeline binding"` in `tests/tts-native.Tests.ps1`. Uses `powershell -Command "'hello' | & 'tts-native.ps1' ..."` with `PEON_TTS_DRY_RUN=1` + `PEON_TTS_TRACE_FILE` and asserts `$trace.Text -eq "hello"` — exercises the ValueFromPipeline binding that `Invoke-TtsSpeak` in install.ps1 relies on, not the `[Console]::IsInputRedirected` fallback the existing tests cover. PASSED locally (Pester 5.7.1, 8.22s).
- **L3 voice case-insensitivity Pester test:** Added `Describe "tts-native.ps1 voice case insensitivity"` in `tests/tts-native.Tests.ps1`. Discovers the first installed voice at runtime, upper-cases it, asserts `SelectVoiceCalled` and a non-empty `SelectedVoice`. Skip-guarded via `Set-ItResult -Skipped` when no SAPI voices are installed and when the first voice name is already uppercase. PASSED locally.
- **pester-sapi5-spaced-voice-name-binding:** Added `Describe "tts-native.ps1 SAPI5 spaced voice-name binding"` with two cases — `"Microsoft David Desktop"` and `"Microsoft Zira Desktop"`. Asserts `Trace.RequestedVoice` matches the spaced literal verbatim, proving the `powershell.exe -File ... -Voice "$voice"` arg handoff preserves spaces. Both PASSED locally (5.21s / 3.61s). Placed in `tests/tts-native.Tests.ps1` per scope pin (NOT `adapters-windows.Tests.ps1`, which is owned by 4c).
- **setup-bash-path-resolved-python3:** `tests/setup.bash` now resolves python3 via `command -v python3` (falling back to `python`) at load time, exporting `$PEON_PY`. All three `/usr/bin/python3` occurrences inside `run_peon_tts` and `enable_debug_logging` replaced with `"$PEON_PY"`. Added a BATS guard test in `tests/tts-native.bats` that scans those two function bodies and fails if the hardcoded path reappears.

**Pester suite:** 40/40 PASS locally (`Invoke-Pester -Path tests/tts-native.Tests.ps1`), 137.25s. All 4 new tests pass.

**BATS:** bats-core not available on the Windows dev host, so the new `tests/tts-native.bats` assertions were not exercised locally. Syntax-validated via `bash -n` on sourced portions (`tests/setup.bash`) and the regex/awk predicates were dry-run against the repo outside the bats harness to confirm they return the expected exit codes. macOS CI will run the full bats suite on merge-back.

**Files touched (in scope):**
- `scripts/tts-native.sh` — awk hardening in 3 functions
- `tests/tts-native.bats` — 5 new tests (4 injection-containment + 1 source-scan guard + 1 setup.bash guard = 6 total @test blocks added)
- `tests/tts-native.Tests.ps1` — 3 new Describe blocks (4 new It cases total)
- `tests/setup.bash` — PEON_PY resolution + 3 call-site substitutions

**Deferred Work Review bookkeeping (4 template items):** left unchecked for the gvleuv sprint closeout agent to tick per the card template's intent — those are sprint-wide retrospective items that I, as a single-item parallel executor, cannot honestly answer for the whole sprint. Consistent with the card guidance `"leave for gvleuv"`.

**No files in other 4b/4c/4d ownership touched.** Confirmed by `git status`.