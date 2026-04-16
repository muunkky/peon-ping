# PRD-003: The Peon Speaks to You — Text-to-Speech for peon-ping

> **Status**: Draft | **Date**: 2026-03-28 | **Author**: cameron
> **Roadmap**: v2/m5

## Problem Statement

Peon-ping communicates through pre-recorded audio files — a finite library of static sound clips mapped to event categories. This works well for reactive feedback ("work complete," "something need doing?") but breaks down when the content needs to be dynamic. A trainer reminder can play a nagging voice line, but it can't say "45 of 300 pushups done — you're behind pace." A notification can pop up a text template with `{project}` and `{summary}`, but the audio is always the same generic clip regardless of context. Users who rely on audio cues (eyes on code, not on notification popups) miss the richest information peon-ping has — the template-rendered text that only appears in silent desktop toasts.

The gap widens as peon-ping grows more context-aware. Path rules, notification templates, and the trainer already generate dynamic text that's never spoken. Every new feature that produces meaningful text (and there will be more) hits the same wall: the audio layer is static, the text layer is dynamic, and they can't meet.

## Background & Context

### Why now

Three factors converge:

1. **The trainer shipped (v2/m3) with text it can't speak.** Trainer reminders generate progress strings like "45/300 pushups, 20/300 squats — 22% done" that appear in desktop notifications but never in audio. The entire value proposition of the trainer is nagging you to exercise — and nagging is dramatically more effective when it's spoken aloud rather than displayed in a toast you've already learned to ignore. The trainer is the killer app for TTS.

2. **Notification templates shipped (v2/m2) with variables that beg to be read.** Templates like `"✅ {project} — {summary}"` render rich context into desktop notifications. Users who configured custom templates did so because they want *more information* from peon-ping's audio channel, not less. TTS closes the loop: the same template that renders a notification can be spoken.

3. **Platform-native TTS is free and zero-dependency.** macOS ships `say`, Windows ships `System.Speech.Synthesis` (SAPI5), and Linux has `espeak-ng` (installed by default on most distros) plus the emerging `piper` for neural quality. The baseline implementation requires no API keys, no downloads, and no configuration — just the OS the user already has. This means TTS can be a toggle, not a project.

### Prior art

- **macOS `say` command**: Ships on every Mac. Supports 50+ voices across languages. Async via `&`. Quality ranges from robotic (older voices) to natural (Siri Neural voices on macOS 14+). Zero configuration.
- **Windows SAPI5 (`System.Speech.Synthesis`)**: Ships on every Windows install. `Add-Type -AssemblyName System.Speech` in PowerShell. 2-3 built-in voices, more installable via Settings → Time & Language → Speech. Async via `SpeakAsync()` or `Start-Process`.
- **Linux `espeak-ng`**: Available in every major distro's package manager. Robotic but functional. `piper` (C++ neural TTS from Rhasspy) offers dramatically better quality with ~50MB model downloads.
- **Accessibility tools**: Screen readers (VoiceOver, NVDA, Narrator) prove that system TTS is reliable enough for continuous professional use. peon-ping's usage is far lighter — a few phrases per hour.
- **Gaming**: Warcraft III itself used pre-recorded voice lines rather than TTS, but modern games increasingly use TTS for dynamic content (enemy callouts, quest updates). The peon-ping aesthetic is pre-recorded character voice lines *supplemented* by TTS for dynamic content — not replaced by it.
- **CLI tools with TTS**: Rare. Most CLI tools are silent. `espanso` (text expander) has TTS for accessibility. `watson` (time tracker) has optional spoken summaries. peon-ping would be a first-mover for coding tool audio feedback with TTS.

### Current audio pipeline

The hook pipeline in `peon.sh` (and `peon.ps1` on Windows) follows this flow:

1. JSON event arrives on stdin from IDE hook
2. Python block (or PowerShell on Windows) maps event → CESP category → pack manifest → random sound file
3. Shell plays sound async via platform backend (`afplay`, `pw-play`, `MediaPlayer`, etc.)
4. Optionally, trainer reminder sound plays after main sound with delay
5. Desktop/mobile notifications sent with template-rendered text

TTS would insert after step 2: when TTS is enabled and the selected sound entry has a `speech_text` field (or a notification template is configured), generate and play spoken audio instead of or after the static sound file. The async playback pattern (step 3) already handles fire-and-forget audio — TTS just needs to produce a playable audio stream or invoke a system command that speaks directly to the audio device.

### What exists today

- **Zero TTS code.** No TTS references in `peon.sh`, `peon.ps1`, or any adapter.
- **`label` field in manifests.** Every sound entry already has a `"label"` string (e.g., `"Ready to work?"`, `"Work, work."`). These are used for notification text and `peon preview` output. They're natural candidates for TTS text — but they're character-specific flavor text, not dynamic content.
- **Notification templates.** Five template keys (`stop`, `error`, `permission`, `idle`, `question`) with variable interpolation (`{project}`, `{summary}`, `{tool_name}`, `{status}`, `{event}`). These already produce the dynamic text that TTS would speak.
- **Trainer progress strings.** Generated during reminder logic: rep counts, percentages, pace status. Currently only rendered into notification messages.
- **44 config keys** in `config.json`. No `tts` section exists. The `trainer` section (nested object) establishes the pattern for adding a new feature namespace.

## User Segments

### Trainer user who wants spoken progress
- **Who**: Developer using the peon trainer for daily exercise goals (pushups, squats). Has trainer enabled, gets reminder sounds every 20 minutes during coding sessions.
- **Current pain**: Trainer reminders play a generic nag sound. The actual progress ("45/300 pushups, behind pace") only appears in a desktop notification toast that auto-dismisses in 4 seconds. If they're in flow, they hear the sound but miss the numbers. They have to run `peon trainer status` to see where they stand.
- **Desired outcome**: The peon *tells* them their progress: "45 of 300 pushups. You're slacking." They hear the information without looking away from code.
- **Priority**: Primary

### Power user who wants richer audio context
- **Who**: Developer who already configured notification templates with `{project}` and `{summary}` variables because they want peon-ping to communicate *what happened*, not just *that something happened*. Likely uses multiple projects with path rules.
- **Current pain**: The notification template renders useful text in a popup, but the audio is always the same pack sound regardless of project or event details. The audio channel carries no information beyond "task complete" vs "error" vs "needs input."
- **Desired outcome**: After the character voice line plays, a brief spoken summary adds context: "myproject — all tests passing." Or the voice line is replaced entirely with a spoken template.
- **Priority**: Primary

### Pack creator who wants voiced characters
- **Who**: Community pack author creating a character voice pack (e.g., GLaDOS, Kerrigan, a custom AI personality). Wants the character to "say" dynamic things that pre-recorded clips can't cover.
- **Current pain**: Every line must be pre-recorded. If a pack wants to say the project name or a custom quip based on event data, there's no mechanism. The pack is limited to a fixed library of clips.
- **Desired outcome**: Pack manifests can define `speech_text` templates per sound entry. When TTS is enabled, the character "speaks" dynamic content using the pack author's chosen voice/style configuration. The manifest becomes a script, not just a playlist.
- **Priority**: Secondary

### Accessibility-conscious user
- **Who**: Developer who prefers or requires audio feedback over visual notifications. May have visual attention constraints, use a tiling window manager where notifications are hidden, or work in a terminal-only environment (SSH) where desktop notifications aren't available.
- **Current pain**: peon-ping's audio is limited to categorical sounds — they know *something* happened but not *what*. Desktop notifications (the informational channel) require visual attention. Mobile push is too slow for real-time context.
- **Desired outcome**: TTS provides the same information as desktop notifications, delivered through the audio channel. They can stay eyes-on-code and still know what happened.
- **Priority**: Secondary

## Goals & Non-Goals

### Goals
- Hook events can optionally trigger spoken output — in addition to, instead of, or after the normal sound file
- Platform-native TTS works out of the box on macOS, Windows, and Linux with zero configuration beyond `peon tts on`
- Dynamic content from notification templates and trainer progress can be spoken, not just displayed
- Pack manifests can define per-entry spoken text with template variables, enabling character-voiced dynamic content
- TTS backend is pluggable — the integration layer abstracts over native, cloud, and local AI engines
- TTS playback is async and does not block hook return (same contract as sound playback)
- CLI commands (`peon tts on/off/status/test/voices/backend`) provide full control without config file editing

### Non-Goals
- **Replacing pre-recorded voice packs with TTS.** TTS supplements pack audio — it doesn't replace the character voice lines that define each pack's personality. The peon's "work work" stays as a WAV file. TTS adds "myproject — all tests passing" after it.
- **Real-time voice cloning or voice matching.** Making TTS output sound like the pack's character (e.g., making `say` sound like a Warcraft peon) is a fascinating future direction but requires custom voice models. Out of scope for this milestone.
- **Streaming TTS during long events.** TTS speaks short phrases (1-2 sentences). Narrating full task output or streaming commentary during agent execution is a different product.
- **SSML or advanced speech markup.** Platform-native TTS supports basic rate/pitch/volume. Rich SSML (pauses, emphasis, phoneme control) varies wildly across backends and adds complexity for marginal benefit at this stage.
- **Automatic language detection.** TTS speaks in the language of the configured voice. Multilingual auto-detection is complex and error-prone. Users select their preferred voice, which implies a language.
- **TTS for the relay/remote path.** SSH and devcontainer users route audio through `relay.sh`. TTS relay support is deferred to a future milestone to avoid overloading scope — but the architecture must not preclude it.

## User Experience

### Scenario 1: First-time TTS activation

A user has been using peon-ping for weeks with the default peon pack. They hear "work work" on task completion and "something need doing?" on permission requests. They want to try TTS.

```
$ peon tts on
✓ TTS enabled (backend: native, voice: default)
  Speak a test phrase with: peon tts test

$ peon tts test
🔊 Speaking: "Ready to work? This is peon-ping text to speech."
```

The system voice speaks the test phrase through the same audio output as sound files. On macOS, this is `say`. On Windows, SAPI5. On Linux, whatever's available (`espeak-ng` or `piper`).

From this point, hook events trigger both the normal pack sound AND a brief spoken phrase. The sound plays first (character identity), then TTS speaks dynamic content (information).

```
[hook fires: Stop event, project "api-server", summary "all 47 tests passing"]

🔊 plays: peon/sounds/task_complete/work_work.mp3
🔊 speaks: "api-server — all 47 tests passing"
```

The spoken text comes from the user's notification template for the `stop` category. If no template is configured, TTS speaks a sensible default: `"{project} — {status}"`.

### Scenario 2: Trainer with spoken progress

A user has the trainer enabled with 300 pushups and 300 squats daily. After a hook event, the trainer reminder fires:

```
[hook fires: Stop event]

🔊 plays: peon/sounds/task_complete/okie_dokie.mp3     (main sound)
   ... 0.5s gap ...
🔊 plays: trainer/sounds/remind/do_pushups.mp3          (trainer nag)
🔊 speaks: "75 of 300 pushups. 50 of 300 squats. You're at 21 percent."
```

The trainer's existing reminder sound plays first (character continuity), then TTS speaks the dynamic progress that previously only appeared in a notification toast. The spoken summary replaces the need to check `peon trainer status` or read a disappearing popup.

When the user is slacking (past noon, below 25% progress):

```
🔊 plays: trainer/sounds/slacking/stop_touching.mp3
🔊 speaks: "30 of 300 pushups. 10 percent. Pick it up."
```

### Scenario 3: Pack manifest with speech_text

A pack author creating a "Mission Control" pack wants dynamic spoken content. They add `speech_text` to their manifest entries:

```json
{
  "categories": {
    "task.complete": {
      "sounds": [
        {
          "file": "sounds/mission_complete.mp3",
          "label": "Mission complete",
          "speech_text": "Mission complete on {project}. {summary}"
        }
      ]
    },
    "task.error": {
      "sounds": [
        {
          "file": "sounds/houston.mp3",
          "label": "Houston, we have a problem",
          "speech_text": "Alert. {project} encountered an error. {summary}"
        }
      ]
    }
  }
}
```

When TTS is enabled, `speech_text` templates are interpolated with event variables and spoken after the sound file. When TTS is disabled, only the sound file plays (existing behavior, no regression).

### Scenario 4: TTS-only mode (no sound files)

A user wants spoken feedback without pack sounds — maybe they're in a meeting, want quieter output, or prefer TTS for accessibility:

```
$ peon tts on --mode speak-only
✓ TTS enabled (mode: speak-only, backend: native, voice: default)
```

In `speak-only` mode, the pack sound file is skipped entirely. Only the TTS phrase plays. The volume, async behavior, and suppression rules (headphones-only, tab-focused muting) all apply to TTS the same way they apply to sound files.

### Scenario 5: Choosing a voice

```
$ peon tts voices
Available voices (backend: native):
  Samantha (en_US)     ← current
  Alex (en_US)
  Daniel (en_GB)
  Kyoko (ja_JP)
  Thomas (fr_FR)
  ... (23 more — run with --all to see full list)

$ peon tts voice Daniel
✓ TTS voice set to Daniel (en_GB)

$ peon tts test
🔊 Speaking: "Ready to work? This is peon-ping text to speech."
   (in Daniel's British English voice)
```

Voice enumeration delegates to the platform: `say -v ?` on macOS, `Get-InstalledVoice` on Windows, `espeak-ng --voices` on Linux.

### Error & Edge Cases

**No TTS engine available (Linux minimal install):**
```
$ peon tts on
⚠ No TTS engine found. Install espeak-ng: sudo apt install espeak-ng
  TTS will remain disabled until a backend is available.
```
TTS fails gracefully — sound files continue playing normally. The user gets a clear action to fix it.

**TTS takes too long:**
TTS invocations inherit the same async pattern as sound playback — fire-and-forget via background process. If TTS takes 2 seconds to synthesize while the system `say` command buffers, it doesn't block the hook. A safety timeout (matching the existing 8-second audio timeout) kills runaway TTS processes.

**Empty speech text:**
If `speech_text` is empty or all template variables resolve to empty strings, TTS is silently skipped for that event. No empty audio plays.

**TTS + relay (SSH/devcontainer):**
TTS is not available over the relay in this milestone. The relay serves sound files only. Users in remote sessions hear pack sounds but not TTS. A future milestone can extend the relay protocol with a `/speak` endpoint. This is an explicit non-goal, documented so users aren't surprised.

## Success Criteria

| Criterion | Measurement | Target |
|-----------|-------------|--------|
| Zero-config activation | Steps from install to hearing TTS | `peon tts on` + `peon tts test` — two commands, no API keys, no downloads (macOS/Windows) |
| Hook latency unchanged | Time from hook invocation to hook return | No measurable increase — TTS is async, fires after hook returns |
| Trainer speaks progress | Trainer reminder includes spoken rep counts | 100% of trainer reminders with TTS enabled include spoken progress |
| Template variables spoken | Notification template text rendered as speech | `{project}`, `{summary}`, `{tool_name}`, `{status}` all resolve in spoken output |
| Platform coverage | TTS works on all supported platforms | macOS, Windows, Linux (with espeak-ng installed) |
| Pack manifest speech | `speech_text` field in manifests triggers TTS | Verified with at least one official pack adding speech_text entries |
| Graceful degradation | Behavior when TTS backend unavailable | Sound files play normally, warning on `peon tts on`, no errors during hooks |
| Backend pluggability | Adding a new TTS backend | New backend requires implementing one function/scriptblock, no changes to hook pipeline |

## Scope & Boundaries

### In Scope
- TTS integration layer in `peon.sh` (Python block) and `peon.ps1` (PowerShell) with pluggable backend contract
- Platform-native TTS backend: macOS `say`, Windows `System.Speech.Synthesis`, Linux `espeak-ng`/`piper` priority chain
- `tts` config section in `config.json` (enabled, backend, voice, rate, volume, mode)
- TTS CLI commands: `peon tts on/off/status/test/voices/voice/backend`
- Notification template text rendered as TTS speech after pack sound
- Trainer progress strings spoken during trainer reminders
- `speech_text` field in CESP manifest schema for pack-defined spoken content
- Shell completions updates for new CLI commands
- BATS tests (Unix) and Pester tests (Windows) for TTS pipeline
- Documentation: README, README_zh, llms.txt, help text

### Out of Scope
- **ElevenLabs TTS backend** — deferred to its own feature (`v2/m5/tts-elevenlabs`). The pluggable architecture supports it, but API key management, audio caching, and cost controls are their own body of work. Each cloud/AI backend ships as an independent feature — no generic "cloud backends" layer.
- **Piper TTS backend (local neural)** — deferred to its own feature (`v2/m5/tts-piper`). BYO binary and model. Piper as a Linux native fallback (detected in the espeak-ng priority chain) is in scope for Phase 1; Piper as a standalone managed backend with model downloads is not.
- **Voice cloning / character voice matching** — making TTS output match pack character voices requires custom voice models. Fascinating but premature.
- **TTS over relay (SSH/devcontainer)** — requires relay protocol extension. The architecture must not preclude it, but implementation is deferred.
- **CESP spec changes** — `speech_text` is an optional extension field. The CESP v1.0 spec at openpeon doesn't need a version bump for additive optional fields, but should be documented in the spec's "extensions" section.
- **Multilingual auto-detection** — users pick a voice (which implies a language). Auto-detecting the language of dynamic content and switching voices is complex and deferred.

### Future Considerations
- Each additional TTS backend (ElevenLabs, OpenAI, Piper, etc.) ships as its own feature implementing the `speak()` contract — no generic multi-provider abstraction layers. Only universal infrastructure (the contract itself, config schema, CLI framework) is shared.
- TTS caching (text hash → cached audio file) ships with the first backend that needs it (ElevenLabs) — not pre-built speculatively in the integration layer
- Voice profiles per pack (manifests declaring a preferred TTS voice/rate for their character) would let pack authors control the TTS experience; the config schema should not preclude this
- The relay `/speak` endpoint should accept the same parameters as the local TTS contract

## Delivery Phases

### Phase 1: "peon tts on" — integration, native backends, and CLI

**Value statement:** Users can run `peon tts on` and hear their peon speak dynamic content using their OS's built-in voice — on any platform, with zero setup.

This phase ships the complete vertical slice: the backend contract (infrastructure), platform-native implementations (first backend), and CLI commands (user controls). These build on each other in sequence — the contract before the backends, the backends before the CLI — but they ship together because none delivers user value alone.

**What ships:**

*Integration layer (tts-integration):*
- `tts` section in `config.json` with defaults (`enabled: false`, `backend: "auto"`, `voice: "default"`, `rate: 1.0`, `volume: 0.5`, `mode: "sound-then-speak"`)
- Backend contract: `speak(text, voice, rate, volume)` → async fire-and-forget
- `auto` backend resolution: detect available TTS engine, pick best for platform
- Hook pipeline integration: after sound selection, if TTS enabled, resolve speech text and invoke backend
- Speech text resolution: notification template for category → default template (`"{project} — {status}"`). The `speech_text` manifest field ships in Phase 2.
- TTS respects all existing suppression rules: `headphones_only`, `suppress_sound_when_tab_focused`, pause/mute state
- TTS mode config: `sound-then-speak` (default), `speak-only`, `speak-then-sound`

*Platform-native backends (tts-native):*
- macOS: `say -v {voice} -r {rate} --volume={volume} "{text}"` via `nohup ... &`
- Windows: `System.Speech.Synthesis.SpeechSynthesizer` via `Start-Process` (detached, matching `win-play.ps1` pattern)
- Linux: `espeak-ng` (fallback) → `piper` (preferred if installed, BYO) priority chain
- Voice enumeration logic per platform for the voices command

*CLI commands (tts-cli):*
- `peon tts on`, `peon tts off`, `peon tts status`, `peon tts test`, `peon tts voices`, `peon tts voice {name}`, `peon tts backend {name}`
- Shell completions (bash, fish) for all new subcommands
- `peon status --verbose` shows TTS state

*Testing:*
- BATS tests (Unix) and Pester tests (Windows) for integration, backends, and CLI
- `peon update` backfills `tts` config section for existing installs

**Launch criteria:**
- `peon tts on && peon tts test` speaks on macOS, Windows, and Linux (with espeak-ng)
- Hook events trigger TTS after sound file with no measurable hook latency increase
- `peon tts voices` enumerates available voices on each platform
- `peon tts off` fully disables TTS with no residual behavior
- All existing tests pass (no regressions in sound-only behavior)

**Dependencies:**
- None. The hook pipeline, config system, async playback pattern, and CLI framework all exist.

### Phase 2: Spoken notifications, trainer reminders, and pack speech

**Value statement:** Trainer reminders speak your exercise progress aloud, notification templates become audible, and pack authors can script dynamic spoken content — the peon tells you *what happened*, not just *that something happened*.

This phase adds the dynamic content sources that make TTS genuinely useful beyond default templates. It builds on Phase 1's working TTS pipeline and CLI.

**What ships:**

*Notification template speech (tts-notifications):*
- All five notification template categories (`stop`, `error`, `permission`, `idle`, `question`) spoken with full variable interpolation (`{project}`, `{summary}`, `{tool_name}`, `{status}`, `{event}`)
- Missing variables render as empty strings (no `{undefined}` in speech)

*Trainer spoken progress (tts-notifications):*
- After trainer reminder sound, speak progress string ("75 of 300 pushups. 50 of 300 squats. 21 percent.")
- Trainer slacking TTS: harsher spoken content when behind pace ("30 of 300 pushups. 10 percent. Pick it up.")

*Pack manifest speech_text (tts-notifications):*
- `speech_text` field in CESP manifest sound entries — optional template string with event variables
- Speech text resolution chain updated: manifest `speech_text` → notification template → default template
- Per-pack voice hint in manifest (`"tts_voice": "Alex"`) — advisory, user config overrides
- At least one official pack (likely `peon`) updated with `speech_text` entries demonstrating the feature

**Launch criteria:**
- Trainer reminders with TTS enabled speak accurate rep counts and percentages
- Pack with `speech_text` entries has dynamic text spoken after sound files
- All five notification template categories produce correct spoken output
- Missing template variables render as empty (no literal `{undefined}` in speech)

**Dependencies:**
- Phase 1 (working TTS pipeline, native backends, and CLI)

### Phase 3: Documentation

**Value statement:** Users and pack creators have complete guides for using and extending TTS, and the feature is discoverable from every documentation surface.

Ships after Phases 1 and 2 so documentation covers the full feature including trainer speech, notification templates, and manifest `speech_text`.

**What ships:**
- README.md TTS section: setup, configuration, mode comparison, voice selection, troubleshooting
- README_zh.md: Chinese translation of TTS section
- `docs/public/llms.txt` updated with TTS context
- `peon help` output updated with TTS commands
- Pack author guide: how to add `speech_text` to manifests
- Voice quality comparison per platform (managing expectations for espeak-ng vs. macOS Neural vs. SAPI5)

**Dependencies:**
- Phase 2 (spoken notifications, trainer, and manifest speech — so docs cover everything)

## Technical Considerations

### Platform-native TTS capabilities and constraints

**macOS `say`:**
- Ships on every macOS install since 10.0
- 50+ voices, Siri Neural voices on macOS 14+ (dramatically better quality)
- Async via `nohup say ... &` — matches existing `afplay` pattern
- Rate: words per minute (default 175-200). Volume: 0.0-1.0 float
- Gotcha: `say` writes to default audio output device. If `use_sound_effects_device` is enabled for pack sounds (routing to Sound Effects device via `peon-play.swift`), TTS needs the same routing or it goes to a different device. Phase 1 should document this — full device routing for TTS is a follow-up.

**Windows `System.Speech.Synthesis`:**
- Ships on every Windows 10/11 install
- 2-3 built-in voices (David, Zira, Mark). More installable via Settings
- Async via `SpeakAsync()` in the same `Start-Process -WindowStyle Hidden` pattern as `win-play.ps1`
- Rate: -10 to 10 integer scale. Volume: 0-100 integer
- Gotcha: PowerShell startup cost (~200ms) for `Start-Process`. Same cost as `win-play.ps1` — already budgeted in the hook timing.

**Linux `espeak-ng` / `piper`:**
- `espeak-ng`: available in apt/dnf/pacman. Robotic quality but universal. Rate: words per minute. Volume: 0-200 amplitude.
- `piper`: Neural quality, C++ binary, ~50MB model download. Growing fast in the Linux TTS space (Rhasspy/Home Assistant ecosystem). If installed, dramatically better than espeak-ng.
- Priority chain mirrors the existing audio backend chain (`pw-play` → `paplay` → `ffplay` → ...) — pick the best available.

### Async playback contract

TTS must follow the exact same async contract as sound playback:
1. Fire-and-forget via background process (`nohup ... &` on Unix, `Start-Process` on Windows)
2. PID tracked for kill-previous-sound behavior (`.sound.pid` or new `.tts.pid`)
3. Safety timeout (8 seconds, matching `win-play.ps1`)
4. No blocking of hook return under any circumstances
5. `PEON_TEST=1` runs TTS synchronously for test capture

### Config schema addition

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

- `backend`: `"auto"` | `"native"` | (future: `"elevenlabs"`, `"openai"`, `"piper"`)
- `voice`: `"default"` (platform default) or voice name string
- `rate`: float multiplier, 1.0 = normal speed. Normalized per backend.
- `volume`: float 0.0-1.0, normalized per backend (same pattern as main volume)
- `mode`: `"sound-then-speak"` (default) | `"speak-only"` | `"speak-then-sound"`

### Manifest schema extension

```json
{
  "file": "sounds/task_complete/work_work.mp3",
  "label": "Work, work.",
  "speech_text": "{project} task complete. {summary}"
}
```

- `speech_text`: optional string with template variables. When present and TTS enabled, spoken after (or instead of, per mode) the sound file.
- Falls back to notification template → default template → no TTS if absent.
- Template variables: same set as notification templates (`{project}`, `{summary}`, `{tool_name}`, `{status}`, `{event}`).

### Debug logging integration

The structured logging system (v2/m4) already covers all hook decision phases. TTS adds new log entries:
- `[tts]` phase: backend resolution, voice selection, text interpolation, speak command, PID
- Follows existing `[play]`, `[notify]`, `[trainer]` log format patterns
- Zero overhead when debug disabled (same no-op pattern)

### Observability

- `peon tts status` shows current config, detected backend, active voice
- `peon status --verbose` includes TTS state in its output
- Debug logs capture every TTS decision (backend, voice, resolved text, command invoked, PID)
- Failed TTS (backend not found, process error) logged at `[tts]` phase but never causes hook failure

## Risks & Open Questions

### Risks
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| TTS quality too robotic on Linux (espeak-ng) | Users disable TTS after trying it once — poor first impression | Medium | Detect piper availability and prefer it. Document voice quality tiers in README. Don't oversell native quality. |
| TTS latency adds perceived delay | Users feel peon-ping is slower even though hook return isn't blocked | Low | TTS fires in background. `sound-then-speak` mode means the immediate sound file plays instantly — TTS follows. User perceives responsiveness from the sound, information from TTS. |
| Audio device routing mismatch | TTS speaks on different device than pack sounds (macOS Sound Effects device) | Medium | Phase 1 documents the limitation. Follow-up adds device routing for TTS (extend `peon-play.swift` or use `say -a` device flag). |
| Pack authors don't adopt speech_text | Feature exists but no packs use it — community adoption stalls | Low | Ship at least one official pack (peon) with speech_text entries. Make speech_text optional so it doesn't burden pack authors who don't want it. Fallback to notification templates means TTS works without any manifest changes. |
| Config migration complexity | Existing users need tts section backfilled on update | Low | Same pattern as every prior config addition — `peon update` merges new defaults. Runtime code uses `.get('tts', {})` with fallback defaults. Battle-tested pattern. |

### Resolved Questions
- **TTS volume is independent of main volume.** `tts.volume` is separate from the top-level `volume`. Users mixing character voice lines with system TTS voice will want different levels — pack sounds loud, TTS quiet, or vice versa.
- **`speak-only` mode still fires desktop notifications.** Even when TTS replaces the sound file, desktop notifications still appear with the rendered template text. Audio and visual are different modalities serving different situations — a user may miss the spoken text but catch the popup, or vice versa.
- **Piper is BYO on Linux.** Phase 1 treats piper as "use if already installed with a model." No auto-download of piper models. `peon tts on` detects piper if present, falls back to espeak-ng otherwise. Managed piper setup (model downloads, default model selection) can follow in a later phase. Note: primary development and testing happens on Windows and macOS — Linux TTS will be best-effort with CI validation on espeak-ng availability.

## Related Documents

- **v2/m5 "The peon speaks to you"** — parent roadmap milestone defining TTS features and success criteria
- **[PRD-002: Hook Observability](PRD-002-hook-observability.md)** — structured logging (v2/m4) that TTS integrates with via `[tts]` log phase
- **[Trainer mode design](../plans/2026-02-16-trainer-mode-design.md)** — trainer architecture that TTS extends with spoken progress
- **[Notification templates design](../plans/2026-02-24-notification-templates-design.md)** — template system that TTS renders as speech
- **Async audio and safe state on Windows** — the `Start-Process -WindowStyle Hidden` pattern, atomic state writes, and 8-second safety timeout established during the Windows native port; TTS backends inherit this pattern (see `scripts/win-play.ps1` and `peon.ps1` async invocation)
- **[Structured hook logging design](../designs/structured-hook-logging.md)** — debug logging format TTS emits to
- **[CESP v1.0 spec](https://github.com/PeonPing/openpeon)** — pack manifest schema that gains optional `speech_text` field

---

## Revision History

| Date | Author | Notes |
|------|--------|-------|
| 2026-03-28 | cameron | Initial draft |
| 2026-03-28 | cameron | Align delivery phases with updated roadmap sequencing; resolve speech_text Phase 1/2 contradiction; individual backends replace generic cloud/AI layers; resolve open questions (independent TTS volume, speak-only keeps notifications, piper BYO) |
