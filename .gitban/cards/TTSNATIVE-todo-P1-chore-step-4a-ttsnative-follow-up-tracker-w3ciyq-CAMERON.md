
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


- [ ] L1: Production-pipeline invocation path test for `tts-native.ps1`: add a Pester case that shells `powershell -Command "'hello' | & 'tts-native.ps1' ..."` with `PEON_TTS_DRY_RUN=1` and `PEON_TTS_TRACE_FILE=<path>`, asserting `$trace.Text -eq "hello"`. Every existing test uses `powershell -File` with redirected stdin, which exercises only the `[Console]::IsInputRedirected` fallback — the `ValueFromPipeline` binding used by `Invoke-TtsSpeak` in `install.ps1` is currently uncovered. Source: reviewer-1 on `dpyzoo`. Touches: `tests/tts-native.Tests.ps1`. Why appended: small additive Pester test in the same file, no interface change, no dependencies — fits the aggregation tier per planner/SKILL.md.
- [ ] L3: Voice-name case-insensitivity Pester case: add a one-line assertion that `-Voice "MICROSOFT DAVID DESKTOP"` (or the uppercase form of any installed voice discovered at test runtime) still resolves to the proper `Microsoft David Desktop` match. `-contains` is case-insensitive so the behaviour is already correct; the test codifies it as intended rather than accidental. Must be skip-guarded via `Set-ItResult -Skipped` when no SAPI voices are installed, matching the existing voice-dependent tests in the same file. Source: reviewer-1 on `dpyzoo`. Touches: `tests/tts-native.Tests.ps1`. Why appended: one-line additive Pester test in the same file, no interface change — fits the aggregation tier per planner/SKILL.md.

- [ ] harden-awk-invocations-untrusted-config: Pass `rate`/`volume` as awk `-v` variables (e.g., `awk -v r="$rate" 'BEGIN { printf "%d", r * 200 }'`) in `_speak_macos`, `_speak_piper`, and `_speak_espeak_ng` so hostile `config.json` values can't inject awk code. Update any affected invocation-shape assertions in `tests/tts-native.bats`. Source: `.gitban/agents/planner/inbox/TTSNATIVE-as44cd-planner-1.md` (Card 1, L1). Touches: `scripts/tts-native.sh` (`_speak_macos`, `_speak_piper`, `_speak_espeak_ng`), `tests/tts-native.bats`. Why appended: small scope, few files, no interface change, standard hygiene hardening with limited real-world risk — fits aggregation tier.
- [ ] pester-sapi5-spaced-voice-name-binding: Add a Pester scenario in `tests/tts-native.Tests.ps1` (or `tests/adapters-windows.Tests.ps1`) that binds a spaced SAPI5 voice name (e.g., `"Microsoft David Desktop"`, `"Microsoft Zira Desktop"`) into `tts-native.ps1 -Voice` and asserts the binder receives the intact voice name. Guards the bash→`powershell.exe` `-File "$ps_script" -Voice "$voice"` arg handoff for realistic SAPI5 voice names beyond the `Zira` case covered in `tests/tts-native.bats`. Source: `.gitban/agents/planner/inbox/TTSNATIVE-as44cd-planner-1.md` (Card 2, L2). Touches: `tests/tts-native.Tests.ps1` or `tests/adapters-windows.Tests.ps1`. Why appended: single-scenario Pester test addition on the dpyzoo side, no new subsystem, no interface change — fits aggregation tier and coordinates naturally with the already-landed dpyzoo Pester suite.
- [ ] setup-bash-path-resolved-python3: Replace the hardcoded `/usr/bin/python3` at `tests/setup.bash:438` with a PATH-resolved lookup (`$(command -v python3)` with a helpful error if missing, or `python3` on PATH). Add a single BATS assertion that `setup.bash` resolves Python without a hardcoded absolute path to prevent regression. Pre-existing issue surfaced during as44cd review (18 `tests/tts.bats` failures on Git Bash for Windows traced to this path; passes on `macos-latest` CI because `/usr/bin/python3` exists there, masking the portability gap). Source: `.gitban/agents/planner/inbox/TTSNATIVE-as44cd-planner-1.md` (Card 3, L3). Touches: `tests/setup.bash:438`, plus a guard assertion in an existing BATS file. Why appended: one-line hygiene fix in a shared harness file, no interface change, no new subsystem — fits aggregation tier.