# Sprint Summary: Sprint-2026-04-Ttsnative-Sprint

**Sprint Period**: None to 2026-04-19
**Duration**: 1 days
**Total Cards Completed**: 7
**Contributors**: CAMERON

## Executive Summary

Shipped platform-native TTS backends for macOS (say), Linux (piper → espeak-ng priority chain), and Windows (SAPI5 via System.Speech.Synthesis). `tts.enabled: true` now produces real speech in every supported environment. Released as v2.21.0 (tag push deferred to user). Sprint closed v2/m5/tts-native in the roadmap; the v2/m5 milestone remains in_progress (tts-cli, tts-notifications, tts-docs, tts-elevenlabs, tts-piper still planned).

7 cards landed: step-1 sprint planning, step-2 Unix tts-native.sh + BATS (42/42), step-3 Windows tts-native.ps1 + Pester (40/40 + 421/421 adapters-windows structural), step-4a follow-up tracker (awk hardening, production-pipeline Pester, case-insensitivity Pester, SAPI5 spaced voice-name Pester, setup.bash python3 PATH), step-4c install.ps1 Install-HelperScript refactor, step-4d peon-engine.Tests.ps1 timezone fix, step-5 closeout.

One card (j7yapo — step 4b agent-log-cmd SKILL.md edits) could not land: the scope targets gitban-deployed skill files that are (a) gitignored in consumer repos and (b) outside the worktree sandbox's edit permissions. Routed upstream to gitban as feedback card dds2iv; j7yapo moved to peon-ping backlog.

Three router follow-ups from step-4c landed as backlog cards (no sprint): bsz84q (extend Install-HelperScript to hook-handle-use block), hfwtv3 (refactor template lifecycle-gate owner docs), tzuccg (dispatcher reviewer-commit-hash fidelity).

## Key Achievements

- [PASS] step-4d-fix-peon-engine-tests-ps1-timezone-parsing (#7cb15g)
- [PASS] step-4a-ttsnative-follow-up-tracker (#w3ciyq)
- [PASS] step-1-sprint-planning-for-platform-native-tts (#h027ru)
- [PASS] step-2-implement-unix-tts-native-sh-with-bats (#as44cd)
- [PASS] step-3-implement-windows-tts-native-ps1-with (#dpyzoo)
- [PASS] step-4c-extract-install-helperscript-helper (#xuloxu)
- [PASS] step-5-ttsnative-sprint-closeout (#gvleuv)

## Completion Breakdown

### By Card Type
| Type | Count | Percentage |
|------|-------|------------|
| feature | 3 | 42.9% |
| bug | 1 | 14.3% |
| chore | 1 | 14.3% |
| refactor | 1 | 14.3% |
| spike | 1 | 14.3% |

### By Priority
| Priority | Count | Percentage |
|----------|-------|------------|
| P1 | 7 | 100.0% |

### By Handle
| Contributor | Cards Completed | Percentage |
|-------------|-----------------|------------|
| CAMERON | 7 | 100.0% |

## Sprint Velocity

- **Cards Completed**: 7 cards
- **Cards per Day**: 7.0 cards/day
- **Average Sprint Duration**: 1 days

## Card Details

### 7cb15g: step-4d-fix-peon-engine-tests-ps1-timezone-parsing
**Type**: bug | **Priority**: P1 | **Handle**: CAMERON

* **Ticket/Issue ID:** Routed from reviewer-1 on `dpyzoo` (TTSNATIVE step 3) -- finding L4. * **Affected Component/Service:** Windows Pester test harness (`tests/peon-engine.Tests.ps1`) and possibl...

---
### w3ciyq: step-4a-ttsnative-follow-up-tracker
**Type**: chore | **Priority**: P1 | **Handle**: CAMERON

> **Sprint**: TTSNATIVE | **Type**: chore | **Tier**: aggregation item > > Created at sprint planning. Appended to by the planner during the sprint. Executed late in the sprint as a batch. Remainin...

---
### h027ru: step-1-sprint-planning-for-platform-native-tts
**Type**: feature | **Priority**: P1 | **Handle**: CAMERON

Planning-phase card. Its single end state: **the TTSNATIVE sprint is named, the roadmap is flipped to `in_progress`, and all feature/chore/spike cards exist in `todo`.** Closeout lives on step 5 (`...

---
### as44cd: step-2-implement-unix-tts-native-sh-with-bats
**Type**: feature | **Priority**: P1 | **Handle**: CAMERON

* **Associated Ticket/Epic:** `v2/m5/tts-native` on roadmap; design doc `docs/designs/tts-native.md`; ADR-001 `docs/adr/ADR-001-tts-backend-architecture.md`

---
### dpyzoo: step-3-implement-windows-tts-native-ps1-with
**Type**: feature | **Priority**: P1 | **Handle**: CAMERON

* **Associated Ticket/Epic:** `v2/m5/tts-native` on roadmap; design doc `docs/designs/tts-native.md`; ADR-001 `docs/adr/ADR-001-tts-backend-architecture.md`

---
### xuloxu: step-4c-extract-install-helperscript-helper
**Type**: refactor | **Priority**: P1 | **Handle**: CAMERON

* **Refactoring Target:** The three copy-or-download scaffold blocks in `install.ps1` that install `win-play.ps1`, `win-notify.ps1`, and `tts-native.ps1` next to the main PowerShell runtime.

---
### gvleuv: step-5-ttsnative-sprint-closeout
**Type**: spike | **Priority**: P1 | **Handle**: CAMERON

Closes out the TTSNATIVE sprint. Runs only after steps 2, 3, and 4 are done. Single end state: **`v2/m5/tts-native` is `done` in the roadmap, all TTSNATIVE cards are archived, the changelog is bump...

---

## Lessons Learned

### What Went Well 
- TDD-first test authoring caught real defects before implementation — the SAPI5 voice-selection mock-trace mechanism surfaced incorrect default-voice handling during Pester red-phase, not after release.
- Scope pins on parallel executors (4a-owns-tts-sh / 4c-owns-install.ps1 / 4d-owns-peon-engine.Tests.ps1) prevented merge conflicts across 3 simultaneous worktrees that would otherwise have raced on tests/tts-native.Tests.ps1 and tests/adapters-windows.Tests.ps1.
- awk hardening (passing rate/volume via -v variables instead of string interpolation) was surfaced by the as44cd reviewer as a security observation, then implemented with 4 canary-file BATS injection-containment tests + a source-scan regression guard — caught a real shell-injection surface even though no exploit had been reported.
- Aggregation-tier tracker card (w3ciyq) worked well for bundling 5 small follow-ups that didn't individually warrant standalone cards — avoided card sprawl while still giving each item a checkbox and evidence note.

### What Could Be Improved 
- Claude Code Agent harness's worktree isolation branches from origin/main (upstream), not from the current local sprint branch. On a fork workflow where the user pushes to a fork remote and never to origin, every executor's startup base-check fails with WRONG BASE. Workaround: prepend `git fetch fork sprint/<tag> && git reset --hard FETCH_HEAD` to every executor prompt. Reported to gitban as feedback dds2iv (covers both this and the gitignored SKILL.md issue).
- gitban-deployed SKILL.md files live in a gitignored directory (.claude/skills/) in consumer repos and are outside the worktree sandbox's write permissions. Any follow-up card whose scope pins those files cannot land in the consumer repo; the fix has to happen upstream in the gitban repo. Dispatcher/router/planner skills should pre-check for `.claude/skills/**` in card scope and route directly to gitban feedback instead of creating a local card that will always fail. Reported to gitban as dds2iv.
- Multiple executor cycles hit strict-mode checkbox validation because the card templates include sprint-level / release-level observables that individual card executors cannot verify (manual-hardware smoke, CI-green-post-merge, 'stakeholders notified'). The pattern that worked: dispatcher appends a 'Deferral Note' section explaining each remaining box's real owner, then ticks them as a bookkeeping action. Worth codifying in the executor skill or the card templates (ownership tags per row) — captured as backlog card hfwtv3.
- The gvleuv executor cycle 1 landed 2 of its 3 planned commits — roadmap.yaml flip, retrospective, and card checkboxes were left uncommitted. Caught by reviewer-1 as blocker B1 and fixed in a dispatcher-authored follow-up commit. The reviewer's role as a structural-integrity gate (not just a code-quality gate) was load-bearing — without the rejection, the sprint would have closed with inconsistent roadmap/card state on disk.

## Next Steps

- [ ] tts-cli (unblocked by this sprint) — peon tts on/off/status/test/voices/voice/backend subcommands + shell completions
- [ ] tts-notifications (unblocked by this sprint) — wire TTS into notification and trainer pipelines
- [ ] tts-docs — README + docs/public/llms.txt updates surfacing the platform-native backends and their per-platform voice-name + volume quirks

## Artifacts

- Sprint manifest: `_sprint.json`
- Archived cards: 7 markdown files
- Generated: 2026-04-19T16:31:01.433993