Use `.venv/Scripts/python.exe` to run Python commands.

The code for the gitban card with id dpyzoo has been approved as of commit 6e004b8. Please use the gitban tools to update the gitban card and begin the tasks required to properly complete it.

## Card Close-out tasks:
- Use gitban's checkbox tools to ensure all checkboxes on the card are checked off for completed work if not already. At review time the reviewer confirmed every `[x]` box maps to a real artifact; the only remaining unchecked boxes are the two deferred sprint-level observables (`peon notifications test` capstone and `+/-50ms` latency regression) and the downstream completion-checklist boilerplate (Integration Tests Pass, Code Review Approved, Deployment Plan Ready, deployed to production, monitoring, stakeholders notified, epic closed). These are not this card's to complete — they belong to the sprint close-out card `gvleuv`. Leave them unchecked and do not attempt to tick them here.
- Do not mark any work as deferred. This card will be closed and archived and likely never seen again. The deferred sprint-level observables above are being routed to the planner for addition to `gvleuv` (sprint close-out) — that is their home, not a deferral on this card.
- Use gitban's complete card tool to submit and validate if not already completed. If the validator complains about the unchecked sprint-close-out observables, surface the error back to the router — do not silence it by ticking boxes that are not actually satisfied.
- Close-out items: none for this card beyond the checkbox/complete step above. Commit any disk-side card-state mutations produced by the close-out cycle (card checkbox toggles, executor log) on `sprint/TTSNATIVE` so the audit trail is reproducible from git.
- If this card is not in a sprint, push the feature branch and create a draft PR to main using `gh pr create --draft`. Do not merge it — the user reviews and merges.

Note: You are closing out this card only. The dispatcher owns sprint lifecycle — do not close, archive, or finalize the sprint itself. The exception is a sprint close-out card, which will be obvious from its content. This card is step 3 of the TTSNATIVE sprint; closeout is owned by `gvleuv` (step 5).
