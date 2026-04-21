Use `.venv/Scripts/python.exe` to run Python commands.

The code for the gitban card with id as44cd has been approved as of commit 58f72a6. Please use the gitban tools to update the gitban card and begin the tasks required to properly complete it.

## Card Close-out tasks:
- Use gitban's checkbox tools to ensure all checkboxes on the card are checked off for completed work if not already.
- The two manual-DoD capstones on the card (real Mac/Linux smoke + `peon notifications test` hook-latency check) are **correctly deferred to release-time smoke on macOS/Linux runners** and must remain unchecked. Do NOT check them — leave them as intentional handoff items for pre-release verification. The reviewer explicitly affirmed this in the approval report. Mark these as deferred in the card close-out notes if the gitban tooling supports that, otherwise just leave them unchecked with a comment.
- The "Code Review Approved" and "Deployment Plan Ready" rows under "Feature Work Phases" and the "Performance Testing" row under "TDD Implementation Workflow" are legitimately checkable: code review approved = this approval; deployment plan ready = merge to main picks it up; performance testing was deferred by the reviewer to release smoke. Check the code-review row and leave the performance/deployment rows honest (unchecked where they depend on deferred manual work).
- Also leave all items under the card's final "Completion Checklist" unchecked that depend on the deferred manual work (production deployment, monitoring, stakeholder notification). Check only what's actually true.
- Do not mark any work as deferred inside the gitban complete-card flow. This card will be closed and archived and likely never seen again.
- Use gitban's complete card tool to submit and validate if not already completed.
- This card is part of the TTSNATIVE sprint. Do NOT push a branch or open a PR — the sprint dispatcher owns sprint-level merging.

Close-out items (from reviewer's approval close-out actions):
- Item 1 (manual Mac/Linux smoke, `peon notifications test` latency check): correctly deferred — document in close-out notes that these are release-smoke handoffs, but do not open a follow-up card (they belong to the existing manual DoD on this card and the sprint's release-readiness).
- Item 2 (full `bats tests/` regression on macOS CI runner to confirm `tts.bats` still passes alongside new `tts-native.bats`): this will happen automatically when the sprint PR hits CI — no action required at card close-out. The executor could not run this locally due to a pre-existing `/usr/bin/python3` hardcode in `tests/setup.bash:438` that is unrelated to this card; the planner is handling that hygiene follow-up separately.
- Item 3 (no new ADR required): confirmed.

Note: You are closing out this card only. The dispatcher owns sprint lifecycle — do not close, archive, or finalize the sprint itself. The exception is a sprint close-out card, which will be obvious from its content.
