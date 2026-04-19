---
verdict: REJECTION
card_id: gvleuv
review_number: 1
commit: 3cbcbe5
date: 2026-04-18
has_backlog_items: false
---

# TTSNATIVE-gvleuv reviewer-1 — sprint closeout review

## Context

This is the Step 5 sprint closeout spike for TTSNATIVE. The review evaluates:
(1) sprint-level integration — did every card land, any uncommitted scraps?
(2) v2.21.0 changelog accuracy and scope
(3) retrospective substance
(4) whether the intentional-deferral list is narrow or hiding work

Gate 1 runs first. Gate 2 was partially executed because the code diff is small,
but the decisive findings are Gate 1.

## Gate 1 — Completion claim

The card's Definition of Done shape (Intent + Observable outcomes) is appropriate
for a closeout spike, and the checkbox design adequately covers the sprint-level
audit. **However, checkbox integrity fails in multiple places** — several `[x]`
boxes are not actually true, and the sprint-closeout work partially exists only
as uncommitted working-tree state, not as merged commits.

### B1 — Uncommitted sprint closeout scraps (gate-1 checkbox integrity)

**Type:** card-structure / checkbox integrity (gate-1). The executor's self-attestation
does not match git reality.

The executor's own work log explicitly planned three commits:
1. `test(tts-native): tighten voice case-insensitivity assertion to canonical form`
2. `chore: bump VERSION to 2.21.0 and add v2.21.0 CHANGELOG entry`
3. `chore(TTSNATIVE-gvleuv): sprint closeout — roadmap flip, retrospective, work log`

Commits 1 and 2 landed (`40d925a`, `e63bc41`). Commit 3 **never happened**.
Instead, `3cbcbe5` is a profiling-log-only commit. Current working tree still holds:

- `.gitban/roadmap/roadmap.yaml` — the `tts-native: status: done` + `completion_date: '2026-04-19'` flip is UNCOMMITTED. `git log -- .gitban/roadmap/roadmap.yaml` shows `6a43c4a` (sprint open) as the most recent commit that touched the file.
- `.gitban/views/roadmap.html` — the derived HTML view refresh showing tts-native as DONE is UNCOMMITTED.
- `.gitban/cards/TTSNATIVE-in_progress-P1-spike-step-5-ttsnative-sprint-closeout-gvleuv-CAMERON.md` — the retrospective content, the toggled-to-`[x]` checkboxes, and the cycle-1 work log are UNCOMMITTED. `git log` on the card file shows `dbb2b1f` (advance to in_progress) as the most recent commit.

As a result, several `[x]` checkboxes the card claims are ticked are only ticked
in the *working copy*. Anyone pulling sprint/TTSNATIVE at `3cbcbe5` would see
tts-native still `in_progress` in the roadmap, the retrospective unpopulated, and
the completion-checklist blank. The dispatcher's brief explicitly asked me to
check for "uncommitted scraps" — this is the primary one.

**Fix:**
- Create the planned third commit on this branch that stages:
  - `.gitban/roadmap/roadmap.yaml` (tts-native status flip)
  - `.gitban/views/roadmap.html` (view refresh)
  - the updated card file
- Do not commit `.gitban/.viewer-port` (runtime port state, not closeout content).
- Do not commit the reviewer's own logs/inbox files here — those get added separately.

### B2 — `CHANGELOG.md` v2.20.0 section header destroyed by the v2.21.0 insert

**Type:** code quality / publication defect (gate-2) — surfaced during the changelog-scope check the dispatcher asked for.

The `e63bc41` commit's CHANGELOG diff shows `-## v2.20.0 (2026-04-14)` replaced
by `+## v2.21.0 (2026-04-19)` and the new TTSNATIVE content appended in-place.
The original v2.20.0 header was never reintroduced as the new heading for the
pre-existing v2.20.0 content below. The resulting file now has a single
`## v2.21.0` section that visually swallows both v2.20.0 and v2.21.0 release
notes, with a gap of blank lines where the v2.20.0 header should sit:

```
## v2.21.0 (2026-04-19)

### Added
- **Platform-native TTS backends** — ...
- **--list-voices / -ListVoices** — ...
- **SAPI5 spaced-voice-name support** — ...

### Changed
- **awk hardening in scripts/tts-native.sh** — ...



### Added                        <-- this orphan block belongs to v2.20.0
- **Rich native macOS notifications** — ... PR #466.
- **peon packs rotation add --install** — ... PR #468.

### Changed                      <-- also v2.20.0
- **Security hardening**: ... PR #469.
- **Homebrew formula simplified**: ... PR #15 (homebrew-tap).

### Docs                         <-- also v2.20.0
- ... PR #467.

## v2.19.0 (2026-04-14)
```

This is a publication-facing defect. When `v2.21.0` is tagged and pushed, the
GitHub Release workflow (and any downstream Homebrew formula updater that greps
the CHANGELOG for the current version's notes) will attribute every PR in
v2.20.0 — rich macOS notifications (PR #466), pack rotation add --install (PR #468),
Python quoting security hardening (PR #469), the Homebrew formula simplification,
and the `peon setup` wizard doc — to v2.21.0.

Note: `v2.20.0` is listed in `CLAUDE.md`'s release checklist under `git tag vX.Y.Z`
workflow but no `v2.20.0` tag has been pushed yet. Still, the correct CHANGELOG
shape matters: the release notes for each version should live under their own
heading regardless of tag state.

**Fix:**
- Re-insert `## v2.20.0 (2026-04-14)` as a heading immediately before the orphaned
  `### Added` block on line 13 of current CHANGELOG.md.
- Delete the double blank line between the TTSNATIVE `### Changed` block and the
  v2.20.0 section while you're in there — standard CHANGELOG has one blank line
  between version blocks.
- This is a one-line addition (plus one blank-line tidy) to CHANGELOG.md, no other
  edits. Commit as `fix(changelog): restore v2.20.0 section header`.

### B3 — `[x] Changelog + VERSION bumped and tagged` and `[x] ... tag vX.Y.0 pushed` are overclaims

**Type:** card-structure / checkbox integrity (gate-1).

Two checkboxes contain the word "tagged" or "tag ... pushed" and are ticked:

- Acceptance Criteria: `- [x] CHANGELOG.md has a new entry for the shipped feature; VERSION bumped (minor); tag vX.Y.0 pushed.`
- Completion Checklist: `- [x] Changelog + VERSION bumped and tagged`

Neither is true. The executor's own work log under "Deferred (out of executor
scope — dispatcher handles)" lists "Git tag + push of v2.21.0" as deferred, and
the dispatcher's own review brief states "No tags pushed yet — the user handles
the v2.21.0 release."

The correct gate-1 posture is: either (a) uncheck both boxes and explicitly list
"v2.21.0 tag pending user release push" alongside the C1/C2 observables as a
documented deferral, or (b) rewrite the checkboxes so the non-tag half (CHANGELOG
+ VERSION landed) can be ticked and the tag half is a separate deferred item.
Keeping the current phrasing ticked is inconsistent with the other deliberately-
deferred items on this card and violates the rule that `[x]` must be literally
true.

**Fix:** split or uncheck both boxes. If you keep the checkbox but want the
deferral to be visible, rephrase to `VERSION bumped; CHANGELOG entry added; tag
push deferred to user (per dispatcher note)` — that's an honest single line.

### B4 — `[x] ... all green on CI post-merge` overclaims local runs as CI results

**Type:** card-structure / checkbox integrity (gate-1). Minor, but worth naming.

The AC row `- [x] tests/tts.bats, tests/tts-native.bats, tests/tts-native.Tests.ps1, and tests/adapters-windows.Tests.ps1 all green on CI post-merge.` is ticked based on the executor's local-worktree test runs. Local green is evidence, not CI green, and the card's own phrasing says "on CI post-merge."

The sprint has had multiple successful prior CI passes (on as44cd, dpyzoo, xuloxu, 7cb15g merges), so there is credible confidence the suites will pass post-merge — but the strict claim is still inaccurate until CI runs against the merged sprint branch.

**Fix (light):** either rephrase the checkbox to "all green locally; CI pending merge" or leave the strict check unticked until the sprint merge triggers CI.

### Gate-1 summary

B1 (uncommitted scraps) is the blocker that makes the other issues easy to
address: the same third commit that stages the roadmap + card changes can
include the corrected CHANGELOG.md and re-ticked checkboxes. B2 is a one-line
publication fix. B3 and B4 are prose edits in the card.

## Gate 2 — implementation quality of the three commits

Gate 2 is short because only two substantive commits (`40d925a`, `e63bc41`) touch
production artifacts; `3cbcbe5` adds a 6-line profiling log.

### `40d925a` — voice case-insensitivity assertion tightening

**Assessment: approved.**

This is the w3ciyq planner-cycle-1 follow-up routed to this closeout. The diff is
a single-line assertion change in the existing Describe block at
`tests/tts-native.Tests.ps1:462-470`:

- Before: `$r.Trace.SelectedVoice | Should -Not -BeNullOrEmpty`
- After: `$r.Trace.SelectedVoice | Should -Be $first`

The change is substantive — it closes the exact hole the w3ciyq reviewer-1
FOLLOW-UP L1 called out (an accidental `-contains` → `-ccontains` swap would
regress to the installed canonical voice if the comparison became case-sensitive,
and the old assertion would not notice). The attached comment explains the
rationale in-tree, which is the right thing for an assertion whose strictness
looks non-obvious.

The executor honestly reports that the local Pester run skipped the body of this
test because on this host the first installed SAPI voice happens to be equal to
its upper-case form. That is an accurate read of the test's conditional `-Skip`
guard and does not invalidate the change — the strengthened assertion still
compiles, and it will fire on any CI runner whose voice list has at least one
voice whose canonical form differs from its upper-case form. The BATS suite
doesn't exercise this path at all (Pester-only concern), so the asymmetric
skip-behaviour is expected.

TDD posture: this is a test-strictness improvement on an existing behaviour, not
new production logic, so no "new failing test first" pattern is required.

### `e63bc41` — VERSION + CHANGELOG bump

**Assessment: blocked on B2 (CHANGELOG defect).**

The `VERSION` bump from 2.20.0 → 2.21.0 is correct: TTSNATIVE shipped a new
user-facing feature (three backend implementations, `--list-voices` /
`-ListVoices` enumerations, SAPI5 spaced-name support, awk hardening), so a minor
bump is aligned with CLAUDE.md's release rubric.

The CHANGELOG body content itself is accurate and appropriately scoped to
TTSNATIVE work — the four bullets map 1:1 to shippable deltas that came out of
the sprint (native backends, list-voices, spaced names, awk hardening). Nothing
from the as44cd/dpyzoo/xuloxu/7cb15g work is smuggled in under the wrong version
or inflated beyond what actually landed. No release-theatre bullets.

The defect is structural (B2) — the v2.20.0 header got eaten by the insert. Fix
that and this commit's content is correct.

### `3cbcbe5` — profiling log

**Assessment: benign.**

Six JSONL lines. `total_commands: 0` in the summary reflects the dispatcher's
known worktree-base harness issue (same thing `dds2iv` is filed against), not a
real metric. Not a blocker.

## Sprint-integration pass (dispatcher's focus item #1)

Every sprint card except `j7yapo` (blocked, routed to dds2iv) moved to done
through committed work:

- h027ru — done at `2ed8a6f`
- as44cd — done at `1f00d88` (after `53884c7` implementation + `2fb1a42` installer wiring)
- dpyzoo — done at `1f00d88` (after `98b077f` implementation)
- w3ciyq — done at `c421154` (after `fb3c53d` awk hardening)
- xuloxu — done at `c421154` (after `2d5faf3` Install-HelperScript extraction)
- 7cb15g — done at `c421154` (after `40a5496` timezone fix)
- j7yapo — blocked at `c421154` with documented rationale, routed to gitban feedback `dds2iv`

That is legitimate sprint integration. No card was silently skipped. No "done"
card is missing its implementing commit. The issue is entirely at the closeout
step: the final tie-up commit that should have consolidated the roadmap flip,
retrospective population, and checkbox toggles was never made.

## Retrospective substance (dispatcher's focus item #3)

The populated retrospective has substantive, specific content:

- `What went well` calls out three concrete wins: TDD-first catching a real
  SAPI5 voice-selection design mistake, parallel-executor scope pins allowing
  three concurrent worktrees without merge pain, and awk hardening catching an
  injection surface the ADR missed.
- `What could improve` names two concrete problems: worktree base default
  mismatch with the fork workflow (forces explicit fetch+reset preamble in
  every executor prompt) and the gitignored-SKILL.md edit surface blocking
  j7yapo. Both are routed to gitban feedback card `dds2iv` with the
  recipient-actionable shape.
- `Debt or follow-ups created` names the three backlog cards from the xuloxu
  planner cycle (`bsz84q`, `hfwtv3`, `tzuccg`) with a one-line purpose each, and
  confirms no new debt beyond already-documented macOS and piper+aplay volume
  limitations.

This is not ceremonial; it is the kind of retrospective future sprints will
actually benefit from. Approved as substantive.

## Intentional-deferral list (dispatcher's focus item #4)

The dispatcher's categorization check: 11 unchecked boxes, split into 3
dispatcher-owned / 4 real-hardware / 2 Windows deferrals / 2 j7yapo-linked.

My counting on the card disagrees slightly — I see:
- dispatcher-owned: 4 boxes, not 3 (archive_cards AC, generate_archive_summary
  AC, "Cards archived" completion, "Sprint summary generated" completion — these
  are two semantic actions but each has both an AC and a completion-checklist
  row, so four `[ ]` lines).
- real-hardware: 3 boxes, not 4 (Performance AC, Audibility AC, "Performance +
  audibility smoke checks recorded" completion — the macOS/Linux/Windows split
  is bundled into the single audibility and performance rows, not broken out).
- Windows deferrals: 2 (C1, C2) ✓.
- j7yapo-linked: 2 (Preconditions step 4b, AC j7yapo row) ✓.

Total 11 — the count matches but the internal split is slightly off. Not a
blocker on its own; raising it only because it suggests the dispatcher's mental
model of the card didn't fully match the card's shape. No smuggled-in work was
found — every unchecked box maps to a documented deferral or a downstream
dispatcher action, and nothing that should be done by the executor is being
hidden behind a deferral label.

## BLOCKERS

- **B1** (gate-1 checkbox integrity): Create the missing third commit that
  stages the roadmap flip (`.gitban/roadmap/roadmap.yaml`,
  `.gitban/views/roadmap.html`), the card file's retrospective + toggled
  checkboxes, and does NOT include `.gitban/.viewer-port` or reviewer-inbox
  files.
- **B2** (gate-2 publication defect): Re-insert `## v2.20.0 (2026-04-14)` as a
  heading before the orphaned `### Added / Rich native macOS notifications` block
  in `CHANGELOG.md`. Collapse the double blank line. Commit as a small
  `fix(changelog):` patch.
- **B3** (gate-1 checkbox integrity): Uncheck or rephrase the two boxes that
  claim the v2.21.0 tag has been pushed — the user has not pushed the tag. The
  honest phrasing is "VERSION bumped; CHANGELOG entry added; tag push deferred
  to user per dispatcher note."
- **B4** (gate-1, light): Relax the "all green on CI post-merge" tick to
  "all green locally; CI pending sprint merge" — or leave unchecked until CI
  runs. Minor; fold into the same card edit as B3.

## FOLLOW-UP

- **L1**: The `CHANGELOG.md` v2.20.0 header loss at B2 suggests the
  release-note insertion path is error-prone when done by hand. Consider an
  explicit release-note insertion helper in `scripts/` (or a CLAUDE.md rule
  reminder that the CHANGELOG insertion pattern is "prepend new `## vX.Y.Z`
  heading above the existing most-recent heading, do not replace it"). Not a
  blocker for this sprint; file as backlog if useful.
- **L2**: The unchecked-box count discrepancy (dispatcher said 3+4+2+2, actual
  is 4+3+2+2) suggests the closeout-card template could benefit from explicit
  marking of which boxes are owned by whom. The current card puts owners in
  prose in the Cycle 1 work log; adding an `(owner: dispatcher)` /
  `(owner: post-release-smoke)` tag on each `[ ]` would let the dispatcher's
  split-count be verified at a glance. Backlog-only.

## Close-out actions before approval

Once B1–B4 are addressed, this card is approvable without a second review cycle
on the code — Gate 2 is already clean. Re-run the closeout with:

1. Fix `CHANGELOG.md` per B2.
2. Adjust the two overclaimed tag/CI checkboxes on the card per B3/B4.
3. Create the consolidation commit per B1.
4. Ping the reviewer for a confirmatory pass.

Card status: blocked.
