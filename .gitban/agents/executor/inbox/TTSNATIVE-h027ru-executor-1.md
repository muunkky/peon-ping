Use `.venv/Scripts/python.exe` to run Python commands.

The code for the gitban card with id h027ru has been approved as of commit 081e4c8. Please use the gitban tools to update the gitban card and begin the tasks required to properly complete it.

## Card Close-out tasks:
- Use gitban's checkbox tools to ensure all checkboxes on the card are checked off for completed work if not already. (All 9 checkboxes were already ticked at review time — verify and proceed.)
- Do not mark any work as deferred. This card will be closed and archived and likely never seen again.
- Use gitban's complete card tool to submit and validate if not already completed.
- Close-out items:
  - Commit the disk-side checkbox/work-log changes on `.gitban/cards/TTSNATIVE-...-h027ru-CAMERON.md` alongside or after the profiling log commit so the card's audit trail is reproducible from git. (This is a git-hygiene step — make sure the card-state mutations from the executor cycle are committed on `sprint/TTSNATIVE`.)
- If this card is not in a sprint, push the feature branch and create a draft PR to main using `gh pr create --draft`. Do not merge it — the user reviews and merges.

Note: You are closing out this card only. The dispatcher owns sprint lifecycle — do not close, archive, or finalize the sprint itself. The exception is a sprint close-out card, which will be obvious from its content. This card is step 1 of the TTSNATIVE sprint; closeout is owned by `gvleuv` (step 5).
