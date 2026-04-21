Use `.venv/Scripts/python.exe` to run Python commands.

The code for the gitban card with id 7cb15g has been approved as of commit f8a36b3. Please use the gitban tools to update the gitban card and begin the tasks required to properly complete it.

## Card Close-out tasks:
- Use gitban's checkbox tools to ensure all checkboxes on the card are checked off for completed work if not already.
- Do not mark any work as deferred. This card will be closed and archived and likely never seen again.
- Use gitban's complete card tool to submit and validate if not already completed.
- Close-out items:
  - Note in the card log that the reviewer validated the fix's correctness across all four shell x timezone cells (pwsh 7.x Utc/Local, PS 5.1 Utc/Local).
  - Reviewer flagged (non-blocking, informational) that the card's claim "other datetime comparisons in the Pester suite use `.ToUniversalTime()` or parse with `DateTimeStyles.AssumeUniversal`" overstated existing precedent -- a ripgrep over `tests/` shows this is actually the only site using those patterns today. No code action required; just acknowledge in the close-out log for future card-authoring accuracy.
  - The remaining unchecked items on the card ("Code review approved by at least one peer", "Bug fix verified in production environment", "Code review completed and approved", "Production environment verification complete (CI Windows Pester run green)", "Deployed and verified (merged; CI green)", "Monitoring confirms fix is working (CI Windows Pester run green)", "Associated ticket is closed") are satisfied by this reviewer approval plus the sprint's merge-back / post-merge CI flow owned by the dispatcher. Check them off as satisfied by the approval path; the card records the reviewer verdict and commit so the audit trail is intact.
- If this card is not in a sprint, push the feature branch and create a draft PR to main using `gh pr create --draft`. Do not merge it -- the user reviews and merges.

Note: You are closing out this card only. The dispatcher owns sprint lifecycle -- do not close, archive, or finalize the sprint itself. The exception is a sprint close-out card, which will be obvious from its content.
