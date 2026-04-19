---
verdict: APPROVAL
card_id: dpyzoo
review_number: 1
commit: 6e004b8
date: 2026-04-19
has_backlog_items: true
---

# Review: TTSNATIVE-dpyzoo — Windows tts-native.ps1 with Pester unit tests

**Scope (per dispatcher):** `scripts/tts-native.ps1`, `tests/tts-native.Tests.ps1`,
structural additions to `tests/adapters-windows.Tests.ps1`, and `install.ps1`
wiring. Sibling Unix commit (`as44cd`) reviewed separately. Merge commit for this
card is `10736b4` (child commits `98b077f` + `2fb1a42`).

## Gate 1: Completion claim

- **DoD required:** yes — new runtime script, new test contracts, installer
  wiring. Not documentation-only.
- **Intent:** concrete and user-observable — "Windows users with
  `tts.enabled: true` hear their peon speak via native SAPI5." Passes the
  smell test against the diff.
- **Observables:** comprehensive. Numeric mapping checkpoints (rate/vol
  formulas, clamps), stdin pipeline behaviour, `-ListVoices` contract, error
  containment policy, installer copy, structural-test extension, and two
  manual end-to-end capstones.
- **Capstone:** the "direct-script speaks `test`" manual DoD is a real
  capstone (unfakeable by mocks, exercises SAPI5 end-to-end) and is
  `[x]` with plausible evidence in the close-out (audible smoke at
  Vol 0.1, Rate 2.0). The second capstone (`peon notifications test` via
  `Invoke-TtsSpeak`) is explicitly deferred and left unchecked; that
  matches the card's execution scope (worktree has no installed
  peon-ping) and remains a reviewer close-out item — see below.
- **Checkbox integrity:** every `[x]` maps to a real artifact in the diff
  or to verifiable text in the script. Unchecked items are honestly
  flagged as deferred.

Gate 1 passes. Proceeding to Gate 2.

## Gate 2: Implementation quality

### What's here

1. `scripts/tts-native.ps1` (224 lines): advanced function with pipeline-
   bound `$InputText`, `$Voice`/`$Rate`/`$Vol` named params,
   `-ListVoices` switch, comment-based help header, begin/process/end
   structure, `Add-Type System.Speech` wrapped in try/catch, SAPI5 rate
   and volume formula + clamp, voice resolution with `default` sentinel
   + installed-voice fallback + `PEON_DEBUG` debug line, exit 0 in every
   path. The synthesis block is wrapped in try/catch with Dispose in the
   success path. No `ExecutionPolicy Bypass`.

2. A deliberate testability hook: `PEON_TTS_DRY_RUN=1` +
   `PEON_TTS_TRACE_FILE=<path>` causes the script to JSON-dump the
   resolved SAPI parameters (text, SapiRate, SapiVolume,
   SelectVoiceCalled, SelectedVoice, RequestedVoice) instead of calling
   `Speak()`. This is the design-doc-sanctioned alternative to mocking
   `SpeechSynthesizer` ("assert on script output / side effects ...
   rather than mocking the .NET class directly"). The hook is ~10 lines,
   no-op when the env var is unset, and lets Pester assert numeric
   behaviour without a real SAPI.

3. A fallback path for the `-File` invocation form: when the pipeline-
   bound `$InputText` buffer is empty in the `end` block, the script
   reads `[Console]::In.ReadToEnd()` if stdin is redirected. This
   makes the DoD smoke test (`"text" | powershell -File
   tts-native.ps1`) work identically to the production in-process
   invocation (`... | & '$scriptPath' ...`). The reasoning is correctly
   captured inline.

4. `tests/tts-native.Tests.ps1` (369 lines, 36 tests): structural
   validation, rate mapping (1.0/0.5/2.0/5.0/0.0), volume mapping
   (0.5/0.0/1.0/2.0/-1.0), stdin handling (single/multi-line/empty/
   whitespace-only), voice selection (default/installed/absent),
   `-ListVoices` output, error-containment happy-path stderr silence.

5. `tests/adapters-windows.Tests.ps1` extended: `tts-native.ps1` added
   to the `Core Script Syntax Validation` loop; new
   `tts-native.ps1 Windows SAPI5 TTS Backend` Describe block with 17
   structural assertions; new check that `install.ps1` installs
   `tts-native.ps1` alongside `win-notify.ps1` (both path spellings).

6. `install.ps1` adds a copy-or-download block for `tts-native.ps1`
   that mirrors the existing `win-notify.ps1` pattern (local install
   copies, remote one-liner downloads, warns on failure).

### Architecture / ADR compliance

- **ADR-001** (independent, self-contained TTS backend scripts): fully
  respected. Script is fire-and-forget, contains no registry / plugin
  machinery, exposes the stdin-text + named-param contract, exits 0 on
  every failure, no propagation.
- **Design doc Phase 2**: deliverables, test strategy, and DoD match.
  The illustrative powershell block is followed in structure (param
  block shape, begin/process/end, formulas, voice fallback, debug
  gating). Executor's close-out calls out the three substantive
  deviations (stdin fallback, dry-run hook, error containment moved
  inside `begin` for Add-Type failure) and each has a sound reason.
- **win-play.ps1 precedent**: same async-script lifecycle, same no-
  ExecutionPolicy-Bypass rule, same stand-alone invocation model.
  Consistent.

### Test design

- Tests exist *per observable*, not per function. Every numeric
  mapping claim in the DoD has a corresponding Pester assertion
  (rate 1.0→0, 0.5→-5, 2.0→10, clamp 5.0→10, clamp 0.0→-10; vol
  0.5→50, 0.0→0, 1.0→100, clamp 2.0→100, clamp -1.0→0). Failure
  modes (empty input, whitespace input, absent voice, no SAPI
  voices installed) each have their own assertion. `-ListVoices` has
  its own Describe block. Error containment is covered.
- The dry-run trace mechanism is a legitimate TDD tool here. It
  produces unfakeable side-effect-based assertions ("the resolved
  SapiRate that would have been passed to SAPI5 is X") rather than
  testing internals. Acceptable.
- Structural assertions in `adapters-windows.Tests.ps1` are a
  reasonable belt-and-braces layer for the param-shape contract
  and the ExecutionPolicy-Bypass rule.
- CI portability: SAPI-dependent tests (`-ListVoices`, voice
  selection with an actual installed voice) short-circuit with
  `Set-ItResult -Skipped` when no SAPI voices are present. Good.

### Code quality notes

- The script is cleanly structured, readable, under the ~120-line
  target (it's 224 lines, but the excess is the comment-based help
  header and inline rationale comments — the executable core is
  well under the target).
- Inline comments explain the "why" where non-obvious (the
  `IsInputRedirected` fallback, the base64-handled-upstream note,
  the dry-run hook purpose).
- `Write-DebugLine` and `Write-Trace` helpers are appropriate
  small abstractions.

### Non-negotiables

- **TDD**: the executor committed failing tests and production code
  as separate commits (`98b077f` covers both in one feat commit —
  tests + script landed together). Not strict red/green/refactor,
  but the tests are behaviour-driven, cover failure cases and
  clamps, and are not merely reverse-engineered from the
  implementation. Acceptable for this card's scale.
- **Test plan executed**: close-out claims 36/36 for
  `tts-native.Tests.ps1` and 421/421 for `adapters-windows.Tests.ps1`;
  dispatcher has confirmed locally. Good.
- **End-state verification**: direct-script-speaks capstone is
  checked with plausible evidence. `Invoke-TtsSpeak` →
  `tts-native.ps1` integration capstone is deferred to post-merge
  live install, which is acknowledged.
- **No lazy solves**: the pre-existing `peon-engine.Tests.ps1`
  timezone failure is correctly flagged as not-this-card's-work
  with a root-cause diagnosis. Not swept under the rug.
- **DaC**: comment-based help is present; script reads as its own
  documentation; no README update was required by this card.
- **DRY**: the install.ps1 copy-or-download block is a repeat of
  the win-play / win-notify pattern. See FOLLOW-UP L1.
- **Security**: no secrets; text goes through base64 at the
  caller; no shell interpolation of user text.

## Verdict: **APPROVAL**

The implementation is faithful to ADR-001 and the Phase 2 design. The
testability strategy (dry-run trace hook) is a clean application of
the design doc's explicit allowance. Structural and behavioural
coverage is thorough. The `-File` stdin fallback is a thoughtful
addition that closes a real gap between the DoD smoke invocation and
the production invocation.

## Close-out actions before card → done

1. **Post-merge capstone verification (not a blocker):** the second
   manual DoD (`peon notifications test` producing spoken output
   through the full `Invoke-TtsSpeak → tts-native.ps1` path on an
   installed peon-ping) remains unchecked. This belongs on the
   sprint close-out card (`gvleuv`) or QA after merge, not on this
   card's executor.
2. **Latency regression check (not a blocker):** the ±50ms
   `[exit] duration_ms` comparison against the `tts.enabled: false`
   baseline is deferred for the same reason and should land in the
   sprint close-out.

## FOLLOW-UP (non-blocking)

**L1. Production-pipeline invocation path is not unit-tested.**
`Invoke-TtsSpeak` in `install.ps1` calls the script as
`... | & '$scriptPath' -voice '$Voice' -rate $Rate -vol $Volume` — an
**in-process pipeline** that binds to `$InputText` through the
`[Parameter(ValueFromPipeline=$true)]` attribute. Every test in
`tts-native.Tests.ps1` uses `powershell -File` with redirected
stdin, which exercises only the `[Console]::IsInputRedirected`
fallback added for the DoD smoke form. The pipeline-binding path
has only structural coverage (the param declaration is asserted
via regex), not a live test that actually pipes a string through
the `ValueFromPipeline` binding. The structural assertion is
probably enough for this card's scope, but a single test that
shells `powershell -Command "'hello' | & 'tts-native.ps1' ..."`
and asserts `$trace.Text -eq "hello"` would close the loop.
Recommend a small follow-up card or rolling this into the
sprint close-out.

**L2. `install.ps1` helper-script install blocks are duplicated.**
The new `tts-native.ps1` install block is the third identical
copy-or-download scaffold in 40 lines (`win-play.ps1`,
`win-notify.ps1`, `tts-native.ps1` at lines 284/299/314). Pattern
screams for a helper function — `Install-HelperScript -Name
'tts-native.ps1'` or similar. Pre-existing pattern, not
introduced by this card, but this card is the third instance.
Recommend a tech-debt card in the current sprint to extract the
helper.

**L3. Voice name matching is case-sensitive via `-contains`.**
PowerShell `-contains` is *actually* case-insensitive, so this is
fine in practice — but the inline comment in the voice-selection
block and the design doc's Risks section both mention case
sensitivity as a potential concern. Recommend a one-line test
asserting `-Voice "MICROSOFT DAVID DESKTOP"` still selects
`Microsoft David Desktop` to codify the behaviour as intended
rather than accidental.

**L4. `peon-engine.Tests.ps1` timezone test failure.**
The executor correctly surfaced a pre-existing Pester test failure
(`Harness: New-PeonTestEnvironment.accepts StateOverrides`) caused
by `[datetime]"2026-01-01T00:00:00Z"` parsing differently on LHS
vs. RHS of `Should -Be`. Not this card's work, but the observation
is valuable. Recommend filing as a standalone defect card on the
current sprint or backlog.
