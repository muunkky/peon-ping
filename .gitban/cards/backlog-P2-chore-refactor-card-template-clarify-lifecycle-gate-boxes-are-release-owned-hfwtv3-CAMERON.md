
# Refactor card template: clarify lifecycle-gate boxes are release-owned

**Type:** chore | **Scope:** gitban templates

## Task Overview

The `refactor` gitban card template (`.gitban/templates/refactor.md`) contains Completion Checklist and workflow-table rows that describe lifecycle stages the executor cannot complete from within a worktree — e.g., `Refactored code validated on a real Windows host via manual install smoke test` (Staging Validation) and `Production deployment successful with monitoring`.

On `xuloxu` (TTSNATIVE step 4c), the executor ticked these as `[x]` at card completion time, creating a low-grade Gate 1 trap: ticked-but-not-actually-done boxes. The template's upstream version currently ships these boxes as `[ ]` (empty), but it is silent about *who* is responsible for ticking them and when, so executors may — and on `xuloxu` did — tick them alongside the rest of the Completion Checklist.

**Goal:** Update `.gitban/templates/refactor.md` so the lifecycle-gate rows carry an inline disambiguation comment (e.g., `# ticked by release runbook, not by executor` or `> Leave unchecked at card completion — ticked post-release`), so the card author must consciously decide whether to tick them or leave them for the release flow.

**Scope:**
- `.gitban/templates/refactor.md` — add inline comments to the following rows (verify line numbers at the time of work; line numbers drift):
  - Refactoring Phases table: `Staging Deployment`, `Production Deployment`
  - Safe Refactoring Workflow table: step 12 (`Deploy to Staging`), step 13 (`Production Deployment`)
  - Refactoring Validation & Completion table: `Staging Validation`, `Production Deployment`
  - Completion Checklist: `Refactored code validated in staging environment`, `Production deployment successful with monitoring`
- Consider similar pass on `feature.md`, `bug.md`, `feature-api.md`, `feature-ui.md`, `feature-infrastructure.md`, `refactor-large.md`, `performance.md`, `bug-infrastructure.md` — any template with Staging/Production rows. Apply the same pattern if consistent.

**Out of scope:**
- Changing the rows' semantic (keep the completion-checklist entry — don't remove release gates).
- Rewriting the upstream gitban template library. This is a project-local `.gitban/templates/` change only.

## Work Log

- [ ] Audit `.gitban/templates/refactor.md` for lifecycle-gate boxes and confirm current `[ ]` default state.
- [ ] Draft inline-comment text that disambiguates executor-time vs release-time ticking.
- [ ] Apply the same pattern to the other templates listed in scope (feature, bug, performance, etc.) — only where the row describes a deployment/release-time gate.
- [ ] Smoke-test by creating a draft card from the updated template: the Completion Checklist should render with the inline comments visible in the gitban viewer / card preview.
- [ ] Verify no existing `create_card` / `move_to_todo` validation breaks on the new comment syntax (the inline comment must not be parsed as a heading or bullet that changes the section structure).

## Completion & Follow-up

- [ ] `.gitban/templates/refactor.md` updated and committed.
- [ ] Related templates updated consistently (or explicitly decided not to, with rationale).
- [ ] One fresh refactor card created from the updated template to verify the executor-facing wording is clear (can be a disposable draft).
- [ ] Commit: `chore(templates): disambiguate lifecycle-gate checkboxes in refactor/feature/bug templates`.

## Notes

Source: reviewer-1 finding L2 on `xuloxu` (TTSNATIVE step 4c). Router inbox: `.gitban/agents/planner/inbox/TTSNATIVE-xuloxu-planner-1.md`.

**Correction to the reviewer note:** The reviewer's finding states the template "ships Completion Checklist entries like `[x] Refactored code validated...` pre-ticked." Inspection of `.gitban/templates/refactor.md` shows these rows ship as `[ ]` (empty). The actual issue is that the template is silent about who owns those checkboxes, not that it pre-ticks them. The executor on `xuloxu` ticked them to close the card. This card still addresses the underlying concern — add inline comments so the ownership is unambiguous at card-fill time.

Routed to backlog (not TTSNATIVE sprint) per explicit user guidance: the TTSNATIVE sprint is near closeout (only `gvleuv` remains) and this is cross-cutting template hygiene that affects all future refactor cards, not a TTS-native regression. Pick up post-sprint.



## Work Log

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Review Current State** | Audit `.gitban/templates/refactor.md` for lifecycle-gate boxes (Staging/Production rows) and confirm current `[ ]` default. | - [ ] Current state is understood and documented. |
| **2. Plan Changes** | Draft inline-comment text that disambiguates executor-time vs release-time ticking (e.g., `# ticked by release runbook, not by executor`). | - [ ] Change plan is documented. |
| **3. Make Changes** | Apply the comment to the Refactoring Phases, Safe Refactoring Workflow, Refactoring Validation & Completion, and Completion Checklist sections. Extend to feature/bug/performance templates where the pattern fits. | - [ ] Changes are implemented. |
| **4. Test/Verify** | Smoke-test by creating a fresh draft card from the updated template; confirm the inline comments render in the gitban viewer and don't break `move_to_todo` validation. | - [ ] Changes are tested/verified. |
| **5. Update Documentation** | n/a — template-internal comments are the documentation. | - [ ] Documentation is updated [if applicable]. |
| **6. Review/Merge** | Gitban reviewer + commit. | - [ ] Changes are reviewed and merged. |

## Completion & Follow-up

| Task | Detail/Link |
| :--- | :--- |
| **Changes Made** | Inline comments added to lifecycle-gate rows across refactor/feature/bug/performance templates. |
| **Files Modified** | `.gitban/templates/refactor.md` primary; others as scoped. |
| **Pull Request** | Single commit or PR per `RELEASING.md`. |
| **Testing Performed** | Fresh draft card created from updated template; validator accepts; viewer renders comments. |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Related Chores Identified?** | Check whether the same ownership ambiguity exists in other deployment-gated sections of the templates. |
| **Documentation Updates Needed?** | None beyond the template comments. |
| **Follow-up Work Required?** | None expected — this is a one-off template hygiene pass. |
| **Process Improvements?** | Consider a linter that flags `[x]` on rows whose comment marks them release-owned. |
| **Automation Opportunities?** | n/a. |

### Completion Checklist

- [ ] All planned changes are implemented.
- [ ] Changes are tested/verified (fresh draft card; validator + viewer).
- [ ] Documentation is updated (inline comments within templates).
- [ ] Changes are reviewed (self-review or gitban reviewer as appropriate).
- [ ] Pull request is merged or changes are committed.
- [ ] Follow-up tickets created for related work identified during execution.
