---
verdict: APPROVAL
card_id: p7hchj
review_number: 1
commit: 3630dfd
date: 2026-03-28
has_backlog_items: false
---

## Summary

This card ports the TTS engine to the Windows PowerShell hook (`install.ps1`): `Resolve-TtsBackend`, `Invoke-TtsSpeak`, speech text resolution, three-mode sequencing, suppression, and trainer TTS. 275 lines added across two files, 27 new Pester tests, 386 total passing.

The implementation is a faithful port of the design doc's Phase 4 PowerShell code samples. Both functions match the design doc nearly character-for-character. The mode sequencing, text resolution chain, and trainer integration all follow the specified patterns. ADR-001 compliance is solid: independent backend scripts, stdin text transport (via Base64), fire-and-forget `Start-Process`, and separate `.tts.pid` tracking.

## BLOCKERS

None.

## FOLLOW-UP

**L1: `Play-Sound` debug message does not fire when sound file is missing.**

The new `Play-Sound` helper guards on `(Test-Path $winPlayScript) -and (Test-Path $SndPath)`, but the `elseif ($peonDebug)` only fires when `$winPlayScript` is missing. If the sound file path doesn't exist but `win-play.ps1` does, the function silently returns with no debug output. The original code delegated the sound-file-exists check to `win-play.ps1` itself. The new guard is a reasonable defensive addition, but the debug branch should distinguish between the two failure cases or at minimum log when `$SndPath` doesn't exist. Non-blocking because this only affects debug-mode diagnostics.

**L2: Design doc specifies `$ttsEnabled` includes `(-not $paused)` guard; implementation omits it.**

The design doc (line 482) defines `$ttsEnabled = ($ttsCfg.enabled -eq $true) -and (-not $paused)`. The implementation uses `$ttsEnabled = ($ttsCfg.enabled -eq $true)` without the paused check. This is actually correct at runtime because `$config.enabled` gates the entire hook at line 1512 (paused sets `enabled = false`, causing early exit before any TTS code runs). The second TTS block at line 2108 has a comment documenting this reasoning. However, the first TTS block at line 1730 lacks the same explanatory comment. Adding a brief note there would prevent future reviewers from flagging the same apparent deviation. Non-blocking.

**L3: Duplicate template variable construction between `$resolvedTemplate` pre-resolution and TTS text resolution.**

Lines 1710-1725 build `$tplSum0`, `$tplTool0` and call `Resolve-NotificationTemplate`. Lines 1889-1899 rebuild the same variables as `$tplSummary`, `$tplToolName` into `$ttsVars`. The summary truncation at 120 chars only appears in the second block (line 1891). This is a mild DRY issue -- the two blocks extract the same fields from `$event` independently. The design doc used a shared `$tplVars` hashtable for both, which would avoid this duplication. Non-blocking because the two blocks serve different purposes (notification template rendering vs. TTS template interpolation) and the duplication is small, but worth consolidating if the area is touched again.
