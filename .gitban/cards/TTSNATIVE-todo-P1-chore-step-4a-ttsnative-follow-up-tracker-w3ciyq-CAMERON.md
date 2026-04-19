
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
