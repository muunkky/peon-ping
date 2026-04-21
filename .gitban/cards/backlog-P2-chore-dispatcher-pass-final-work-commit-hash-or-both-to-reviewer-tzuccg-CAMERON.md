
# Dispatcher: pass final-work commit hash (or both) to reviewer

**Type:** chore | **Scope:** dispatcher skill / orchestration

## Task Overview

On `xuloxu` (TTSNATIVE step 4c), the dispatcher passed commit `d9a988f` as the review target, but that was the profiling-log-only follow-up commit — the substantive refactor lived at `2d5faf3`. The reviewer had to walk the log to find the diff of interest, which is wasted time that compounds across every reviewed card.

**Goal:** Update the dispatcher skill so that when it enqueues a reviewer, it passes either (a) the final-work commit hash at HEAD of the card's feature branch at review time, or (b) both the work commit and any trailing log/metadata commits with explicit labels.

**Recommended approach:** (a) — HEAD of the feature branch is almost always what the reviewer actually needs. The trailing log commits are invariably bookkeeping that the reviewer can scan on demand. This is a minor orchestration polish that improves reviewer efficiency on every card going forward.

**Scope:**
- `.claude/skills/dispatcher/SKILL.md` — update the reviewer-dispatch instructions so the hash it passes is documented as "HEAD of the feature branch at review time" (not "latest commit on main" or "most recent worktree commit", both of which can pick up log-only commits).
- `.claude/skills/reviewer/SKILL.md` — if the contract is documented there, update the reviewer prose to match.
- Any dispatcher helper script that resolves the commit hash (search for `git rev-parse`, `git log -1`, `HEAD` references in `.claude/skills/dispatcher/`).

**Out of scope:**
- Rewriting the dispatcher skill's overall orchestration. This is a targeted hash-resolution fix.
- Reviewing past cards with the corrected hash.

## Work Log

- [ ] Read `.claude/skills/dispatcher/SKILL.md` to find the reviewer-dispatch block and identify where the commit hash is resolved and embedded in the reviewer inbox file.
- [ ] Confirm the current resolution logic (e.g., does it use `git log -1`, `git rev-parse HEAD`, or something else? Does the worktree's HEAD reflect the feature branch or main?).
- [ ] Patch the resolution to capture HEAD of the card's feature branch at review time (i.e., the commit the reviewer should diff against the branch point with `main`).
- [ ] Alternatively / additionally: pass both the work commit AND the trailing commit range, labelled (`Work commit: <sha>`, `Trailing metadata: <sha..sha>`), so the reviewer can quickly decide which matters.
- [ ] Update `.claude/skills/dispatcher/SKILL.md` prose to document the new contract.
- [ ] If reviewer contract docs live elsewhere (`.claude/skills/reviewer/SKILL.md`), update those too.
- [ ] Smoke-test: dispatch a trivial reviewer cycle on a throwaway card; verify the inbox file references the correct feature-branch HEAD.

## Completion & Follow-up

- [ ] Dispatcher reviewer-dispatch contract updated.
- [ ] Reviewer-side docs updated (if applicable).
- [ ] Smoke-test confirms the reviewer inbox references the correct commit.
- [ ] Commit: `chore(dispatcher): pass feature-branch HEAD to reviewer, not worktree HEAD`.

## Notes

Source: reviewer-1 finding L3 on `xuloxu` (TTSNATIVE step 4c). Router inbox: `.gitban/agents/planner/inbox/TTSNATIVE-xuloxu-planner-1.md`.

Concrete example from `xuloxu`:
- Work commit: `2d5faf3` (the Install-HelperScript refactor itself)
- Trailing log commit: `d9a988f` (agent profiling log only)
- Dispatcher passed `d9a988f`, the reviewer had to walk `git log` to find `2d5faf3`.

Routed to backlog (not TTSNATIVE sprint) per explicit user guidance: the TTSNATIVE sprint is near closeout (only `gvleuv` remains) and this is a cross-cutting orchestration fix that benefits all future sprints, not a TTS-native regression. Pick up post-sprint.



## Work Log

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Review Current State** | Read `.claude/skills/dispatcher/SKILL.md`; identify how the commit hash is currently resolved for reviewer dispatch (grep for `git rev-parse`, `git log -1`, `HEAD`). | - [ ] Current state is understood and documented. |
| **2. Plan Changes** | Decide between option (a) HEAD of feature branch, or (b) pass both work commit and trailing metadata commits with labels. Recommendation: (a). | - [ ] Change plan is documented. |
| **3. Make Changes** | Patch dispatcher helper(s) to resolve HEAD of the card's feature branch at review time. Update SKILL.md prose to document the new contract. | - [ ] Changes are implemented. |
| **4. Test/Verify** | Smoke-test: dispatch a trivial reviewer cycle on a throwaway card; verify the inbox file references the correct feature-branch HEAD and not a log-only trailing commit. | - [ ] Changes are tested/verified. |
| **5. Update Documentation** | `.claude/skills/dispatcher/SKILL.md` prose; `.claude/skills/reviewer/SKILL.md` if contract is cross-referenced there. | - [ ] Documentation is updated [if applicable]. |
| **6. Review/Merge** | Self-review + commit. | - [ ] Changes are reviewed and merged. |

## Completion & Follow-up

| Task | Detail/Link |
| :--- | :--- |
| **Changes Made** | Dispatcher now passes feature-branch HEAD (or both work + trailing commits with labels) to reviewer. |
| **Files Modified** | `.claude/skills/dispatcher/SKILL.md`; possibly `.claude/skills/reviewer/SKILL.md` and any dispatcher helper scripts. |
| **Pull Request** | Single commit: `chore(dispatcher): pass feature-branch HEAD to reviewer, not worktree HEAD`. |
| **Testing Performed** | Trivial reviewer-cycle smoke test verified inbox references correct commit. |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Related Chores Identified?** | Check whether planner/executor dispatch paths have the same hash-resolution ambiguity. |
| **Documentation Updates Needed?** | Dispatcher + reviewer SKILL.md updated as part of this card. |
| **Follow-up Work Required?** | None expected. |
| **Process Improvements?** | Document the commit-hash contract explicitly so future skill edits preserve it. |
| **Automation Opportunities?** | n/a. |

### Completion Checklist

- [ ] All planned changes are implemented.
- [ ] Changes are tested/verified (reviewer-cycle smoke test).
- [ ] Documentation is updated (dispatcher/reviewer SKILL.md).
- [ ] Changes are reviewed (self-review or gitban reviewer as appropriate).
- [ ] Pull request is merged or changes are committed.
- [ ] Follow-up tickets created for related work identified during execution.
