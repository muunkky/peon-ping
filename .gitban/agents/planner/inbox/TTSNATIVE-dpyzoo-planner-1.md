The reviewer flagged 4 non-blocking items + 2 sprint-close-out observables, grouped into 4 cards below.
Create ONE card per group. Do not split groups into multiple cards.
The planner is responsible for deduplication against existing cards.
All cards go into the current sprint unless marked BLOCKED with a reason.

Note: The TTSNATIVE sprint already carries:
- A follow-up tracker card (`w3ciyq` -- "TTSNATIVE follow-up tracker"). If an item fits that tracker's aggregation scope per planner/SKILL.md, append it there rather than creating a new card.
- A sprint close-out card (`gvleuv` -- "step-5-ttsnative-sprint-closeout"). The reviewer explicitly routed two deferred observables (Group D below) to `gvleuv` -- append them there rather than creating a new card.

### Card 1: TTSNATIVE follow-up tracker -- tts-native.ps1 additional test coverage
Sprint: TTSNATIVE
Files touched: `tests/tts-native.Tests.ps1` (additive only; script `scripts/tts-native.ps1` is not modified)
Append target: `w3ciyq` (aggregation tracker) -- both items are small additive Pester tests in the same file. They fit the aggregation tier. If planner/SKILL.md's current append criteria reject the aggregation, fall back to a single standalone card for both items combined.
Items:
- L1: Production-pipeline invocation path is not unit-tested. `Invoke-TtsSpeak` in `install.ps1` invokes `tts-native.ps1` through a native PowerShell pipeline (`| & '$scriptPath' -voice ... -rate ... -vol ...`) that binds to `$InputText` via `ValueFromPipeline`. Every existing test uses `powershell -File` with redirected stdin, which exercises only the `[Console]::IsInputRedirected` fallback. Add a single test that shells `powershell -Command "'hello' | & 'tts-native.ps1' ..."` (with `PEON_TTS_DRY_RUN=1` and `PEON_TTS_TRACE_FILE=<path>`) and asserts `$trace.Text -eq "hello"`. Closes the gap between the DoD smoke form and the production invocation path.
- L3: Voice name matching case-sensitivity is not asserted. `-contains` is case-insensitive in PowerShell so the behaviour is already correct, but the inline comment in `tts-native.ps1`'s voice-selection block and the design doc's Risks section both flag case sensitivity as a potential concern. Add a one-line test asserting `-Voice "MICROSOFT DAVID DESKTOP"` (or the uppercase form of any installed voice discovered at test runtime) still resolves to the proper `Microsoft David Desktop` match. Codifies the behaviour as intended rather than accidental. Must be skip-guarded via `Set-ItResult -Skipped` when no SAPI voices are installed, matching the existing voice-dependent tests in the same file.

### Card 2: Extract `Install-HelperScript` helper in install.ps1
Sprint: TTSNATIVE
Files touched: `install.ps1` (lines ~284/299/314 -- three copy-or-download blocks), `tests/adapters-windows.Tests.ps1` (the existing "install.ps1 installs tts-native.ps1 alongside win-notify.ps1" assertion and the sibling `win-play.ps1` / `win-notify.ps1` install assertions may need trivial update if the install-block shape changes)
Items:
- L2: `install.ps1`'s new `tts-native.ps1` install block is the third identical copy-or-download scaffold in ~40 lines (`win-play.ps1`, `win-notify.ps1`, `tts-native.ps1` at lines 284 / 299 / 314). Pattern is begging for a helper -- `Install-HelperScript -Name 'tts-native.ps1' -LocalSource $scriptPath -RemoteUrl $remoteUrl -DestDir $installDir` or similar. Pre-existing DRY violation, not introduced by this card, but this card's addition is the third instance and the tipping point. Standalone tech-debt card: refactor the three blocks into one helper function, update all three call-sites, ensure `tests/adapters-windows.Tests.ps1` structural assertions for all three installed files still pass (file exists, no ExecutionPolicy Bypass, etc.). Must not change the external behaviour of `install.ps1` -- local install still copies from repo, remote install still downloads via one-liner, failure still warns not throws.

### Card 3: Fix peon-engine.Tests.ps1 timezone parsing failure in test harness
Sprint: TTSNATIVE
Files touched: `tests/peon-engine.Tests.ps1` (line ~112, `Harness: New-PeonTestEnvironment.accepts StateOverrides`) and possibly the harness module itself if the fix is in the state-override datetime parsing rather than the test assertion
Items:
- L4: Pre-existing Pester test failure, surfaced by the `dpyzoo` executor during broader regression sweep. The test compares `[datetime]"2026-01-01T00:00:00Z"` on the LHS (parsed as UTC `DateTime`) with the RHS (parsed in the local timezone). `Should -Be` compares with timezone awareness, so the expected value is interpreted as local time while the actual value is UTC and the comparison fails with `Expected 2025-12-31T17:00:00.0000000-07:00, but got 2026-01-01T00:00:00.0000000Z`. Fix is likely one of: (a) use `[datetime]::Parse("...", $null, [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal)` on both sides, (b) compare `.ToUniversalTime()` on both sides before `Should -Be`, or (c) use `Should -BeLikeExactly` on the `.ToString("o")` representation. Not this card's (dpyzoo's) code, but it is a silent time-bomb in the Windows Pester suite that will confuse future executors. Standalone defect card.

### Card 4: TTSNATIVE sprint close-out -- deferred tts-native.ps1 observables
Sprint: TTSNATIVE
Files touched: none in code -- this is an append to the existing sprint close-out card's observables
Append target: `gvleuv` (TTSNATIVE sprint close-out, step 5). The reviewer explicitly routed these two items to `gvleuv` in the approval review's "Close-out actions before card -> done" section -- they are sprint-level end-to-end checks that cannot run from a worktree with no installed peon-ping.
Items:
- C1: Manual DoD -- `peon notifications test` with `tts.enabled: true` on an installed Windows peon-ping must produce spoken output through the full `Invoke-TtsSpeak -> tts-native.ps1` path. This is the second manual capstone from dpyzoo's Acceptance Criteria; it was left unchecked by the executor because the worktree has no installed peon-ping. Verify post-merge on a real Windows 10 or 11 install.
- C2: Hook return latency regression check -- `[exit] duration_ms` with `tts.enabled: true` must stay within +/-50ms of the `tts.enabled: false` baseline. This is the TDD workflow Performance row + the final Acceptance Criteria entry from dpyzoo; same deferral reason as C1. Measure on the same installed environment.
