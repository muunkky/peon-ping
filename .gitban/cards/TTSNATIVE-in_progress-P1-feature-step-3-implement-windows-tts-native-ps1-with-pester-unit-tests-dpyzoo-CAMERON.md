
# Step 3: Implement Windows tts-native.ps1 with Pester unit tests

**Parallel with:** step 2 (`as44cd`). Files are disjoint — step 2 touches `scripts/tts-native.sh`, `tests/tts-native.bats`, and `install.sh`; this card touches `scripts/tts-native.ps1`, `tests/tts-native.Tests.ps1`, `tests/adapters-windows.Tests.ps1`, and `install.ps1`. No code artifact flows between the two. Runtime ordering (MSYS2 branch in `tts-native.sh` delegates to this script when present) is already handled by step 2's "missing `tts-native.ps1` → silent exit 0" acceptance criterion, so there is no sequencing requirement.

**When to use this template:** Feature card for implementing the Windows side of the platform-native TTS backend per `docs/designs/tts-native.md` Phase 2. Produces `scripts/tts-native.ps1` (SAPI5 via `System.Speech.Synthesis`), associated Pester unit tests, `install.ps1` wiring, and structural tests in `adapters-windows.Tests.ps1`. After this card lands, Windows users with `tts.enabled: true` hear their peon speak via native SAPI5.

## Feature Overview & Context

* **Associated Ticket/Epic:** `v2/m5/tts-native` on roadmap; design doc `docs/designs/tts-native.md`; ADR-001 `docs/adr/ADR-001-tts-backend-architecture.md`
* **Feature Area/Component:** TTS backend — Windows PowerShell implementation
* **Target Release/Milestone:** v2/m5 "The peon speaks to you"; this card plus step 2 completes the `tts-native` feature

**Required Checks:**
* [ ] **Associated Ticket/Epic** link is included above.
* [ ] **Feature Area/Component** is identified.
* [ ] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

The Windows integration layer (`install.ps1` `Resolve-TtsBackend`, `Invoke-TtsSpeak`) was shipped in PR #442. `Invoke-TtsSpeak` base64-encodes the text (metacharacter safety across the `-Command` boundary) and invokes the script via `Start-Process -WindowStyle Hidden -PassThru`, writing the PID to `.tts.pid`. The script receives decoded plain text on stdin; named params carry voice/rate/volume. The script does not exist yet.

* [ ] `README.md` or project documentation reviewed.
* [ ] Existing architecture documentation or ADRs reviewed.
* [ ] Related feature implementations or similar code reviewed.
* [ ] API documentation or interface specs reviewed [if applicable].

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **Design Doc** | `docs/designs/tts-native.md` (lines 277-394, 445-485) | Authoritative interface + Phase 2 deliverables and DoD. Code blocks are illustrative; verify `System.Speech` API calls against current docs. |
| **ADR-001** | `docs/adr/ADR-001-tts-backend-architecture.md` | SAPI5 not WinRT for Phase 2. Calling convention (text on stdin, named params for options). Silent failure policy. |
| **Integration layer — Windows** | `install.ps1:605` (`Resolve-TtsBackend`); `Invoke-TtsSpeak` | Script invoked via `Start-Process -WindowStyle Hidden -PassThru`. Text is base64-decoded before reaching the script — script receives plain UTF-8 on stdin. |
| **Windows async script precedent** | `scripts/win-play.ps1` | Established pattern for async PowerShell backends invoked from `peon.ps1`. Same lifecycle (self-contained, fire-and-forget). No ExecutionPolicy Bypass. |
| **Windows structural tests** | `tests/adapters-windows.Tests.ps1` | Validates PowerShell syntax, parameter shape, absence of ExecutionPolicy Bypass across `.ps1` files. Must be extended to cover `tts-native.ps1`. |
| **Pester test patterns** | `tests/tts-resolution.Tests.ps1` | Pattern for TTS-adjacent Pester coverage; illustrative of mocking + assertion style. |

## Design & Planning

### Initial Design Thoughts & Requirements

Authoritative interface and failure policy are fixed by the design doc. Executor implements script body and tests.

* **Script shape:** PowerShell advanced function with `param()` block accepting `$InputText` (ValueFromPipeline), `$Voice` (default `"default"`), `$Rate` (default `1.0`), `$Vol` (default `0.5`), `-ListVoices` switch. `begin`/`process`/`end` blocks handle pipeline accumulation.
* **Engine:** `Add-Type -AssemblyName System.Speech`; instantiate `[System.Speech.Synthesis.SpeechSynthesizer]`. On exception during `Add-Type`, exit 0 silently with debug log.
* **Voice selection:** `$synth.GetInstalledVoices()` filtered by `VoiceInfo.Name -eq $Voice`. When voice is `"default"` or not installed, fall through to engine default (don't call `SelectVoice`). Missing voice emits a debug line to stderr only under `PEON_DEBUG=1`.
* **Rate mapping:** float → SAPI int `-10..+10`. Formula: `[int][math]::Round(($Rate - 1.0) * 10)`, clamped. `1.0 → 0`, `0.5 → -5`, `2.0 → +10`, `5.0 → +10`, `0.0 → -10`.
* **Volume mapping:** float → SAPI int `0..100`. Formula: `[int][math]::Round($Vol * 100)`, clamped. `0.5 → 50`, `0.0 → 0`, `1.0 → 100`, `2.0 → 100`.
* **Stdin accumulation:** `begin` initializes a `StringBuilder`; `process` appends each `$InputText` line; `end` trims trailing whitespace and skips synthesis if the buffer is empty.
* **Error policy:** try/catch around synthesis, disposal in the success path. All errors emit to stderr only under `PEON_DEBUG=1` (`[Console]::Error.WriteLine`). Exit code always 0.
* **`-ListVoices`:** emit `VoiceInfo.Name` from `GetInstalledVoices()`, one per line on stdout, exit 0. Do not read stdin in this mode.

### Acceptance Criteria

* [ ] `scripts/tts-native.ps1` exists and passes `[System.Management.Automation.PSParser]::Tokenize` with zero errors (structural test proves it).
* [ ] Comment-based help header at top of file (`<#` block) with `.SYNOPSIS`, `.PARAMETER` entries for Voice/Rate/Vol/ListVoices, and at least two `.EXAMPLE` blocks matching the design doc's illustrative header.
* [ ] `param()` block declares: `[Parameter(ValueFromPipeline=$true)] [string]$InputText`, `[string]$Voice = "default"`, `[double]$Rate = 1.0`, `[double]$Vol = 0.5`, `[switch]$ListVoices`.
* [ ] `begin`/`process`/`end` block structure handles pipeline input; empty or whitespace-only buffer exits 0 without calling `Speak`.
* [ ] `Add-Type -AssemblyName System.Speech` wrapped in try/catch; failure → debug log + exit 0.
* [ ] Rate mapping is `[int][math]::Round(($Rate - 1.0) * 10)` clamped to `-10..+10`. Verified via Pester.
* [ ] Volume mapping is `[int][math]::Round($Vol * 100)` clamped to `0..100`. Verified via Pester.
* [ ] Voice selection uses `GetInstalledVoices()` filtered by `VoiceInfo.Name`. `"default"` or missing voice → no `SelectVoice` call, engine default used. Missing voice emits debug line.
* [ ] `-ListVoices` prints `VoiceInfo.Name` values (one per line) to stdout and exits 0 without reading stdin.
* [ ] Synthesis is wrapped in try/catch. On exception, no propagation — debug log to stderr only under `PEON_DEBUG=1`, exit 0. Synth is disposed in the success path.
* [ ] No `Set-ExecutionPolicy Bypass` and no `-ExecutionPolicy Bypass` in the script (enforced by `adapters-windows.Tests.ps1`).
* [ ] `install.ps1` copies `scripts/tts-native.ps1` into the install directory during `-Local` and remote installs.
* [ ] New file `tests/tts-native.Tests.ps1` exists with Pester unit tests covering rate/volume mapping, stdin pipeline binding, voice selection (present/absent/default), empty input, `-ListVoices` output, and clamping.
* [ ] `tests/adapters-windows.Tests.ps1` extended with structural tests for `tts-native.ps1`: file exists in repo, parses cleanly, has expected `param()` parameters, no `ExecutionPolicy Bypass`, has comment-based help header.
* [ ] All existing Pester tests (`tests/adapters-windows.Tests.ps1`, `tests/tts-resolution.Tests.ps1`) continue to pass on the Windows CI runner.
* [ ] Manual DoD: on a real Windows 10 or 11 machine, `"test" | powershell -File scripts/tts-native.ps1 -Voice default -Rate 1.0 -Vol 0.5` speaks "test" and exits 0.
* [ ] Manual DoD: `powershell -File scripts/tts-native.ps1 -ListVoices` prints at least `Microsoft David` or `Microsoft Zira` (both ship with default Windows).
* [ ] Manual DoD: on a Windows install with `tts.enabled: true`, `peon notifications test` produces spoken output through `Invoke-TtsSpeak → tts-native.ps1`.
* [ ] Hook return latency regression stays within ±50ms of the `tts.enabled: false` baseline (measured via `[exit] duration_ms` log line).

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | `docs/designs/tts-native.md` (Phase 2) + ADR-001 | - [ ] Design Complete |
| **Test Plan Creation** | TDD workflow below enumerates all Pester scenarios | - [ ] Test Plan Approved |
| **TDD Implementation** | Write failing Pester first; then script; then install.ps1 wiring; then structural tests | - [ ] Implementation Complete |
| **Integration Testing** | `Invoke-TtsSpeak` end-to-end on Windows — Stop event in test mode | - [ ] Integration Tests Pass |
| **Documentation** | Comment-based help header; no README update this card | - [ ] Documentation Complete |
| **Code Review** | PR + reviewer agent | - [ ] Code Review Approved |
| **Deployment Plan** | merge to main; installer picks it up on `peon update` | - [ ] Deployment Plan Ready |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | Create `tests/tts-native.Tests.ps1` with unit scenarios below; extend `tests/adapters-windows.Tests.ps1` with structural scenarios | - [ ] Failing tests are committed and documented |
| **2. Implement Feature Code** | Write `scripts/tts-native.ps1` body per design doc structure | - [ ] Feature implementation is complete |
| **3. Run Passing Tests** | Pester green locally and on Windows CI | - [ ] Originally failing tests now pass |
| **4. Refactor** | Extract helpers (`Write-DebugLine`); keep file under ~120 lines | - [ ] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | `Invoke-Pester tests/` — all existing suites pass | - [ ] All tests pass (unit, integration, e2e) |
| **6. Performance Testing** | `peon notifications test` with `tts.enabled: true` on Windows; compare `[exit] duration_ms` to `tts.enabled: false` baseline. Target: ±50ms. | - [ ] Performance requirements are met |

### Implementation Notes

**Pester scenarios to cover in `tests/tts-native.Tests.ps1`:**

* **Rate mapping (unit):**
  * `Rate 1.0 → SAPI rate 0`
  * `Rate 0.5 → SAPI rate -5`
  * `Rate 2.0 → SAPI rate +10`
  * `Rate 5.0 → SAPI rate +10` (clamped)
  * `Rate 0.0 → SAPI rate -10` (clamped)

* **Volume mapping (unit):**
  * `Vol 0.5 → SAPI volume 50`
  * `Vol 0.0 → SAPI volume 0`
  * `Vol 1.0 → SAPI volume 100`
  * `Vol 2.0 → SAPI volume 100` (clamped)

* **Stdin pipeline binding:**
  * `"hello" | tts-native.ps1` binds `$InputText` to `"hello"`; buffer ends with `"hello"` at synthesis time
  * Multi-line pipeline input appends each line; trailing whitespace is trimmed before synthesis
  * Empty stdin exits 0 with no `Speak` call
  * Whitespace-only stdin exits 0 with no `Speak` call

* **Voice selection:**
  * Requested voice exists → `SelectVoice` called with that name
  * Requested voice not installed → falls through to default, debug line emitted (assert on stderr capture)
  * Voice `"default"` → `SelectVoice` not called

* **`-ListVoices`:**
  * Emits installed voice names, one per line, on stdout
  * Exits 0 without reading stdin
  * Does not call `Speak`

* **Error containment:**
  * Mocked `SpeechSynthesizer` raising an exception is caught; exit code stays 0; stderr silent unless `PEON_DEBUG=1`

**Mocking strategy:**

`System.Speech.Synthesizer` cannot be easily mocked as a .NET class — instead, wrap the synthesizer usage in small functions that Pester can mock (e.g., `Invoke-Synth`, `Get-SapiVoices`) or use Pester's `Mock` on cmdlet wrappers. The executor chooses the approach that produces cleanest tests. An alternative is to assert on script output / side effects (e.g., a trace log written during test runs) rather than mocking the .NET class directly.

**Structural test additions in `tests/adapters-windows.Tests.ps1`:**

* `scripts/tts-native.ps1` exists
* Parses cleanly via `[System.Management.Automation.PSParser]::Tokenize`
* Has a comment-based help header (`<#` near top of file)
* Declares expected `param()` parameters (`InputText`, `Voice`, `Rate`, `Vol`, `ListVoices`)
* Contains no `ExecutionPolicy Bypass` string (matching existing rule for other .ps1 files)

**Integration test:**

End-to-end from `peon.ps1` event handling through `Invoke-TtsSpeak` to the script. Synthesize a Stop event in test mode, verify `.tts-vars.json` shows `TTS_BACKEND: "native"`, and check the debug log shows the script was invoked without errors. (Audio output cannot be captured by the test runner; manual DoD covers audibility.)

**Test Strategy:**

Unit tests cover pure functions (rate/volume mapping, voice selection fallback logic). Integration/structural tests cover script shape and invocation contract. Manual DoD covers end-to-end audibility on real Windows hardware.

**Key Implementation Decisions:**

SAPI5 via `System.Speech.Synthesis` (not WinRT `Windows.Media.SpeechSynthesis`) per ADR-001 — broader compatibility across Windows 10/11 at the cost of no neural voices. Base64 decoding stays in `Invoke-TtsSpeak`, not in this script — the script receives plain text on stdin. `-File` invocation from `Invoke-TtsSpeak` preserves stdin bytes and makes named params safe.

```powershell
# Sketch — verify System.Speech API calls at implementation time
$sapiRate = [int][math]::Round(($Rate - 1.0) * 10)
$sapiRate = [math]::Max(-10, [math]::Min(10, $sapiRate))
$synth.Rate = $sapiRate
```

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | PR review + reviewer agent |
| **QA Verification** | Manual smoke on Windows 10 + Windows 11 |
| **Production Deployment** | merge to main; `peon update` picks it up |
| **Monitoring Setup** | `[exit] duration_ms` in existing hook log |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No (expected) |
| **Further Investigation?** | SAPI5 voice name case sensitivity (design doc §Risks) — add case-insensitive lookup if user feedback surfaces it |
| **Technical Debt Created?** | WinRT upgrade path for neural voices documented as future refinement; no debt introduced in this card |
| **Future Enhancements** | WinRT swap inside `tts-native.ps1` later (architecturally isolated, no external changes needed) |

### Completion Checklist

* [ ] All acceptance criteria are met and verified.
* [ ] All tests are passing (unit, integration, e2e, performance).
* [ ] Code review is approved and PR is merged.
* [ ] Documentation is updated (README, API docs, user guides).
* [ ] Feature is deployed to production.
* [ ] Monitoring and alerting are configured.
* [ ] Stakeholders are notified of completion.
* [ ] Follow-up actions are documented and tickets created.
* [ ] Associated ticket/epic is closed.
