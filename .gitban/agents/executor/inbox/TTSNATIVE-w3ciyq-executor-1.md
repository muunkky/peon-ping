Use `.venv/Scripts/python.exe` to run Python commands.

The code for the gitban card with id w3ciyq has been approved as of commit fb3c53d. Please use the gitban tools to update the gitban card and begin the tasks required to properly complete it.

## Card Close-out tasks:
- Use gitban's checkbox tools to ensure all checkboxes on the card are checked off for completed work if not already.
- Do not mark any work as deferred. This card will be closed and archived and likely never seen again.
- Use gitban's complete card tool to submit and validate if not already completed.
- Close-out items:
  - The four "Deferred Work Review" bookkeeping checkboxes at the top of the card were intentionally left unchecked by Cycle-1 ("leave for gvleuv"). Per router guidance, no work can be deferred on close-out: tick those four boxes now. Your Cycle-1 evidence already satisfies them — you reviewed commit messages, PR/reviewer notes, and the code for TODO/FIXME markers while executing the five Items, and there is no team chat to check for this solo sprint. Tick them as part of this close-out.
  - Tick the template checkboxes in the Cleanup Scope & Context, Documentation Updates, Testing & Quality, Code Quality & Technical, Acceptance Criteria, and Completion Checklist sections that are satisfied by the actual work on this card. The reviewer verified all five Items are implemented with real tests, scope is clean, tests pass (Pester 40/40 local + macOS CI will run BATS on merge-back), and no new warnings were introduced. Every box on this tracker that is actually satisfied must be ticked before completion.
- This card is in the TTSNATIVE sprint. Do not push a branch or open a PR for this card — the sprint merge-back is handled by the sprint closeout card (gvleuv).

Note: You are closing out this card only. The dispatcher owns sprint lifecycle — do not close, archive, or finalize the sprint itself.
