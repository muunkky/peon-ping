Use `.venv/Scripts/python.exe` to run Python commands.

The code for the gitban card with id p7hchj has been approved as of commit 3630dfd. Please use the gitban tools to update the gitban card and begin the tasks required to properly complete it.

## Card Close-out tasks:
- Use gitban's checkbox tools to ensure all checkboxes on the card are checked off for completed work if not already.
- Do not mark any work as deferred. This card will be closed and archived and likely never seen again.
- Use gitban's complete card tool to submit and validate if not already completed.
- Close-out items:
  - **L1**: In `install.ps1`, the `Play-Sound` helper's `elseif ($peonDebug)` only fires when `$winPlayScript` is missing. Add a second debug branch (or expand the existing one) to also log when `$SndPath` doesn't exist. This is a one-line diagnostic fix.
  - **L2**: In `install.ps1`, the first TTS block (~line 1730) lacks the explanatory comment that the second TTS block (~line 2108) has, explaining why `$ttsEnabled` omits the `(-not $paused)` guard (because `$config.enabled` gates the entire hook earlier). Add a brief comment matching the one at line 2108.
  - **L3**: In `install.ps1`, the template variable construction is duplicated between the notification template rendering (~lines 1710-1725) and TTS text resolution (~lines 1889-1899). Add a code comment noting this intentional duplication and that it should be consolidated into a shared `$tplVars` hashtable if the area is touched again. (Do not refactor now -- just document the intent.)
- If this card is not in a sprint, push the feature branch and create a draft PR to main using `gh pr create --draft`. Do not merge it -- the user reviews and merges.
