---
verdict: APPROVAL
card_id: as44cd
review_number: 1
commit: 58f72a6
date: 2026-04-18
has_backlog_items: true
---

# Gate 1: Completion Claim

**PASS.** The card has a clear Intent (narrative block: "after this card lands, Unix users with `tts.enabled: true` hear their peon speak"), 13 specific testable acceptance-criteria checkboxes covering every documented behavior (platform branches, engine priority, defaults, metacharacter safety, install.sh wiring, regression protection), and two unchecked manual-DoD capstones at the bottom (real Mac/Linux smoke + hook-latency regression).

The capstones are real — each is an end-to-end, unfakeable, user-observable statement:

- `echo "test" | bash scripts/tts-native.sh "default" "1.0" "0.5"` produces audible speech on a live host, exit 0
- `peon notifications test` with TTS enabled keeps hook latency within ±50ms of baseline

Both are correctly left unchecked. The executor was transparent in the work log: "Manual DoD items — NOT verified (require live hosts)" and explicitly flagged the hand-off to release-time smoke on macOS/Linux runners. That is exactly the honesty Gate 1 looks for — self-attestation is reliable, not inflated.

Checkbox integrity is sound. Every checked `[x]` item corresponds to verifiable behavior in the diff or test suite. The `tts.bats` 18 pre-existing failures on the executor's Git Bash host are honestly characterized (hardcoded `/usr/bin/python3` in `tests/setup.bash:438` — genuinely pre-existing, unrelated to this card) and the dispatcher independently confirmed 36/36 pass on the new `tests/tts-native.bats` suite.

Proceeding to Gate 2.

# Gate 2: Implementation Quality

Scope reviewed: `scripts/tts-native.sh` (223 lines), `tests/tts-native.bats` (523 lines), `install.sh` (+2 lines). Sibling card dpyzoo (Windows side) explicitly out-of-scope.

## ADR-001 compliance

Every architectural constraint in ADR-001 is honored:

- **Stdin text contract** (§Decision, lines 34-42 of the ADR) — `IFS= read -r text` on line 207 of the script; shell-metacharacter-hostile text flows through stdin, never through CLI args.
- **Fire-and-forget, silent failure policy** (§Key Factor 1, §Error output §6 of design doc) — every engine call has `|| _debug "..."`, and the script unconditionally `exit 0`s at line 223. No engine failure can propagate to the hook.
- **Platform detection via `uname -s`** with Darwin / Linux / MINGW\*/MSYS\* / fallback (matches design doc §Interface Design one-to-one).
- **No shared backend library** — script is self-contained; each `_speak_*` function does its own unit conversions; no sourced helpers.
- **Minimal calling convention** — four params (voice/rate/volume as `$1`/`$2`/`$3`, text on stdin) matches `peon.sh:460` `speak()` invocation `nohup sh -c 'printf "%s\n" "$0" | "$1" "$2" "$3" "$4"'`.
- **File organization** — `scripts/tts-native.sh` lands exactly where the ADR's filesystem map (§Decision, lines 77-85) says it should.

Design-doc Phase 1 deliverables (§Implementation Phases, lines 397-403 of design doc) all present: new executable script, `install.sh` wiring, new BATS test file, mock left intact for integration tests.

## TDD evidence

Commit order is correct TDD:

1. `38329b0` — `test(tts-native): add failing BATS unit tests for scripts/tts-native.sh` (tests first, red phase)
2. `53884c7` — `feat(tts-native): implement Unix platform-native TTS backend` (implementation second, green phase)

The test file is a specification, not a mirror — it asserts on **engine invocation shape** (flag names, arg values, stdin bytes) and **contract behavior** (always-exit-0, silent-stdout, metacharacter survival), not on internal function names or return values. That is the test-first smell: tests could have been written without reading the implementation.

Failure and edge cases are covered beyond happy paths:

- Engine-missing branches (no piper binary, no model file, neither engine installed, unsupported platform)
- `PEON_DEBUG=1` stderr visibility verified
- Engine non-zero exit does not propagate
- Empty stdin + whitespace-only stdin both handled
- Shell metacharacters (`$USER`, backticks, quotes, apostrophes, `& semicolon;`) pass through uncorrupted
- Piper sidecar handling across three states (valid JSON, missing sidecar, malformed JSON)
- `PEON_PIPER_MODEL` env-var override
- `--list-voices` per platform including the MSYS2 delegation

36 scenarios cleanly partitioned into "platform branching / unit conversions / contract / list-voices / sidecar handling" sections with section comments. Mocking strategy (PATH-shadowed `uname`/`say`/`espeak-ng`/`piper`/`aplay`/`powershell.exe` via wrapper scripts that log args + stdin) is tight — no overmocking; the real script body runs, only the engine leaves are stubbed.

## Implementation quality

The script is cleanly structured: helper functions (`_debug`, `_ignore_unused_volume`) → engine functions per platform → dispatchers (`_speak_linux`, `_list_voices`) → entry point. Header comment is thorough: usage, stdin contract, arg list, env vars, exit policy, and a link to both the ADR and design doc.

Stylistic observations:

- Executor chose `if voice == "default" then ... else ...` duplicating the engine command, rather than the design doc's `voice_flag=""` + `# shellcheck disable=SC2086; say $voice_flag ...` pattern. Both are valid; the explicit if-else avoids the shellcheck suppression and is arguably clearer. Not a blocker.
- `_ignore_unused_volume` is a micro-function documenting intent rather than adding logic. Slightly over-engineered but explicitly called for in the design doc rationale (make the omission auditable). Acceptable.
- `set -uo pipefail` (no `-e`) is correct — with `-e` the `|| _debug` patterns would exit non-zero and break the always-exit-0 invariant.
- `_speak_via_powershell` correctly uses `-NoProfile -File` with named params, avoiding the `-Command` metacharacter pitfall the ADR and design doc warn about.

## install.sh wiring

Two changes, both correct:

- Line 594 adds the remote-install `curl` fetch for `scripts/tts-native.sh`.
- Line 678 adds `chmod +x` in the post-install phase.

Local install relies on the existing `cp "$SCRIPT_DIR/scripts/"*.sh` glob at line 553, which transparently picks up the new file — the executor's work-log claim is accurate.

## Security / hardening

No exposed secrets, no privilege escalation, no injection vectors in the hook pipeline path. One observation worth noting as FOLLOW-UP: `awk "BEGIN { printf \"%d\", $rate * 200 }"` embeds `$rate` (user-controllable via `config.json`) directly into the awk program. An attacker with write access to `~/.claude/peon-ping/config.json` could inject awk code via a crafted `tts.rate` value (e.g., `"1); system(...); exit(0"`). The threat model is weak — anyone who can write `config.json` already has the user's full privilege — but it's a real gap relative to industry best practice for shell arithmetic on untrusted input. Same pattern in `_speak_espeak_ng` for `$volume`. Not a blocker for this card (the pattern is verbatim from the design doc sketch and matches existing conventions), but worth sprint follow-up.

# BLOCKERS

None.

# FOLLOW-UP

**L1 (sprint tech debt):** `awk "BEGIN { printf \"%d\", $rate * ... }"` in `_speak_macos`, `_speak_piper`, and `_speak_espeak_ng` embeds user-controllable config values (`rate`, `volume`) directly into the awk program text. If a hostile `config.json` sets `rate` to something like `1); system("rm -rf ~"); exit(0`, awk would execute it. The threat model requires the attacker to already have write access to the user's config file, so real-world impact is limited, but the hardening is cheap: pass values as awk variables (`awk -v r="$rate" 'BEGIN { printf "%d", r * 200 }'`). Consider a follow-up card or a targeted fix in the `tts-docs` or `tts-hardening` sprint — not urgent enough to block this card.

**L2 (sprint tech debt):** The MSYS2 bridge test only exercises simple voice names (`Zira`). Real SAPI5 voice names have spaces (`"Microsoft David Desktop"`, `"Microsoft Zira Desktop"`). Bash-to-powershell.exe arg handoff through `-File "$ps_script" -Voice "$voice"` should survive spaces (Windows reassembles the argv array from quoted values), but the Pester suite on the dpyzoo side should verify the parameter binder sees the intact name. Noting here so the integration test for the full Windows stack (when both cards land) covers it.

**L3 (sprint tech debt):** `tests/setup.bash:438` hardcodes `/usr/bin/python3`, which breaks `tests/tts.bats` on any host where `python3` isn't at that path (Git Bash on Windows, some macOS installs, minimal Linux images). This is pre-existing and not caused by this card, but the card does depend on `tts.bats` staying green — on CI it passes because macos-latest has `/usr/bin/python3`. Worth a small hygiene card to swap for `$(command -v python3)` or `python3` on PATH.

# Approval close-out actions

1. Manual DoD items (real Mac smoke, real Linux smoke with espeak-ng, real Linux smoke with no engines, `peon notifications test` hook-latency check) remain unchecked and should be verified before release. These are correctly deferred — they require live hosts the executor cannot reach from a Windows worktree.
2. Full `bats tests/` regression on macOS CI runner to confirm `tts.bats` integration tests (using `install_mock_tts_backend`) still pass alongside the new `tts-native.bats` — the executor could not verify this locally due to the pre-existing `/usr/bin/python3` issue on their Git Bash host.
3. No new ADR required — changes are Phase-1 delivery of ADR-001's already-accepted architecture.
