
# Step 2: Implement Unix tts-native.sh with BATS unit tests

**Parallel with:** step 3 (`dpyzoo`). Files are disjoint — this card owns `scripts/tts-native.sh`, `tests/tts-native.bats`, and the `install.sh` wiring; step 3 owns the PowerShell side. MSYS2 branch in this script delegates to `tts-native.ps1` when present, and acceptance criterion 7 specifies silent exit 0 when absent — so no code artifact or test fixture flows between the two cards.

**When to use this template:** Feature card for implementing the Unix side of the platform-native TTS backend per `docs/designs/tts-native.md` Phase 1. Produces `scripts/tts-native.sh` (macOS + Linux + MSYS2 bridge), associated BATS unit tests, and install.sh wiring. The integration layer's `speak()` function already calls this script path — after this card lands, Unix users with `tts.enabled: true` hear their peon speak.

## Feature Overview & Context

* **Associated Ticket/Epic:** `v2/m5/tts-native` on roadmap; design doc `docs/designs/tts-native.md`; ADR-001 `docs/adr/ADR-001-tts-backend-architecture.md`
* **Feature Area/Component:** TTS backend — Unix shell implementation
* **Target Release/Milestone:** v2/m5 "The peon speaks to you"; this card plus step 3 completes the `tts-native` feature

**Required Checks:**
* [ ] **Associated Ticket/Epic** link is included above.
* [ ] **Feature Area/Component** is identified.
* [ ] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

The integration layer (`peon.sh` `speak()`, `_resolve_tts_backend`) was shipped in PR #442 (TTSINTEG sprint). It invokes `scripts/tts-native.sh` via `nohup sh -c 'printf "%s\n" "$0" | "$1" "$2" "$3" "$4"'` with text as `$0` and voice/rate/volume as `$1-$4`. The script does not exist yet — `speak()` logs `[tts] backend script 'tts-native.sh' not found` under `PEON_DEBUG=1` and silently returns.

* [ ] `README.md` or project documentation reviewed.
* [ ] Existing architecture documentation or ADRs reviewed.
* [ ] Related feature implementations or similar code reviewed.
* [ ] API documentation or interface specs reviewed [if applicable].

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **Design Doc** | `docs/designs/tts-native.md` (lines 137-275, 395-444) | Authoritative interface + Phase 1 deliverables and DoD. Code blocks are illustrative; verify engine flags at implementation time. |
| **ADR-001** | `docs/adr/ADR-001-tts-backend-architecture.md` | Calling convention (text on stdin, voice/rate/volume as positional args); fire-and-forget; silent failure policy; no shared backend library. |
| **Integration layer — Unix** | `peon.sh:404-465` (`_resolve_tts_backend`, `speak()`) | Resolves backend via static `case` block. `native` → `tts-native.sh`. `auto` probes elevenlabs → piper → native. Invocation uses `nohup sh -c` with text as `$0`. |
| **Cross-platform script precedent** | `scripts/notify.sh`, `scripts/win-play.ps1` | Unix uses one script with internal `uname` branching (notify.sh). Windows uses separate `.ps1` scripts for async audio (win-play.ps1). Follow both patterns. |
| **Test infrastructure** | `tests/setup.bash:384-425`; `tests/tts.bats` (293 lines, 18 tests) | `install_mock_tts_backend` writes a mock `tts-native.sh` that logs voice/rate/volume + stdin. Existing integration tests use the mock — they must keep passing after this card. New `tests/tts-native.bats` exercises the real script with mocked engines. |
| **Piper model sidecar format** | piper docs (`.onnx.json` with `audio.sample_rate`) | Script reads sample rate from sidecar JSON, falls back to 22050 if missing/unparseable. |

## Design & Planning

### Initial Design Thoughts & Requirements

Authoritative interface, failure policy, and platform branching are fixed by the design doc. The executor implements the script body and tests; code blocks in the design doc are illustrative and engine flags must be verified against current docs (`say`, `espeak-ng`, `piper`, `aplay`) before committing.

* **Platform branching via `uname -s`:** `Darwin` → macOS `say`, `Linux` → piper/espeak-ng priority chain, `MINGW*`/`MSYS*` → bridge to `tts-native.ps1` via `powershell.exe`.
* **Linux engine priority:** piper preferred when both `command -v piper` AND `[ -f "$PIPER_MODEL" ]` succeed (binary + model both required to count as available). Fall through to `espeak-ng`. If neither is installed, exit 0 silently; debug-log the reason under `PEON_DEBUG=1`.
* **Piper model discovery:** `$PEON_PIPER_MODEL` env var (explicit path) first, else default `$PEON_DIR/piper-models/en_US-lessac-medium.onnx`. No XDG-convention scanning in Phase 1.
* **Sample-rate-aware aplay:** read `audio.sample_rate` from `${model}.json` sidecar via `python3 -c 'import json; ...'`, fall back to 22050.
* **Unit conversions (at each engine):** macOS wpm = `rate * 200`; espeak-ng wpm = `rate * 175`, amplitude = `vol * 100`; piper `--length-scale = 1.0 / rate`. Volume is unsupported on macOS `say` and piper+aplay; passed to `_ignore_unused_volume` to document intent.
* **Error policy:** stdout silent during normal hook invocation (reserved for `--list-voices`); stderr emits diagnostics only under `PEON_DEBUG=1`. Exit code is always 0 — TTS failure must not fail the hook.
* **MSYS2 bridge:** invokes `powershell.exe -NoProfile -File "$PEON_DIR/scripts/tts-native.ps1" -Voice ... -Rate ... -Vol ...` with text on stdin. Guards with `[ -f "$ps_script" ]` so Phase 2 not being shipped yet produces silent failure (the designed behavior).
* **`--list-voices` mode:** one voice name per line per engine. macOS: `say -v '?' | awk '{print $1}'`. Linux: piper model basenames (if present) followed by `espeak-ng --voices` names. MSYS2: delegates to `tts-native.ps1 -ListVoices`.

### Acceptance Criteria

* [ ] `scripts/tts-native.sh` exists, is executable (`chmod +x`), and passes `bash -n`.
* [ ] Script header (top-of-file comment) documents usage, stdin contract, arg list, and error policy matching the design doc's illustrative interface block.
* [ ] Platform detection uses `uname -s` with cases for `Darwin`, `Linux`, `MINGW*`/`MSYS*`, and a fallback that debug-logs and exits 0.
* [ ] macOS branch invokes `say` with `-v <voice>` (omitted when voice == `default`), `-r <wpm>` where wpm = `rate * 200`. Volume flag is intentionally omitted (design decision — `--volume=` is macOS 14+ only).
* [ ] Linux branch prefers piper: if `command -v piper` succeeds AND a model file exists at `$PEON_PIPER_MODEL` (or default path), pipe text through `piper --model <m> --length-scale <1/rate> --output-raw | aplay -q -r <sr> -f S16_LE -t raw`. Sample rate read from `${model}.json` sidecar, default 22050.
* [ ] Linux branch falls back to `espeak-ng -v <voice> -s <wpm> -a <amplitude> -- <text>` when piper is not available; wpm = `rate * 175`, amplitude = `vol * 100`.
* [ ] Linux branch with neither engine installed exits 0 silently; `PEON_DEBUG=1` emits one `[tts-native] no TTS engine found on Linux` line to stderr.
* [ ] MSYS2 branch pipes text to `powershell.exe -NoProfile -File <PEON_DIR>/scripts/tts-native.ps1 -Voice ... -Rate ... -Vol ...`; missing `tts-native.ps1` exits 0 silently (debug-log under `PEON_DEBUG=1`).
* [ ] `--list-voices` flag prints one voice name per line on stdout per platform; exits 0. macOS: `say -v '?'` names. Linux: piper model basenames (if present) then `espeak-ng --voices` names. MSYS2: delegates to `tts-native.ps1 -ListVoices`.
* [ ] Empty stdin (no text arrived or only whitespace) exits 0 with no engine invocation and no stderr output unless `PEON_DEBUG=1`.
* [ ] Shell metacharacters in stdin text (`$foo`, backticks, single/double quotes, newlines) reach the engine uncorrupted — no `eval`, no shell-interpolation re-expansion; all invocations use `--` separator where supported and quote `$text` correctly.
* [ ] `install.sh` copies `scripts/tts-native.sh` into `$PEON_DIR/scripts/` during `--local` and remote installs.
* [ ] New file `tests/tts-native.bats` exists with the unit, contract, and unit-conversion test coverage enumerated in the TDD workflow below. All tests pass on the macOS CI runner.
* [ ] All existing `tests/tts.bats` tests continue to pass (the `install_mock_tts_backend` mock keeps working for integration-layer tests — don't replace the mock with the real script for those tests).
* [ ] Manual DoD: on a real Mac, `echo "test" | bash scripts/tts-native.sh "default" "1.0" "0.5"` speaks "test" and exits 0. On a Linux host with `espeak-ng` installed, same invocation speaks "test". On a Linux host with neither engine, exit is clean and stderr is empty without `PEON_DEBUG=1`.
* [ ] `peon notifications test` (or equivalent synthetic Stop event) with `tts.enabled: true` produces spoken output and hook return latency stays within ±50ms of baseline (`[exit] duration_ms=` log line).

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | `docs/designs/tts-native.md` (Phase 1) + ADR-001 | - [ ] Design Complete |
| **Test Plan Creation** | TDD workflow below enumerates all BATS scenarios | - [ ] Test Plan Approved |
| **TDD Implementation** | Write failing BATS first; then script; then install.sh wiring | - [ ] Implementation Complete |
| **Integration Testing** | `tests/tts.bats` 18-test suite still passes against mock backend | - [ ] Integration Tests Pass |
| **Documentation** | Script header comment; no README update this card (ships with `tts-docs`) | - [ ] Documentation Complete |
| **Code Review** | PR + reviewer agent | - [ ] Code Review Approved |
| **Deployment Plan** | merge to main; installer picks it up on `peon update` | - [ ] Deployment Plan Ready |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | Create `tests/tts-native.bats` with all scenarios below; verify red run | - [ ] Failing tests are committed and documented |
| **2. Implement Feature Code** | Write `scripts/tts-native.sh` body per design doc structure | - [ ] Feature implementation is complete |
| **3. Run Passing Tests** | BATS green locally and on macOS CI | - [ ] Originally failing tests now pass |
| **4. Refactor** | Extract shared helpers (`_debug`, `_ignore_unused_volume`); keep file under ~150 lines | - [ ] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | `bats tests/` — all existing suites including `tts.bats` pass | - [ ] All tests pass (unit, integration, e2e) |
| **6. Performance Testing** | Run `peon notifications test` with `tts.enabled: true` and compare `[exit] duration_ms` to baseline (`tts.enabled: false`). Target: ±50ms. | - [ ] Performance requirements are met |

### Implementation Notes

**BATS scenarios to cover in `tests/tts-native.bats` (non-exhaustive; write what's needed to prove each behavior):**

* **Platform branching (uname stubbed on PATH):**
  * `Darwin` uname → `say` stub is invoked with `-r 200`, and `-v <voice>` appears when voice != "default"
  * `Linux` uname + piper binary + model file → piper stub receives `--length-scale 1.00`; espeak-ng stub is not invoked
  * `Linux` uname + only espeak-ng → espeak-ng stub invoked with `-s 175 -a 50` (for vol=0.5); piper stub not invoked
  * `Linux` uname + neither engine → script exits 0 silently; with `PEON_DEBUG=1` stderr contains `no TTS engine found`
  * `MINGW64_NT-10.0` uname → `powershell.exe` stub invoked with `-File .../tts-native.ps1 -Voice ... -Rate ... -Vol ...`
  * `MINGW64_NT-10.0` uname + missing tts-native.ps1 → exits 0 silently; debug log shows "not found"
  * Unknown uname → exits 0; debug log shows "unsupported platform"

* **Unit conversion correctness:**
  * Rate `1.0` → macOS wpm `200`, espeak-ng wpm `175`, piper length-scale `1.00`
  * Rate `2.0` → macOS wpm `400`, espeak-ng wpm `350`, piper length-scale `0.50`
  * Rate `0.5` → macOS wpm `100`, espeak-ng wpm `88` (or `87` depending on rounding — assert on the awk output, not a literal), piper length-scale `2.00`
  * Volume `0.5` → espeak-ng amplitude `50`; ignored by macOS/piper
  * Volume `1.0` → espeak-ng amplitude `100`
  * Volume `0.0` → espeak-ng amplitude `0`

* **Contract behavior:**
  * Empty stdin (no bytes or only newline) exits 0 without invoking any engine stub
  * Missing positional args default to `voice=default`, `rate=1.0`, `volume=0.5` (assert engine invocation shows defaults applied)
  * Shell metacharacters in stdin (`$FOO`, backticks, double quotes, apostrophes) survive verbatim to the engine stub's logged text
  * TTS failure paths (engine stub exits non-zero) do not cause the wrapper script to exit non-zero — script always exits 0

* **`--list-voices` mode:**
  * macOS: `say` stub emits a voice list; script output is one voice per line on stdout
  * Linux with piper: `.onnx` basenames listed; Linux with espeak-ng: voice names listed; Linux with both: piper first
  * MSYS2: delegates to `tts-native.ps1 -ListVoices` (powershell stub captures the call)

* **Sample-rate sidecar handling (piper):**
  * When `<model>.json` exists with `audio.sample_rate: 16000`, aplay is invoked with `-r 16000`
  * When sidecar is missing or JSON parse fails, aplay is invoked with `-r 22050` (default)

**Mocking strategy:**

Stub `uname`, `say`, `espeak-ng`, `piper`, `aplay`, `powershell.exe`, and optionally `python3` via PATH-first wrapper scripts that log their args/stdin to files under `$TEST_DIR`. This mirrors the existing `install_mock_tts_backend` approach. Do not modify `install_mock_tts_backend` — that mock remains the backend for `tests/tts.bats` integration tests. The new BATS file sets up a different test environment targeted at the real script.

**Test Strategy:**

Behavioral tests on engine invocation shape (what flags, what stdin, what env) are the bulk of the coverage. Unit conversion tests assert on arithmetic correctness. Contract tests guard the always-exit-0 and silent-stdout invariants.

**Key Implementation Decisions:**

One file for all Unix platforms with internal `uname` branching (not separate `tts-native-mac.sh`/`tts-native-linux.sh`) — matches `notify.sh` pattern. Each engine function takes `text voice rate volume` and does its own unit conversion; no shared conversion helpers to keep per-engine logic self-contained.

```bash
# Sketch — verify engine flags against current docs before committing
_speak_macos() {
    local wpm
    wpm=$(awk "BEGIN { printf \"%d\", $3 * 200 }")
    local voice_flag=""
    [ "$2" != "default" ] && voice_flag="-v $2"
    # shellcheck disable=SC2086
    say $voice_flag -r "$wpm" -- "$1" 2>/dev/null || _debug "say failed"
}
```

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | PR review + reviewer agent |
| **QA Verification** | Manual smoke on Mac + one Linux host (espeak-ng installed) |
| **Production Deployment** | merge to main; `peon update` picks it up |
| **Monitoring Setup** | `[exit] duration_ms` in existing hook log |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No (expected) |
| **Further Investigation?** | Sample-rate sidecar edge cases (malformed JSON, missing `audio.sample_rate` key) covered by tests |
| **Technical Debt Created?** | macOS volume unsupported, piper+aplay volume unsupported — documented as known limitations per design doc §Risks |
| **Future Enhancements** | `tts-docs` feature will surface the volume limitations; `--volume=` for macOS 14+ is a future refinement |

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
