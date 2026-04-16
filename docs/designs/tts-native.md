# Design Doc: Platform-native TTS backends

> **ADR**: [ADR-001 — TTS Backend Architecture](../adr/ADR-001-tts-backend-architecture.md) | **Date**: 2026-04-16 | **Author**: cameron

## Overview

The TTS integration layer shipped in PR #442 established the `speak()` contract and pipeline integration on both Unix and Windows. The hook pipeline resolves speech text, selects a backend via `_resolve_tts_backend` / `Resolve-TtsBackend`, and invokes the script with text on stdin and voice/rate/volume as arguments. The pipeline works — but there is no backend script to invoke. `scripts/tts-native.sh` and `scripts/tts-native.ps1` do not exist.

This design doc specifies how to implement those two scripts so that `tts.enabled: true` produces spoken output on every supported platform using its built-in TTS engine, with zero setup beyond what the OS already provides. ADR-001 decided *what* the scripts are (independent, self-contained, stdin-text + args-for-options). This doc specifies *how* — platform detection within `tts-native.sh`, the macOS `say` invocation, the Linux priority chain between `piper` and `espeak-ng`, and the Windows `System.Speech.Synthesis` call through PowerShell. It also specifies the voice enumeration logic the `peon tts voices` CLI command depends on and the test strategy that proves each platform works in isolation.

The implementation is two phases: `tts-native.sh` (Unix — macOS and Linux sharing the same script), then `tts-native.ps1` (Windows). Each phase is independently deployable. After Phase 1, Unix users with `tts.enabled: true` hear their peon speak. After Phase 2, Windows users do too. No hook pipeline code changes — the integration layer already calls these scripts when they exist.

## Requirements

The implementation is complete when:

1. **macOS users on default configuration hear spoken output.** `tts.enabled: true` → the peon speaks using macOS `say` via `scripts/tts-native.sh`. No installation required; `say` ships with macOS.
2. **Linux users with `espeak-ng` installed hear spoken output.** `tts-native.sh` detects `espeak-ng` and invokes it. If `piper` is also installed with a model file, it is preferred over `espeak-ng` for higher quality.
3. **Linux users with neither `espeak-ng` nor `piper` installed see a helpful message** from `peon tts on` and `peon tts test`, and silent failure (no errors in the IDE) during hook events.
4. **Windows users on default configuration hear spoken output.** `tts.enabled: true` → the peon speaks using SAPI5 via `scripts/tts-native.ps1`. No installation required; SAPI5 ships with Windows.
5. **`peon tts voices` enumerates the correct voices on each platform.** macOS: `say -v '?'` output. Linux espeak-ng: `espeak-ng --voices`. Linux piper: model file names in configured model dir. Windows: `[System.Speech.Synthesis.SpeechSynthesizer]::GetInstalledVoices()`.
6. **Hook return latency is unchanged.** Native TTS invocation is async (fire-and-forget via `nohup` / `Start-Process`). The `[exit] duration_ms=N` log metric shows no measurable delta compared to `tts.enabled: false` baseline. Target: <50ms regression.
7. **Both scripts are independently testable.** `echo "hello" | bash scripts/tts-native.sh "Alex" "1.0" "0.5"` on macOS speaks "hello" and exits 0, with no hook pipeline context. BATS tests exercise Unix paths (mocked `say`, `espeak-ng`, `piper`). Pester tests exercise Windows paths (mocked `SpeechSynthesizer`). The integration layer tests in `tests/tts.bats` continue to pass against mock backends.
8. **TTS failures never fail the hook.** Missing binaries, invalid voices, audio-device contention, SAPI5 exceptions — each scenario exits cleanly with no propagation to the hook's exit code. The hook pipeline's `fire-and-forget` invocation pattern already enforces this at the process boundary; scripts must honor it by not writing unrecoverable errors to stdout/stderr during normal hook invocations (debug logging stays on stderr and is only visible with `PEON_DEBUG=1`).

## Current State

The integration layer is complete in `peon.sh` and `install.ps1`:

- **`peon.sh:404-422`** — `_resolve_tts_backend` maps config values to script filenames. `native` → `tts-native.sh`. `auto` probes installed scripts in priority order (elevenlabs → piper → native) and returns the first match.
- **`peon.sh:428-465`** — `speak()` invokes the resolved backend via `nohup sh -c 'printf "%s\n" "$0" | "$1" "$2" "$3" "$4"'` with text as `$0` and args as `$1-$4`. Fire-and-forget. PID stored in `.tts.pid`.
- **`install.ps1:605`** — `Resolve-TtsBackend` returns `tts-native.ps1` for `native` backend.
- **`Invoke-TtsSpeak`** — Base64-encodes the text (metacharacter safety) and invokes the script via `Start-Process -WindowStyle Hidden -PassThru`. PID stored in `.tts.pid`.

`scripts/` contains `win-play.ps1` (the architectural precedent for async platform scripts), `notify.sh`, `mac-overlay*.js`, `hook-handle-use.{sh,ps1}`, `pack-download.sh`, and others. No `tts-native.{sh,ps1}` present.

Test infrastructure:

- **`tests/setup.bash:384-407`** — `install_mock_tts_backend` writes a mock `tts-native.sh` to `$TEST_DIR/scripts/` that logs voice/rate/volume args and stdin text to `tts.log`. `tts_was_called`, `tts_call_count`, `tts_last_call` assertion helpers.
- **`tests/tts.bats`** (293 lines, 18 tests) — exercises the full integration pipeline against the mock backend. All tests use `install_mock_tts_backend` at the start, then assert the integration layer's behavior (mode sequencing, suppression, trainer, metacharacter safety).

No real backend script exists, so `tts.enabled: true` today produces no speech — the `speak()` function resolves a script path that isn't there and logs `[tts] backend script 'tts-native.sh' not found` when `PEON_DEBUG=1`, then silently returns.

## Target State

```
scripts/
  tts-native.sh      # Unix — macOS say / Linux piper→espeak-ng priority chain
  tts-native.ps1     # Windows — SAPI5 via System.Speech.Synthesis
  win-play.ps1       # (existing) Windows audio playback
  notify.sh          # (existing) Cross-platform notifications
  ...
```

**`scripts/tts-native.sh`** — reads text from stdin, accepts voice/rate/volume as positional args. Detects platform via `uname`, then:

- **macOS**: `say -v "$voice" -r "$rate_wpm" --volume="$volume" -- <text>` (unquoted text flag or `-f /dev/stdin`)
- **Linux**: probe for `piper` binary + configured model file → use it if present. Fall back to `espeak-ng -v "$voice" -s "$rate_wpm" --stdout | aplay` (or equivalent audio output). If neither is installed, exit 0 silently (debug-log the reason if `PEON_DEBUG=1`).
- **WSL/MSYS2**: delegate to the Windows `tts-native.ps1` via `powershell.exe` (same pattern as `win-play.ps1` for cross-environment audio).

**`scripts/tts-native.ps1`** — reads text from stdin (matching `Invoke-TtsSpeak`'s invocation: decoded text piped to the script, named params for voice/rate/volume), then:

- Loads `System.Speech.Synthesis` assembly
- Instantiates `SpeechSynthesizer`
- Selects voice by name (or uses default if voice is `"default"` or not found)
- Sets rate (SAPI5 rate is -10 to +10, with 0 being default) — map `1.0` float to SAPI5 `0`, `0.5` to `-5`, `2.0` to `+10`
- Sets volume (SAPI5 volume is 0-100 int) — map float 0.0-1.0 to int 0-100
- Calls `Speak($text)` (synchronous inside the already-async `Start-Process` wrapper from `Invoke-TtsSpeak`)
- Wraps in try/catch; on exception, logs to stderr only when `PEON_DEBUG=1`

Base64 encoding happens *only* at the hook→`Start-Process -Command` boundary in `Invoke-TtsSpeak`, where metacharacters could otherwise corrupt the `-Command` string. By the time bytes reach `tts-native.ps1`, they are already decoded plain text on stdin.

The hook pipeline's `speak()` / `Invoke-TtsSpeak` already backgrounds these scripts, so the scripts themselves are synchronous — they run to completion within their subprocess and exit when speech finishes.

**Voice enumeration** is surfaced through `peon tts voices` (shipped in `tts-cli` feature, which depends on `tts-native`). Each script accepts a `--list-voices` flag (Unix) or `-ListVoices` switch (Windows) that prints voice names to stdout, one per line. The CLI invokes the script with this flag and formats the output.

## Design

### Architecture

The scripts slot into the integration layer as leaves in the call graph. Nothing above them changes.

```
Hook event (Stop, Notification, etc.)
    ↓
peon.sh / peon.ps1 (hook script)
    ↓
[Python/PowerShell resolves speech text → TTS_TEXT, TTS_VOICE, TTS_RATE, TTS_VOLUME]
    ↓
speak() [peon.sh] / Invoke-TtsSpeak [peon.ps1]
    ↓
[_resolve_tts_backend → find_bundled_script → absolute path]
    ↓
nohup sh -c '...' / Start-Process -WindowStyle Hidden
    ↓
┌───────────────────┴────────────────────┐
│                                        │
scripts/tts-native.sh              scripts/tts-native.ps1
│                                        │
├── uname → "Darwin" → say               ├── Add-Type System.Speech
├── uname → "Linux"                      ├── new SpeechSynthesizer
│   ├── which piper + model?  → piper    ├── SelectVoice / SetRate / SetVolume
│   └── else: espeak-ng                  └── Speak(text)
└── uname → "MINGW*"/"MSYS*"
    → powershell.exe tts-native.ps1
```

No new modules. Two files, each under 100 lines.

### Key Design Decisions

**1. One `tts-native.sh` for all Unix platforms, not separate `tts-native-mac.sh` / `tts-native-linux.sh`.** ADR-001 allows either. A single file with internal `uname` branching matches how `notify.sh` and `play_sound()` already work in `peon.sh` — Unix users expect one Unix script. The platform check is 5 lines; splitting into separate files would double the file count without reducing the logic. Alternative considered: separate files per platform. Rejected because the per-platform logic is small (`say` is 1 line, `espeak-ng` is 2, `piper` is 3), and the overhead of maintaining two files for 10 lines of code isn't worth it.

**2. Linux prefers `piper` over `espeak-ng` when both are installed.** `piper` produces dramatically better quality (neural TTS) at the cost of a BYO binary and model file (~50MB). `espeak-ng` is robotic but ships in every major distro's default packages. The priority chain is `piper → espeak-ng → nothing`. The `auto` backend resolution at the hook level is a separate concern (elevenlabs → piper → native as a whole); within `tts-native.sh`, we prefer the better of the native options when both exist. Alternative: prefer `espeak-ng` as a more predictable default. Rejected because a user who went out of their way to install `piper` did so explicitly for quality — surprising them with `espeak-ng` would waste their setup.

**3. Piper detection requires both the binary AND a model file to count as "available."** `piper` with no model cannot speak. The detection is `command -v piper && [ -f "$PIPER_MODEL" ]`, where `PIPER_MODEL` comes from `$PEON_PIPER_MODEL` env var or defaults to `$PEON_DIR/piper-models/en_US-lessac-medium.onnx`. This avoids a common failure mode where piper is installed but unusable. Alternative: assume piper is usable if the binary exists. Rejected because it creates a silent-failure path (user installed piper, expected it to work, got silence with no explanation — even `PEON_DEBUG=1` wouldn't help unless the script explicitly logs the model-missing case, which adds complexity).

**4. Windows scripts use SAPI5 (`System.Speech.Synthesis`), not WinRT (`Windows.Media.SpeechSynthesis`).** ADR-001 already documented this decision — SAPI5 has broader compatibility (Windows 10 support, simpler PowerShell integration) at the cost of not reaching Windows 11's neural voices. The architecture is designed for `tts-native.ps1` to adopt WinRT internally later without breaking anything else. Phase 2 ships SAPI5; a future feature slice can swap to WinRT if user demand justifies it.

**5. Rate/volume units are normalized to a float 0.0-2.0 (rate) and 0.0-1.0 (volume) at the integration-layer boundary, and each script maps to its native units internally.** The integration layer passes `TTS_RATE=1.0` and `TTS_VOLUME=0.5`. Each backend script has to understand its own engine's rate/volume conventions:

| Engine | Rate formula | Rate default (for float 1.0) | Volume handling |
|---|---|---|---|
| macOS `say` | wpm = `rate * 200` | 200 wpm (passes `-r 200`) | **No per-invocation volume** — `say` has no stable volume flag across supported macOS versions (`--volume=` is macOS 14+ only). Users control via system output volume. |
| `espeak-ng` | wpm = `rate * 175`; amp = `int(vol * 100)` | 175 wpm (passes `-s 175`) | Amplitude range is 0-200 (default 100); the mapping `int(vol*100)` treats vol=1.0 as normal default. vol>1.0 is not clamped in the formula but `-a` caps at 200 either way. |
| `piper` | length_scale = `1.0 / rate` | 1.0 (passes `--length-scale 1.0`) | **No volume control** — piper writes raw PCM; `aplay` plays it verbatim with no volume flag. Users control via system volume. A future refinement could pipe through `sox` for volume scaling if a volume-aware dependency becomes acceptable. |
| SAPI5 | sapi_rate = `clamp(round((rate-1.0)*10), -10, +10)`; sapi_vol = `clamp(round(vol*100), 0, 100)` | 0 (rate=1.0 → 0; rate=0.5 → -5; rate=2.0 → +10) | Native 0-100 int via `$synth.Volume`. |

Each script has a small unit conversion at its entry point. This is the one piece of duplication ADR-001 accepted in exchange for backend isolation. Alternative: pass unit-specific values from the integration layer. Rejected because it would couple the integration layer to every backend's unit system — adding ElevenLabs would mean adding stability/similarity params to the call sites, defeating the contract's minimalism.

**Volume expectations are engine-specific and `peon tts volume 0.5` does not guarantee half loudness on every backend.** Two of the four native engines (macOS `say`, Linux `piper`) don't support per-invocation volume at all on the supported version range. This is a real user-facing discrepancy but it matches the reality of the underlying tools. Users who need precise volume control on those engines should adjust system volume or use a different backend. `tts-docs` surfaces this.

**6. Error output policy: silent during hook invocations, visible with `PEON_DEBUG=1`.** All stdout/stderr from the backend scripts is suppressed by the `>/dev/null 2>&1` redirection in the integration layer's `speak()`. But we still want debug visibility when the user sets `PEON_DEBUG=1`. The scripts honor this by routing errors to stderr and the hook pipeline captures stderr when debug is on. The script does not write to stdout during normal invocations — stdout is reserved for `--list-voices` output (captured by the CLI). Alternative: always write to stderr. Rejected because users running `peon tts test` directly (outside the hook) want to see errors without setting `PEON_DEBUG=1`, and differentiating "normal use" from "test use" from inside the script requires sniffing parent process or env vars, neither of which is clean.

### Interface Design

**`scripts/tts-native.sh` — entry point**

The code blocks below are *illustrative* — they sketch the structure and intent, but the executor is expected to verify engine flags and unit conversions against the current engine documentation before committing. The blocking-level design decisions (stdin text contract, platform detection order, Linux engine priority chain, error policy) are the authoritative specification; exact flag syntax may need adjustment during implementation.

```bash
#!/bin/bash
# Usage:
#   echo "text to speak" | tts-native.sh <voice> <rate> <volume>
#   tts-native.sh --list-voices
#
# Positional args:
#   voice   — engine-specific voice name (e.g., "Alex" for macOS, "en-us" for espeak-ng)
#             or "default" for engine default
#   rate    — float, 1.0 = normal speed, 0.5 = half, 2.0 = double
#   volume  — float, 0.0 silent to 1.0 full
#
# Stdin:   one line of text to speak (read via `IFS= read -r text`)
# Stdout:  nothing (voice list only with --list-voices)
# Stderr:  diagnostic messages only (hook pipeline redirects this to /dev/null)
# Exit:    0 always — TTS failure never fails the caller
set -uo pipefail

PEON_DEBUG="${PEON_DEBUG:-0}"

_debug() { [ "$PEON_DEBUG" = "1" ] && printf '[tts-native] %s\n' "$*" >&2 || true; }

# --- List voices mode ---
if [ "${1:-}" = "--list-voices" ]; then
    _list_voices  # platform-specific, prints one voice per line
    exit 0
fi

# --- Speak mode ---
voice="${1:-default}"
rate="${2:-1.0}"
volume="${3:-0.5}"
IFS= read -r text || { _debug "no input text"; exit 0; }
[ -z "$text" ] && exit 0

case "$(uname -s)" in
    Darwin)       _speak_macos "$text" "$voice" "$rate" "$volume" ;;
    Linux)        _speak_linux "$text" "$voice" "$rate" "$volume" ;;
    MINGW*|MSYS*) _speak_via_powershell "$text" "$voice" "$rate" "$volume" ;;
    *)            _debug "unsupported platform: $(uname -s)"; exit 0 ;;
esac
```

**Unix platform functions (inside `tts-native.sh`):**

```bash
_speak_macos() {
    local text="$1" voice="$2" rate="$3" volume="$4"
    # volume is intentionally unused on macOS — say has no stable cross-version
    # volume flag. Users control loudness via system output volume.
    _ignore_unused_volume "$volume"
    local wpm  # macOS say uses words-per-minute
    wpm=$(awk "BEGIN { printf \"%d\", $rate * 200 }")
    local voice_flag=""
    [ "$voice" != "default" ] && voice_flag="-v $voice"
    # shellcheck disable=SC2086
    say $voice_flag -r "$wpm" -- "$text" 2>/dev/null || _debug "say failed"
}

_speak_linux() {
    local text="$1" voice="$2" rate="$3" volume="$4"
    # Prefer piper if binary AND model are available
    local piper_model="${PEON_PIPER_MODEL:-$PEON_DIR/piper-models/en_US-lessac-medium.onnx}"
    if command -v piper >/dev/null 2>&1 && [ -f "$piper_model" ]; then
        _speak_piper "$text" "$piper_model" "$rate"
        return
    fi
    if command -v espeak-ng >/dev/null 2>&1; then
        _speak_espeak_ng "$text" "$voice" "$rate" "$volume"
        return
    fi
    _debug "no TTS engine found on Linux (tried piper, espeak-ng)"
}

_speak_piper() {
    local text="$1" model="$2" rate="$3"
    # Piper length_scale: default 1.0, lower = faster speech.
    # rate=1.0 → length_scale=1.0 (normal), rate=2.0 → 0.5 (double speed),
    # rate=0.5 → 2.0 (half speed).
    local length_scale
    length_scale=$(awk "BEGIN { printf \"%.2f\", 1.0 / $rate }")
    # Read sample rate from model's sidecar config; fall back to 22050.
    local sr="${model}.json"
    local rate_hz
    rate_hz=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['audio']['sample_rate'])" "$sr" 2>/dev/null || echo 22050)
    printf '%s\n' "$text" | piper --model "$model" --length-scale "$length_scale" --output-raw 2>/dev/null | \
        aplay -q -r "$rate_hz" -f S16_LE -t raw 2>/dev/null || _debug "piper pipeline failed"
    # Volume: piper + aplay have no volume control. Intentionally ignored.
}

_speak_espeak_ng() {
    local text="$1" voice="$2" rate="$3" volume="$4"
    local wpm vol_int
    wpm=$(awk "BEGIN { printf \"%d\", $rate * 175 }")
    vol_int=$(awk "BEGIN { printf \"%d\", $volume * 100 }")
    local voice_flag=""
    [ "$voice" != "default" ] && voice_flag="-v $voice"
    # shellcheck disable=SC2086
    espeak-ng $voice_flag -s "$wpm" -a "$vol_int" -- "$text" 2>/dev/null || _debug "espeak-ng failed"
}

_speak_via_powershell() {
    local text="$1" voice="$2" rate="$3" volume="$4"
    local peon_dir="${PEON_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
    local ps_script="$peon_dir/scripts/tts-native.ps1"
    [ -f "$ps_script" ] || { _debug "tts-native.ps1 not found"; return; }
    # Pipe text via stdin and pass voice/rate/volume as named params.
    # No Base64 needed: `-File` invocation preserves stdin bytes and named
    # params are not subject to the metacharacter-through-`-Command`
    # problem that Invoke-TtsSpeak guards against in the hook path.
    printf '%s\n' "$text" | powershell.exe -NoProfile -File "$ps_script" \
        -Voice "$voice" -Rate "$rate" -Vol "$volume" 2>/dev/null \
        || _debug "powershell tts-native.ps1 failed"
}

_list_voices() {
    case "$(uname -s)" in
        Darwin)
            say -v '?' | awk '{print $1}'
            ;;
        Linux)
            if command -v piper >/dev/null 2>&1; then
                local piper_dir="${PEON_PIPER_MODEL_DIR:-$PEON_DIR/piper-models}"
                [ -d "$piper_dir" ] && find "$piper_dir" -maxdepth 1 -name '*.onnx' -exec basename {} .onnx \; | sort
            fi
            if command -v espeak-ng >/dev/null 2>&1; then
                espeak-ng --voices 2>/dev/null | awk 'NR>1 {print $4}'
            fi
            ;;
        MINGW*|MSYS*)
            _list_voices_via_powershell
            ;;
    esac
}
```

**`scripts/tts-native.ps1` — entry point**

Illustrative code — same caveat as the Unix script: structure and intent are authoritative, exact API calls should be verified against the current `System.Speech` documentation during implementation.

```powershell
<#
.SYNOPSIS
    Windows native TTS backend. Invoked by peon-ping's Invoke-TtsSpeak with
    decoded text piped via stdin and normalized voice/rate/volume as named
    parameters. Base64 handling lives in Invoke-TtsSpeak, not here — bytes
    arriving here are already plain UTF-8 text.

.PARAMETER Voice
    SAPI5 voice name or "default" for system default.

.PARAMETER Rate
    Float 0.0-2.0. 1.0 is normal, 0.5 is half, 2.0 is double speed.
    Mapped to SAPI5's int -10..+10 scale.

.PARAMETER Vol
    Float 0.0-1.0. 0.0 is silent, 1.0 is full volume. Mapped to SAPI5's int 0-100.

.PARAMETER ListVoices
    If set, prints available voice names to stdout and exits. Does not read stdin.

.EXAMPLE
    "hello world" | .\tts-native.ps1 -Voice "Microsoft David" -Rate 1.0 -Vol 0.5

.EXAMPLE
    .\tts-native.ps1 -ListVoices
#>
param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputText,
    [string]$Voice = "default",
    [double]$Rate = 1.0,
    [double]$Vol = 0.5,
    [switch]$ListVoices
)

begin {
    $peonDebug = $env:PEON_DEBUG -eq "1"
    function Write-DebugLine { param($m) if ($peonDebug) { [Console]::Error.WriteLine("[tts-native] $m") } }

    try {
        Add-Type -AssemblyName System.Speech
    } catch {
        Write-DebugLine "failed to load System.Speech: $_"
        exit 0
    }

    if ($ListVoices) {
        try {
            $synth = [System.Speech.Synthesis.SpeechSynthesizer]::new()
            $synth.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo.Name }
            $synth.Dispose()
        } catch {
            Write-DebugLine "voice enumeration failed: $_"
        }
        exit 0
    }

    $buffer = New-Object System.Text.StringBuilder
}

process {
    if ($InputText) { [void]$buffer.AppendLine($InputText) }
}

end {
    $text = $buffer.ToString().TrimEnd()
    if (-not $text) { exit 0 }

    try {
        $synth = [System.Speech.Synthesis.SpeechSynthesizer]::new()

        # Rate: float 1.0 → SAPI int 0; 0.5 → -5; 2.0 → +10; clamp to -10..+10
        $sapiRate = [int][math]::Round(($Rate - 1.0) * 10)
        $sapiRate = [math]::Max(-10, [math]::Min(10, $sapiRate))
        $synth.Rate = $sapiRate

        # Volume: float 0.0-1.0 → SAPI int 0-100
        $sapiVol = [int][math]::Round($Vol * 100)
        $sapiVol = [math]::Max(0, [math]::Min(100, $sapiVol))
        $synth.Volume = $sapiVol

        if ($Voice -and $Voice -ne "default") {
            $voiceInfo = $synth.GetInstalledVoices() | Where-Object { $_.VoiceInfo.Name -eq $Voice } | Select-Object -First 1
            if ($voiceInfo) {
                $synth.SelectVoice($Voice)
            } else {
                Write-DebugLine "voice '$Voice' not installed; using default"
            }
        }

        $synth.Speak($text)
        $synth.Dispose()
    } catch {
        Write-DebugLine "SAPI5 synthesis failed: $_"
        # Do not propagate — hook must not fail
    }

    exit 0
}
```

**Voice list format (machine-readable, one per line):**

Used by the `peon tts voices` CLI command (tts-cli feature). Each platform emits its native voice identifier — the same string the user passes to `peon tts voice <name>`. Example output on macOS:

```
Alex
Samantha
Fred
Victoria
...
```

## Implementation Phases

### Phase 1: tts-native.sh (Unix implementation)

**Deliverables:**
- `scripts/tts-native.sh` — new file, executable, implementing the Unix entry point with platform detection for macOS / Linux / MSYS2 and the `_speak_macos` / `_speak_linux` / `_list_voices` functions above
- `install.sh` — add `tts-native.sh` to the list of scripts copied into `$PEON_DIR/scripts/`
- `tests/tts-native.bats` — new BATS test file with unit tests per platform (uname mocked, `say`/`espeak-ng`/`piper` mocked as PATH stubs that log their args)
- `tests/setup.bash` — already has `install_mock_tts_backend`; no change needed since the mock remains useful for integration tests in `tests/tts.bats`

**Test strategy:**
- **Unit tests** (mock `say` / `espeak-ng` / `piper` / `uname`):
  - macOS branch: `uname` returns `Darwin` → `say` is called with expected `-v`, `-r`, `--volume` flags
  - Linux with piper + model: piper is invoked with correct `--length-scale`; espeak-ng is NOT invoked
  - Linux with only espeak-ng: espeak-ng is invoked; piper probe does not call piper
  - Linux with neither: script exits 0 silently; debug log shows "no TTS engine found"
  - MSYS2: `powershell.exe` is called with text piped via stdin and named params
  - `--list-voices` on each platform produces expected output (one voice per line)
- **Contract tests**:
  - stdin text with shell metacharacters (`$foo`, backticks, quotes, newlines) survives to the synthesis call uncorrupted — the text-as-$0 pattern in the hook's `nohup sh -c` already enforces this at the caller side; the script must not re-interpret it via eval or printf `%s` without `--` separator
  - Empty stdin → exit 0 with no synthesis call
  - Missing positional args use defaults (voice=`default`, rate=`1.0`, volume=`0.5`)
- **Unit conversion tests**:
  - Rate `1.0` → `200` wpm for macOS, `175` wpm for espeak-ng, `1.00` length-scale for piper
  - Rate `2.0` → `400` wpm, `350` wpm, `0.50` length-scale (double speed = half sample length)
  - Rate `0.5` → `100` wpm, `88` wpm (floor), `2.00` length-scale (half speed = double sample length)
  - Volume `0.5` → ignored by macOS, `50` amplitude int for espeak-ng, ignored by piper
  - Volume `1.0` → `100` amplitude (espeak-ng default)
  - Volume `0.0` → `0` amplitude (silent on espeak-ng)

**Infrastructure:**
- `install.sh` updated to copy the new script (one-line change adding it to the copy list)

**Documentation:**
- Header comment in `scripts/tts-native.sh` matching the Usage block in the interface design above
- No README or llms.txt update in this phase; user-facing docs ship with `tts-docs`

**Dependencies:** ADR-001 accepted (done), tts-integration feature shipped (done, PR #442)

**Definition of done:**
- [ ] `scripts/tts-native.sh` exists, is executable, and has valid bash syntax (`bash -n` passes)
- [ ] Script is copied into install layout by `install.sh`
- [ ] `echo "test" | bash scripts/tts-native.sh "default" "1.0" "0.5"` on a real Mac speaks "test" and exits 0
- [ ] `echo "test" | bash scripts/tts-native.sh "default" "1.0" "0.5"` on a Linux host with `espeak-ng` installed speaks "test" and exits 0
- [ ] `echo "test" | bash scripts/tts-native.sh "default" "1.0" "0.5"` on a Linux host with neither engine exits 0 silently; stderr is empty without `PEON_DEBUG=1` and contains a diagnostic line with it
- [ ] All `tests/tts-native.bats` unit tests pass in CI (BATS job on macOS)
- [ ] All existing `tests/tts.bats` tests still pass (integration layer tests using the mock backend)
- [ ] `bash scripts/tts-native.sh --list-voices` on macOS prints at least one voice name per line
- [ ] On a machine with `tts.enabled: true` and this script present, `peon notifications test` (which fires a synthetic Stop event) produces spoken output without changing hook latency beyond ±50ms of baseline

### Phase 2: tts-native.ps1 (Windows implementation)

**Deliverables:**
- `scripts/tts-native.ps1` — new file implementing the Windows entry point using `System.Speech.Synthesis`
- `install.ps1` — add `tts-native.ps1` to the list of scripts copied into the install directory
- `tests/tts-native.Tests.ps1` — new Pester file with Windows-side coverage (SpeechSynthesizer mocked where possible; direct invocation tests for rate/volume mapping, voice selection, stdin-pipeline input handling)
- `tests/adapters-windows.Tests.ps1` — add structural tests for the existence of `tts-native.ps1` and its expected parameters

**Test strategy:**
- **Unit tests** (Pester):
  - Rate mapping: `Rate 1.0 → SAPI rate 0`, `Rate 0.5 → SAPI rate -5`, `Rate 2.0 → SAPI rate +10`, `Rate 5.0 → clamped to +10`
  - Volume mapping: `Vol 0.5 → SAPI volume 50`, `Vol 0.0 → 0`, `Vol 1.0 → 100`, `Vol 2.0 → clamped to 100`
  - Stdin pipeline input: `"hello" | tts-native.ps1` binds to `$InputText` and ends with `$text = "hello"` before synthesis
  - Multi-line stdin input: each line appends to the buffer; trailing whitespace is trimmed before synthesis
  - Voice selection: requested voice exists → `SelectVoice` called; not installed → falls through to default with debug log
  - Empty stdin or whitespace-only input → exits 0 without calling `Speak`
  - `-ListVoices` prints installed voice names (one per line) and exits 0
- **Contract tests**:
  - Script is invokable via `Start-Process -WindowStyle Hidden -PassThru` and exits within 10 seconds for a short phrase
  - `Invoke-TtsSpeak` from the embedded `peon.ps1` successfully calls this script and produces speech
- **Integration test**:
  - End-to-end via the integration layer: synthesize a Stop event in test mode, verify `.tts-vars.json` contains `TTS_BACKEND: "native"` and the script's invocation left no errors in the debug log

**Infrastructure:**
- `install.ps1` updated to copy the new script (one-line change in the `$scripts` copy list)

**Documentation:**
- Comment-based help header (`<# .SYNOPSIS ... .PARAMETER ... #>`) matching the interface design above
- No README update this phase

**Dependencies:** Phase 1 complete (Unix side working), tts-integration feature shipped (done)

**Definition of done:**
- [ ] `scripts/tts-native.ps1` exists, has valid PowerShell syntax (`[System.Management.Automation.PSParser]::Tokenize` returns no errors)
- [ ] Script is copied into install layout by `install.ps1`
- [ ] On a real Windows 10 or 11 machine, `"test" | powershell -File scripts/tts-native.ps1 -Voice default -Rate 1.0 -Vol 0.5` speaks "test" and exits 0
- [ ] `powershell -File scripts/tts-native.ps1 -ListVoices` prints installed voice names (one per line); at least "Microsoft David" or "Microsoft Zira" appears on a default Windows install
- [ ] All `tests/tts-native.Tests.ps1` Pester tests pass in CI (Windows Pester job)
- [ ] All existing `tests/tts-resolution.Tests.ps1` and `tests/adapters-windows.Tests.ps1` TTS tests still pass
- [ ] On a Windows install with `tts.enabled: true`, `peon notifications test` produces spoken output through `Invoke-TtsSpeak → tts-native.ps1`
- [ ] Hook return latency regression on Windows is within ±50ms of the `tts.enabled: false` baseline (measured via `[exit] duration_ms` log line)

## Migration & Rollback

**Migration**: None required. This is a pure addition of two files. Existing installs with `tts.enabled: false` (the default) are unaffected. Users who already have `tts.enabled: true` (the handful who hand-edited their config during the integration layer rollout) will see speech start working — their config was already valid, the backend just didn't exist.

**Rollback**: Clean. Both files are new; deleting them reverts to the current no-backend-available state. The hook pipeline already handles "script not found" gracefully (`speak()` / `Invoke-TtsSpeak` both exit early with a debug log). No data, state, or config changes are involved.

## Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `say` on macOS routes to default output device, bypassing Sound Effects device routing used by pack sounds | Users who configured Sound Effects device hear TTS from a different output than their pack sounds | Medium | Phase 1 documents this in the script header and in the `tts-notifications` README section. Full routing unification is tracked as a follow-up; not in tts-native scope |
| macOS `say` has no stable volume flag across supported OS versions (`--volume=` exists only on Sonoma 14+) | Per-invocation volume control is unavailable on macOS; `peon tts volume 0.3` has no effect | Medium | Design accepts this limitation: `say` is invoked without a volume flag, and users adjust via system output volume. `tts-docs` surfaces this. If demand emerges, a future version-sniffing fallback can opt in to `--volume=` on 14+. |
| `piper` + `aplay` pipeline has no volume control | `peon tts volume 0.3` has no effect when piper is the active Linux backend | Medium | Design accepts this. Piper is BYO and targeted at advanced users who want quality over configurability. `tts-docs` surfaces the limitation; a later `tts-piper` iteration can add `sox`-based volume scaling if it becomes popular |
| `espeak-ng` voice naming conventions differ from user expectations (e.g., `en-us` vs. `English-American`) | `peon tts voice <name>` fails silently for names the user expected to work | Low | `--list-voices` output is the source of truth; `peon tts voice` validates against it before writing config. Documented in `tts-docs`. |
| SAPI5 voice selection is case-sensitive in older Windows versions | `peon tts voice microsoft david` fails on Windows 10; only `Microsoft David` works | Low | Script matches voice name exactly; `peon tts voices` shows the canonical casing. If this becomes a real user complaint, add case-insensitive lookup |
| Piper models output at non-default sample rates (16k, 48k) cause garbled playback when `aplay -r` is hardcoded | Community-trained models sound distorted | Low | Script reads sample rate from the model's `.onnx.json` sidecar (`audio.sample_rate`), falls back to 22050 if missing or unparseable |
| `aplay` is not available on Linux systems without ALSA utils installed (rare on desktop distros, possible on minimal containers) | Piper pipeline fails even though piper binary is present | Low | Document in `tts-docs` that piper requires `alsa-utils`. Script falls through to `espeak-ng` on pipeline failure (via exit-code check); if `aplay` is missing, piper's pipe fails and the next Linux engine is tried — but the fall-through only happens if `espeak-ng` is installed. Users on minimal containers with only piper will see silent failure (acceptable). |
| `piper` binary installed via `pip install --user` lands in `~/.local/bin/` which may not be on the hook's PATH | Users report "piper is installed but peon-ping can't find it" | Low | `tts-docs` documents that the piper binary must be on the hook's PATH, not just the user's interactive shell. Power users can symlink `/usr/local/bin/piper` or set `PATH` in the hook environment. No code change in `tts-native`. |

## Roadmap Connection

- **Milestone**: v2/m5 "The peon speaks to you" — `in_progress`
- **Feature**: `v2/m5/tts-native` — status moves from `planned` → `in_progress` when Phase 1 starts and `done` when both phases pass CI
- **Unblocks**:
  - `tts-cli` (depends on `tts-native` for `peon tts voices` enumeration)
  - `tts-notifications` (depends on `tts-native` to make speech actually work end-to-end — the notification templates route through `speak()` which needs a real backend)
- **Does not unblock**:
  - `tts-elevenlabs` and `tts-piper` — these depend on `tts-cli` (CLI surface for cache management and backend configuration), not on `tts-native` directly. They share the calling convention but operate independently.

After this design doc lands, the roadmap entry for `v2/m5/tts-native` should have `docs_ref` pointing to `docs/designs/tts-native.md`.

## Resolved Questions

1. **Piper model discovery scope: peon-configured paths only.** Discovery checks `$PEON_PIPER_MODEL` (explicit file path) first, then `$PEON_DIR/piper-models/*.onnx`. Conventional locations like `~/.local/share/piper/` are not scanned in Phase 1 — keeping discovery explicit avoids surprising users with models they didn't know peon-ping could see, and gives `tts-docs` a single canonical location to document ("put your piper models in `~/.claude/hooks/peon-ping/piper-models/` or set `PEON_PIPER_MODEL`"). If user feedback surfaces demand for XDG-convention discovery, it can be added as an additive probe list without breaking existing installs.

2. **WSL/MSYS2 → PowerShell bridge ships in Phase 1.** Real deployment patterns (Cursor on Windows running its shell in WSL, Git Bash users invoking `peon.sh` directly) make the bridge worth the ~10 lines of code even without a WSL CI runner. The bridge is tested indirectly in Phase 2 (the PowerShell script it calls has its own Pester tests), and the bridge layer itself is simple enough that `bash -n` + a manual smoke test on one WSL host is sufficient pre-merge validation.

3. **Voice list output format: plain voice names, no engine tags.** `tts-native.sh --list-voices` emits one voice name per line with no prefix. Users on Linux with both `piper` and `espeak-ng` installed will see models from piper (which is preferred) listed first, then espeak-ng voices — the order communicates which engine would be used, and the `tts-cli` presentation layer can group or annotate as it sees fit without changing this script's output contract. If disambiguation becomes a real user need (two voices with the same name on different engines), the CLI can add engine grouping in its presentation; the script doesn't need to change.

---

## Revision History

| Date | Author | Notes |
|------|--------|-------|
| 2026-04-16 | cameron | Initial design |
