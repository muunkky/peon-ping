# Design Doc: TTS Integration Layer and Backend Contract

> **ADR**: [ADR-001](../adr/ADR-001-tts-backend-architecture.md) | **Date**: 2026-03-28 | **Author**: cameron

## Overview

This document designs the TTS integration layer for peon-ping — the foundation that every TTS
feature builds on. ADR-001 decided that TTS backends ship as independent, self-contained scripts
invoked through a minimal calling convention (text on stdin, voice/rate/volume as arguments). This
design doc works out the specifics: where the hook pipeline gains TTS awareness, how speech text is
resolved from multiple sources, how mode sequencing coordinates sound and speech, how backend
resolution selects the right script, and how the config schema and state management extend to
support TTS.

The integration layer is deliberately inert on its own — it resolves text and invokes a backend
script, but without a backend installed (tts-native ships separately), `peon tts on` detects no
available engine and tells the user. This separation means the integration layer can be tested
against mock backends without platform-specific TTS dependencies.

## Requirements

The implementation is complete when:

1. The hook pipeline in `peon.sh` resolves speech text from the configured source chain and invokes
   the selected TTS backend as an async background process after (or instead of, per mode) sound
   playback — without increasing hook return latency.
2. The hook pipeline in `install.ps1` (embedded `peon.ps1` engine) provides identical TTS behavior
   to the Unix implementation — same config keys, same text resolution, same mode sequencing, same
   async contract.
3. A TTS backend script receives text on stdin with voice, rate, and volume as arguments — nothing
   else. No hook context, no config access, no state file. The contract is the calling convention
   and nothing more.
4. `config.json` gains a `tts` section with `enabled`, `backend`, `voice`, `rate`, `volume`, and
   `mode` fields, and `peon update` backfills this section for existing installs without overwriting
   user-modified values.
5. Backend resolution maps `config.tts.backend` to a script path via an explicit `case`/`switch`
   block. `"auto"` resolves to the best available backend by probing for installed scripts in
   priority order. When no backend is available, TTS is silently skipped during hooks and explicitly
   reported during `peon tts on`.
6. Speech text resolution follows a defined chain: manifest `speech_text` field (when present) →
   notification template for the active category → default template `"{project} — {status}"`. Empty
   resolved text skips TTS entirely.
7. TTS PID tracking (`.tts.pid`) is independent from sound PID (`.sound.pid`), enabling the three
   sequencing modes and independent kill-previous behavior.
8. All existing suppression rules (`headphones_only`, `meeting_detect`, `suppress_sound_when_tab_focused`,
   pause/mute state) apply to TTS identically to how they apply to sound playback.

## Current State

### Hook pipeline (Unix — `peon.sh`)

The embedded Python block (lines ~3329–3778) handles event routing, category mapping, sound
selection, notification template resolution, and trainer reminder logic. It outputs shell variables
via `print()` statements:

```
SOUND_FILE=/path/to/sound.mp3
VOLUME=0.5
NOTIFY=true
MSG="api-server — Task complete"
TRAINER_SOUND=/path/to/trainer.mp3
TRAINER_MSG="Time for reps!"
```

Shell code `eval`s these variables, then `_run_sound_and_notify()` (line 3927) handles playback:

1. Check suppression rules (headphones, meeting, tab focus)
2. `play_sound "$SOUND_FILE" "$VOLUME"` — platform-dispatched, async via `nohup ... &`
3. `send_notification` — desktop notification with template-rendered text
4. `send_mobile_notification` — push notification if configured

After `_run_sound_and_notify` returns (backgrounded via `& disown` in production), trainer reminder
logic (line 3968) waits for the main sound PID to finish, pauses 0.5s, then plays the trainer
sound and sends a trainer notification.

### Hook pipeline (Windows — embedded in `install.ps1`)

The `peon.ps1` engine (lines ~1400–1900 of `install.ps1`) mirrors the Python logic in pure
PowerShell. Sound selection, anti-repeat, icon resolution, and notification template resolution
all follow the same patterns. Audio delegates to `scripts/win-play.ps1` via
`Start-Process -WindowStyle Hidden`. Trainer reminder logic follows the same wait-then-play
pattern.

### Sound PID tracking

- `save_sound_pid()` writes PID to `$PEON_DIR/.sound.pid`
- `kill_previous_sound()` reads and kills the previous PID before playing a new sound
- Trainer reminder waits for `.sound.pid` to finish before playing its sound

### Notification template resolution

The Python block (lines 3715–3740) resolves templates using `_tpl_vars`:

```python
_tpl_vars = defaultdict(str, {
    'project': project,
    'summary': event_data.get('transcript_summary', '').strip()[:120],
    'tool_name': event_data.get('tool_name', ''),
    'status': status,
    'event': event,
})
msg = _tpl.format_map(_tpl_vars)
```

Template key mapping: `task.complete` → `stop`, `task.error` → `error`,
`PermissionRequest` → `permission`, idle/question from notification subtypes.

### Config structure

`config.json` has 44 keys. The `trainer` section (nested object) establishes the pattern for
feature namespaces. No `tts` section exists today.

### State management

`.state.json` uses atomic writes (temp file + `os.replace()` on Unix, `Write-StateAtomic` on
Windows). Stores `last_played`, `session_packs`, `prompt_timestamps`, `trainer`, etc. Read with
retry logic (3 attempts with backoff).

## Target State

After this implementation, the hook pipeline gains a TTS phase between sound playback and
notification dispatch. The flow becomes:

```
Event JSON → Python/PS routing → Category → Sound selection
                                          → Speech text resolution (NEW)
                                          ↓
                              _run_sound_and_notify()
                                  ├── play_sound()         [existing]
                                  ├── speak()              [NEW]
                                  ├── send_notification()  [existing]
                                  └── send_mobile_notif()  [existing]
                                          ↓
                              Trainer reminder (if applicable)
                                  ├── wait for .sound.pid  [existing]
                                  ├── wait for .tts.pid    [NEW — avoids overlap]
                                  ├── play trainer sound   [existing]
                                  ├── speak trainer text   [NEW]
                                  └── send trainer notif   [existing]
```

### Architecture

```
                          ┌──────────────────────┐
                          │   Hook Pipeline       │
                          │  (peon.sh / peon.ps1) │
                          └──────┬───────────────┘
                                 │
                    ┌────────────┼────────────────┐
                    │            │                 │
            ┌───────▼──┐  ┌─────▼─────┐   ┌──────▼──────┐
            │play_sound│  │  speak()  │   │send_notif() │
            │ .sound.pid│  │ .tts.pid │   │             │
            └──────────┘  └─────┬─────┘   └─────────────┘
                                │
                    ┌───────────┼───────────────┐
                    │           │               │
              ┌─────▼────┐ ┌───▼─────┐  ┌──────▼──────┐
              │tts-native│ │tts-11lab│  │  tts-piper  │
              │   .sh    │ │   .sh   │  │    .sh      │
              │   .ps1   │ │   .ps1  │  │    .ps1     │
              └──────────┘ └─────────┘  └─────────────┘
```

The `speak()` function is the integration layer's single responsibility: resolve the backend,
construct the invocation, and fire it as a background process. Each backend script is a black box
that reads text from stdin and produces audio.

### Mode sequencing in `_run_sound_and_notify`

```
sound-then-speak (default):
  play_sound() → speak()       → notifications

speak-only:
  [skip sound] → speak()       → notifications

speak-then-sound:
  speak()      → play_sound()  → notifications
```

In `sound-then-speak` and `speak-then-sound`, both sound and speech fire as independent background
processes — no waiting. The perceptual ordering comes from invocation order and the ~200ms startup
delta. `speak-only` skips `play_sound()` entirely.

## Design

### Key Design Decisions

**1. Speech text resolution happens in the Python/PowerShell routing block, not in `speak()`.**

The Python block already has access to the manifest (`pick` variable with the chosen sound entry),
notification templates (`_tpl_vars`), and event context (`project`, `status`, `summary`). Resolving
speech text here means `speak()` receives already-interpolated plain text — no template engine, no
manifest access, no event context needed in the shell function or backend scripts.

Alternative considered: having `speak()` accept template strings and variables, resolving text
at invocation time. Rejected because it duplicates the template resolution already done for
notifications and splits the "what text to produce" logic across two locations.

**2. `_run_sound_and_notify()` handles mode sequencing; `speak()` is mode-unaware.**

`_run_sound_and_notify()` is the only place that knows about both `play_sound()` and `speak()`, so
it owns the ordering decision. A `case` on `TTS_MODE` determines whether sound fires first, speech
fires first, or sound is skipped entirely. `speak()` itself is a thin wrapper — resolve backend,
invoke script, track PID — with no knowledge of modes. This keeps each function to a single
responsibility: the caller sequences, the speaker speaks.

Alternative considered: having `speak()` handle mode logic internally, checking `TTS_MODE` and
coordinating with `play_sound()`. Rejected because `speak()` would need to know about sound
playback state and SOUND_FILE availability — concerns that belong to the caller.

```bash
_run_sound_and_notify() {
  # ... suppression checks (applied to both sound and TTS) ...

  if [ "$_skip_sound" = "false" ]; then
    case "${TTS_MODE:-sound-then-speak}" in
      sound-then-speak)
        [ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ] && play_sound "$SOUND_FILE" "$VOLUME"
        [ -n "$TTS_TEXT" ] && speak "$TTS_TEXT"
        ;;
      speak-only)
        [ -n "$TTS_TEXT" ] && speak "$TTS_TEXT"
        ;;
      speak-then-sound)
        [ -n "$TTS_TEXT" ] && speak "$TTS_TEXT"
        [ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ] && play_sound "$SOUND_FILE" "$VOLUME"
        ;;
    esac
  fi

  # ... notifications (unchanged) ...
}
```

Each branch guards both `SOUND_FILE` (may be empty if no sound for this category) and `TTS_TEXT`
(may be empty if TTS disabled or text resolved empty). When `SOUND_FILE` is empty, only TTS fires
regardless of mode. When `TTS_TEXT` is empty, only sound fires — existing behavior preserved
exactly.

**3. Backend resolution is a static `case` block, not filesystem scanning.**

The ADR explicitly chose this: "Explicit is better than implicit for a system with <10 backends."
The hook pipeline maps config values to script paths:

```bash
# Unix — always returns a script filename (e.g., "tts-native.sh"), never an absolute path.
# The caller (speak()) resolves to absolute via find_bundled_script.
_resolve_tts_backend() {
  local backend="${1:-auto}"
  case "$backend" in
    native)     echo "tts-native.sh" ;;
    elevenlabs) echo "tts-elevenlabs.sh" ;;
    piper)      echo "tts-piper.sh" ;;
    auto)
      # Probe in priority order: prefer premium when installed.
      # At Phase 1 launch, only native exists — probes are ~1ms each.
      for b in elevenlabs piper native; do
        local script_name
        script_name="$(_resolve_tts_backend "$b")" || continue
        find_bundled_script "$script_name" >/dev/null 2>&1 || continue
        echo "$script_name" && return 0
      done
      return 1  # no backend available
      ;;
    *) return 1 ;;
  esac
}
```

```powershell
# Windows — always returns a script filename (e.g., "tts-native.ps1"), never a full path.
# The caller (Invoke-TtsSpeak) resolves to absolute via Join-Path $InstallDir "scripts\$name".
function Resolve-TtsBackend {
    param([string]$Backend = "auto")
    switch ($Backend) {
        "native"     { return "tts-native.ps1" }
        "elevenlabs" { return "tts-elevenlabs.ps1" }
        "piper"      { return "tts-piper.ps1" }
        "auto" {
            # Probe in priority order: prefer premium when installed.
            # At Phase 1 launch, only native exists — probes are ~1ms each.
            foreach ($b in @("elevenlabs", "piper", "native")) {
                $scriptName = Resolve-TtsBackend -Backend $b
                $full = Join-Path $InstallDir "scripts\$scriptName"
                if (Test-Path $full) { return $scriptName }
            }
            return $null
        }
        default { return $null }
    }
}
```

The `auto` probe order prefers premium backends when installed (ElevenLabs > Piper > native). At
Phase 1 launch, only `native` exists, so `auto` trivially resolves to `native`. This ordering
means users who later install ElevenLabs get an automatic upgrade without config changes.

**4. TTS PID tracking uses `.tts.pid` separate from `.sound.pid`.**

The ADR specified this for mode independence. The `speak()` function manages `.tts.pid` with the
same kill-previous pattern as `kill_previous_sound()`:

```bash
kill_previous_tts() {
  local pidfile="$PEON_DIR/.tts.pid"
  if [ -f "$pidfile" ]; then
    local old_pid
    old_pid=$(cat "$pidfile" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      kill "$old_pid" 2>/dev/null
    fi
    rm -f "$pidfile"
  fi
}

save_tts_pid() {
  echo "$1" > "$PEON_DIR/.tts.pid"
}
```

The trainer subshell waits for *both* `.sound.pid` and `.tts.pid` to complete before playing
trainer content. In `sound-then-speak` mode, main TTS starts after main sound — so `.sound.pid`
can finish while `.tts.pid` is mid-utterance. Waiting for both PIDs prevents the trainer sound
from overlapping with the main event's TTS phrase. The wait logic uses the same poll pattern as
the existing `.sound.pid` wait (10s timeout, 100ms poll interval).

**5. `PEON_TEST=1` makes TTS synchronous for test capture.**

The existing test pattern: `PEON_TEST=1` causes `play_sound()` to run synchronously (no `nohup`,
no `&`). TTS follows the same convention — `speak()` runs the backend in the foreground when
`PEON_TEST=1`, allowing BATS tests to capture the invocation and verify arguments. In production,
the backend runs via `nohup ... &` (Unix) or `Start-Process -WindowStyle Hidden` (Windows).

### Interface Design

#### `speak()` shell function (Unix)

```bash
speak() {
  local text="$1"
  [ -z "$text" ] && return 0

  kill_previous_tts

  # _resolve_tts_backend returns a script filename (e.g., "tts-native.sh").
  # find_bundled_script resolves it to an absolute path.
  local script_name
  script_name="$(_resolve_tts_backend "${TTS_BACKEND:-auto}")" || return 0
  local abs_script
  abs_script="$(find_bundled_script "$script_name")" 2>/dev/null || return 0
  [ -x "$abs_script" ] || return 0

  local voice="${TTS_VOICE:-default}"
  local rate="${TTS_RATE:-1.0}"
  local vol="${TTS_VOLUME:-0.5}"

  if [ "${PEON_TEST:-0}" = "1" ]; then
    printf '%s\n' "$text" | "$abs_script" "$voice" "$rate" "$vol" >/dev/null 2>&1
  else
    # printf '%s\n' is used instead of echo to avoid flag interpretation
    # (e.g., text starting with "-n" or "-e"). Text is passed as $0 to sh -c,
    # avoiding shell interpolation of metacharacters in the text content.
    nohup sh -c 'printf "%s\n" "$0" | "$1" "$2" "$3" "$4"' \
      "$text" "$abs_script" "$voice" "$rate" "$vol" >/dev/null 2>&1 &
    save_tts_pid $!
  fi
}
```

#### `Invoke-TtsSpeak` PowerShell function (Windows)

```powershell
function Invoke-TtsSpeak {
    param(
        [string]$Text,
        [string]$Backend = "auto",
        [string]$Voice = "default",
        [double]$Rate = 1.0,
        [double]$Volume = 0.5
    )
    if (-not $Text) { return }

    # Kill previous TTS
    $pidFile = Join-Path $InstallDir ".tts.pid"
    if (Test-Path $pidFile) {
        $oldPid = Get-Content $pidFile -ErrorAction SilentlyContinue
        if ($oldPid) {
            try { Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue } catch {}
        }
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }

    $scriptName = Resolve-TtsBackend -Backend $Backend
    if (-not $scriptName) { return }
    $scriptPath = Join-Path $InstallDir "scripts\$scriptName"
    if (-not (Test-Path $scriptPath)) { return }

    # Text is Base64-encoded to avoid shell metacharacter injection. Dynamic text
    # from template variables ({summary}, {project}) can contain double quotes,
    # dollar signs, backticks, and other PowerShell-interpreted characters that
    # would corrupt or break a directly-interpolated -Command string. This matches
    # the Unix side's safety guarantee (text passed as $0, never interpolated).
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Text))
    $proc = Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile", "-NonInteractive", "-Command",
            "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$b64')) | & '$scriptPath' -voice '$Voice' -rate $Rate -vol $Volume" `
        -WindowStyle Hidden -PassThru
    $proc.Id | Set-Content $pidFile
}
```

#### Python block output (new variables)

The Python block gains these additional `print()` outputs:

```python
print('TTS_ENABLED=' + ('true' if tts_enabled else 'false'))
print('TTS_TEXT=' + q(tts_text))
print('TTS_BACKEND=' + q(tts_backend))
print('TTS_VOICE=' + q(tts_voice))
print('TTS_RATE=' + q(str(tts_rate)))
print('TTS_VOLUME=' + q(str(tts_volume)))
print('TTS_MODE=' + q(tts_mode))
print('TRAINER_TTS_TEXT=' + q(trainer_tts_text))
```

#### Speech text resolution (Python block addition)

```python
# --- TTS speech text resolution ---
tts_cfg = cfg.get('tts', {})
tts_enabled = tts_cfg.get('enabled', False) and not paused
tts_text = ''
tts_backend = tts_cfg.get('backend', 'auto')
tts_voice = tts_cfg.get('voice', 'default')
tts_rate = tts_cfg.get('rate', 1.0)
tts_volume = tts_cfg.get('volume', 0.5)
tts_mode = tts_cfg.get('mode', 'sound-then-speak')

if tts_enabled and category:
    # Chain: manifest speech_text → notification template → default
    if pick and pick.get('speech_text'):
        _speech_tpl = pick['speech_text']
    elif _tpl:
        _speech_tpl = _tpl  # already resolved notification template
    else:
        _speech_tpl = '{project} \u2014 {status}'

    try:
        tts_text = _speech_tpl.format_map(_tpl_vars)
    except Exception:
        tts_text = ''

    # Empty after interpolation → skip
    tts_text = tts_text.strip()
    if tts_text == '\u2014' or not tts_text:
        tts_text = ''
```

The `pick` variable (the chosen manifest sound entry) is already in scope from sound selection
(line 3571). The `_tpl_vars` dict is already populated from notification template resolution
(line 3730). This placement — after both sound selection and template resolution — means all
inputs are available.

`TRAINER_TTS_TEXT` reuses the existing trainer progress string verbatim — the same string that
currently renders into `TRAINER_MSG` for desktop notifications. No reformatting for speech in
this phase (resolved question #1):

```python
# After trainer reminder logic (which already computes trainer_msg):
trainer_tts_text = trainer_msg if (tts_enabled and trainer_msg) else ''
```

#### Speech text resolution (PowerShell addition)

```powershell
# --- TTS speech text resolution ---
$ttsCfg = if ($config.tts) { $config.tts } else { @{} }
$ttsEnabled = ($ttsCfg.enabled -eq $true) -and (-not $paused)
$ttsText = ""
$ttsBackend = if ($ttsCfg.backend) { $ttsCfg.backend } else { "auto" }
$ttsVoice = if ($ttsCfg.voice) { $ttsCfg.voice } else { "default" }
$ttsRate = if ($ttsCfg.rate) { $ttsCfg.rate } else { 1.0 }
$ttsVolume = if ($ttsCfg.volume) { $ttsCfg.volume } else { 0.5 }
$ttsMode = if ($ttsCfg.mode) { $ttsCfg.mode } else { "sound-then-speak" }

if ($ttsEnabled -and $category) {
    $speechTpl = ""
    if ($chosen -and $chosen.speech_text) {
        $speechTpl = $chosen.speech_text
    } elseif ($resolvedTemplate) {
        $speechTpl = $resolvedTemplate
    } else {
        $speechTpl = "{project} `u{2014} {status}"
    }

    # Interpolate template variables (same set as notification templates)
    $ttsText = $speechTpl
    foreach ($key in $tplVars.Keys) {
        $ttsText = $ttsText.Replace("{$key}", $tplVars[$key])
    }
    $ttsText = $ttsText.Trim()
    if ($ttsText -eq "`u{2014}" -or -not $ttsText) { $ttsText = "" }
}
```

#### PowerShell mode sequencing (Windows)

The PowerShell sound playback section gains the same mode-aware branching as Unix:

```powershell
if (-not $skipSound) {
    switch ($ttsMode) {
        "sound-then-speak" {
            if ($soundFile -and (Test-Path $soundFile)) { Play-Sound $soundFile $volume }
            if ($ttsText) { Invoke-TtsSpeak -Text $ttsText -Backend $ttsBackend -Voice $ttsVoice -Rate $ttsRate -Volume $ttsVolume }
        }
        "speak-only" {
            if ($ttsText) { Invoke-TtsSpeak -Text $ttsText -Backend $ttsBackend -Voice $ttsVoice -Rate $ttsRate -Volume $ttsVolume }
        }
        "speak-then-sound" {
            if ($ttsText) { Invoke-TtsSpeak -Text $ttsText -Backend $ttsBackend -Voice $ttsVoice -Rate $ttsRate -Volume $ttsVolume }
            if ($soundFile -and (Test-Path $soundFile)) { Play-Sound $soundFile $volume }
        }
    }
}
```

#### Config schema addition

```json
{
  "tts": {
    "enabled": false,
    "backend": "auto",
    "voice": "default",
    "rate": 1.0,
    "volume": 0.5,
    "mode": "sound-then-speak"
  }
}
```

Added to `config.json` defaults. Runtime code uses `cfg.get('tts', {})` with per-field defaults,
so missing keys in existing configs are safe.

#### Debug logging

TTS adds a `[tts]` log phase following the existing structured logging format:

```
[tts] enabled=true backend=native voice=Alex rate=1.0 volume=0.5 mode=sound-then-speak
[tts] text="api-server — all tests passing" source=template
[tts] cmd="scripts/tts-native.sh" pid=48291
```

Or when skipped:

```
[tts] enabled=true backend=auto resolved=none skip=no_backend
[tts] enabled=true text="" skip=empty_text
[tts] enabled=false skip=disabled
```

## Implementation Phases

### Phase 1: Config schema and `peon update` backfill

**Goal:** Existing installs gain the `tts` config section on next update, and new installs include
it by default.

**Deliverables:**
- `config.json` updated with `tts` section (6 keys, all with safe defaults)
- `peon update` config merge logic extended to backfill `tts` section without overwriting
  user-modified values (same merge pattern as every prior config addition)
- `install.ps1` Windows installer includes `tts` section in generated config

**Test strategy:**
- **Unit (BATS):** `peon update` on a config without `tts` section adds it with correct defaults.
  `peon update` on a config with existing `tts` section preserves user values.
- **Unit (Pester):** Same two cases for the Windows config generation path.

**Infrastructure:** None.

**Documentation:** None (config key docs ship with tts-docs feature).

**Dependencies:** None.

**Definition of done:**
- [ ] `config.json` contains `tts` section with 6 keys
- [ ] `peon update` backfills `tts` section on configs that lack it
- [ ] `peon update` preserves existing `tts` values when section already present
- [ ] Windows installer generates config with `tts` section
- [ ] All existing BATS and Pester tests pass (no regressions)

### Phase 2: Speech text resolution in Python block

**Goal:** The Python routing block resolves TTS speech text from the manifest/template/default
chain and outputs `TTS_*` shell variables.

**Deliverables:**
- Speech text resolution logic added to `peon.sh` Python block (after sound selection and template
  resolution)
- 8 new `print()` outputs: `TTS_ENABLED`, `TTS_TEXT`, `TTS_BACKEND`, `TTS_VOICE`, `TTS_RATE`,
  `TTS_VOLUME`, `TTS_MODE`, `TRAINER_TTS_TEXT`
- TTS config loading with safe defaults (`cfg.get('tts', {})`)

**Test strategy:**
- **Unit (BATS):** Mock events with TTS enabled verify correct `TTS_TEXT` output for each source
  in the resolution chain: (a) manifest `speech_text` present → uses it, (b) notification template
  configured → uses it, (c) neither → uses default `"{project} — {status}"`. (d) Empty text after
  interpolation → `TTS_TEXT` is empty. (e) TTS disabled → `TTS_ENABLED=false`, no `TTS_TEXT`.

**Infrastructure:** None.

**Documentation:** None.

**Dependencies:** Phase 1 (config schema).

**Definition of done:**
- [ ] Python block reads `tts` config section with safe defaults
- [ ] `TTS_TEXT` resolves from manifest `speech_text` when present
- [ ] `TTS_TEXT` falls back to notification template when no `speech_text`
- [ ] `TTS_TEXT` falls back to default template `"{project} — {status}"` when no notification template
- [ ] Empty resolved text produces empty `TTS_TEXT`
- [ ] `TTS_ENABLED=false` when TTS disabled or hook is paused
- [ ] `TRAINER_TTS_TEXT` populated with trainer progress string when trainer fires and TTS enabled
- [ ] All 8 `TTS_*` variables printed in output block

### Phase 3: `speak()` function, PID tracking, and mode sequencing (Unix)

**Goal:** `peon.sh` gains the `speak()` shell function, TTS PID management, backend resolution,
and mode-aware sequencing in `_run_sound_and_notify()`.

**Deliverables:**
- `speak()` function: backend resolution → script invocation → PID tracking
- `_resolve_tts_backend()` function: config value → script path mapping with `auto` probing
- `kill_previous_tts()` and `save_tts_pid()` functions
- `_run_sound_and_notify()` updated with mode-aware sound/TTS ordering
- Trainer reminder block updated to wait for both `.sound.pid` and `.tts.pid`, then speak
  `TRAINER_TTS_TEXT` after trainer sound
- All suppression rules (`headphones_only`, `meeting_detect`, `suppress_sound_when_tab_focused`,
  pause) applied to TTS
- `PEON_TEST=1` synchronous mode for test capture
- `[tts]` debug log phase entries

**Test strategy:**
- **Unit (BATS):** Mock backend script (logs invocation args to a file instead of speaking).
  Tests verify: (a) `speak()` invokes backend with correct args order, (b) text passed on stdin,
  (c) mode sequencing — `sound-then-speak` plays sound then speaks, `speak-only` skips sound,
  `speak-then-sound` speaks then plays sound, (d) empty `TTS_TEXT` skips TTS invocation entirely,
  (e) `TTS_ENABLED=false` skips all TTS, (f) suppression rules suppress TTS same as sound,
  (g) kill-previous kills old `.tts.pid` before new speak, (h) `auto` backend resolution probes
  scripts in order, (i) missing backend script → graceful skip.
- **Integration (BATS):** Full hook invocation with TTS enabled, mock backend, and mock `afplay`
  — verify both sound and TTS fire in correct order for each mode.

**Infrastructure:** None.

**Documentation:** None.

**Dependencies:** Phase 2 (speech text resolution).

**Definition of done:**
- [ ] `speak()` invokes resolved backend script with text on stdin
- [ ] Backend receives voice, rate, volume as positional args
- [ ] `.tts.pid` written after background TTS process starts
- [ ] `kill_previous_tts()` kills old TTS before new invocation
- [ ] `_run_sound_and_notify()` respects `TTS_MODE` for ordering
- [ ] `speak-only` mode skips `play_sound()` entirely
- [ ] All suppression rules apply to TTS
- [ ] `PEON_TEST=1` runs TTS synchronously
- [ ] `[tts]` debug log entries emitted when debug enabled
- [ ] Trainer subshell waits for both `.sound.pid` and `.tts.pid` before playing trainer content
- [ ] Trainer speaks `TRAINER_TTS_TEXT` after trainer sound when TTS enabled
- [ ] Hook return latency unchanged (TTS is async)
- [ ] Missing backend → silent skip, no error

### Phase 4: PowerShell port (Windows)

**Goal:** The Windows hook engine (`install.ps1` embedded `peon.ps1`) provides identical TTS
behavior to the Unix implementation.

**Deliverables:**
- `Invoke-TtsSpeak` function: backend resolution → `Start-Process` invocation → PID tracking
- `Resolve-TtsBackend` function: config value → script path mapping
- TTS PID management (`.tts.pid` read/write/kill)
- Mode-aware sequencing in the sound playback section
- Speech text resolution in the PowerShell routing block (mirrors Python block output)
- Trainer TTS integration
- Suppression rules applied to TTS

**Test strategy:**
- **Unit (Pester):** (a) `Resolve-TtsBackend` returns correct paths for each named backend,
  (b) `Resolve-TtsBackend -Backend auto` probes in priority order, (c) speech text resolution
  chain produces correct output for manifest/template/default sources, (d) TTS disabled → no
  `Start-Process` call, (e) mode sequencing logic branches correctly, (f) `.tts.pid` file
  management (write on speak, read/kill on next speak).

**Infrastructure:** None.

**Documentation:** None.

**Dependencies:** Phase 3 (Unix implementation validates the design; Windows mirrors it).

**Definition of done:**
- [ ] `Invoke-TtsSpeak` invokes resolved backend via `Start-Process -WindowStyle Hidden`
- [ ] Backend receives text on stdin via PowerShell pipeline
- [ ] `.tts.pid` managed (write/read/kill)
- [ ] Mode sequencing matches Unix behavior
- [ ] Speech text resolution chain matches Python block logic
- [ ] All suppression rules apply
- [ ] Trainer speaks progress when TTS enabled
- [ ] All existing Pester tests pass (no regressions)

## Migration & Rollback

**Migration:** `peon update` backfills the `tts` section into existing configs. Runtime code
defaults every `tts` field individually via `.get()` with fallbacks, so partially-populated
configs are safe. `tts.enabled` defaults to `false`, meaning TTS has no effect until explicitly
activated — zero behavior change for existing users.

**Rollback:** Clean `git revert`. The `tts` section in config is inert when `enabled: false` (the
default). Reverting the code leaves the config section harmless. No state migration — `.tts.pid`
is only created when TTS runs and is cleaned up by `kill_previous_tts`.

## Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Speech text resolution adds latency to Python block | Hook return delayed for all users, not just TTS users | Low | Resolution is pure string operations (dict lookup + `format_map`). No I/O, no subprocess. Measured at <1ms in similar template resolution for notifications. |
| Mode sequencing interacts badly with trainer wait logic | Trainer sound waits for wrong PID, causing silence or overlap | Medium | Trainer subshell waits for *both* `.sound.pid` and `.tts.pid` before playing trainer content. This prevents overlap in `sound-then-speak` mode where main TTS may still be speaking when `.sound.pid` finishes. Clear PID separation prevents cross-talk. Test all mode × trainer combinations. |
| `nohup sh -c` text quoting breaks on edge cases | Speech text with quotes, newlines, or special chars corrupts backend input | Medium | Text passed via positional `$0` in `sh -c`, not interpolated into the command string. `printf '%s\n'` used instead of `echo` to avoid flag interpretation (text starting with `-n`, `-e`). BATS tests include adversarial text (quotes, backticks, newlines, Unicode, dash-prefixed strings). |
| PowerShell `Start-Process` pipeline stdin not trivial | Windows backend doesn't receive text on stdin | Medium | Text is Base64-encoded before embedding in the `-Command` string, avoiding injection of shell metacharacters (double quotes, `$()`, backticks) from dynamic template content. The backend receives decoded text on stdin via PowerShell pipeline. |
| `auto` backend resolution adds file probes to every hook | Minor latency from checking script existence | Low | `auto` probes 3 paths max (`-x` / `Test-Path` checks). ~1ms total. Cache result in state if needed (unlikely). |

## Roadmap Connection

This design implements the **tts-integration** feature under **v2/m5** ("The peon speaks to you").
It's the P1 foundation that `tts-native`, `tts-cli`, and `tts-notifications` all depend on.

The roadmap correctly sequences the dependency chain:
`tts-integration` → `tts-native` → `tts-cli` → `tts-notifications` / `tts-docs` / `tts-elevenlabs` / `tts-piper`

No roadmap changes needed — the existing feature breakdown and dependencies match this design.

## Resolved Questions

1. **Trainer TTS text format:** Use the existing trainer progress string as-is (e.g., "75 of 300
   pushups. 50 of 300 squats. 21 percent."). Optimize for speech later if user feedback warrants it.

2. **TTS volume in speak-only mode:** Always use `tts.volume`, independent from the top-level
   `volume`. Users choosing `speak-only` set `tts.volume` to their preferred level.

3. **Tab-focused suppression:** Suppress both sound and TTS uniformly when
   `suppress_sound_when_tab_focused` is true. Granular per-modality suppression
   (`suppress_tts_when_tab_focused`) is tracked as a separate roadmap feature under v2/m5.

---

## Revision History

| Date | Author | Notes |
|------|--------|-------|
| 2026-03-28 | cameron | Initial design |
| 2026-03-28 | cameron | Design review fixes: Windows text transport uses Base64 to match ADR stdin safety guarantee; backend resolution returns consistent filenames (not mixed relative/absolute paths); find_bundled_script called with correct script filenames including extension; printf replaces echo to avoid flag interpretation; trainer waits for both .sound.pid and .tts.pid before playing; KDD #2 prose aligned with code (caller handles mode sequencing); TRAINER_TTS_TEXT derivation specified; PowerShell mode sequencing code added; SOUND_FILE guards added to mode branches |
