The reviewer flagged 3 non-blocking items, grouped into 3 cards below.
Create ONE card per group. Do not split groups into multiple cards.
The planner is responsible for deduplication against existing cards.
All cards go into the current sprint unless marked BLOCKED with a reason.

Note: The TTSNATIVE sprint already carries a follow-up tracker card (`w3ciyq` — "step-4a-ttsnative-follow-up-tracker") intended to absorb small in-scope follow-ups per the aggregation tier in planner/SKILL.md. Each group below is a small, in-scope hygiene/hardening item — if any (or all) of them fit `w3ciyq`'s aggregation criteria, append to that tracker instead of creating standalone cards. If any item exceeds the aggregation tier's scope, create a standalone card as specified.

### Card 1: Harden `scripts/tts-native.sh` awk invocations against untrusted config values
Sprint: TTSNATIVE
Files touched: `scripts/tts-native.sh`
Items:
- L1: `awk "BEGIN { printf \"%d\", $rate * 200 }"` in `_speak_macos`, `_speak_piper`, and `_speak_espeak_ng` embeds user-controllable `config.json` values (`rate`, `volume`) directly into the awk program text. A hostile config (e.g., `rate: "1); system(\"rm -rf ~\"); exit(0"`) would inject awk code. Threat model requires attacker write-access to the user's config, so real-world risk is limited, but the hardening is cheap and standard practice. Action: pass values as awk variables (`awk -v r="$rate" 'BEGIN { printf "%d", r * 200 }'`) across all three engine functions. Update the relevant BATS scenarios in `tests/tts-native.bats` if the invocation shape assertions need to reassert on the new form. Reviewer note: "not urgent enough to block this card" but explicitly called out as sprint tech debt.

### Card 2: Pester coverage for MSYS2 bridge → `tts-native.ps1` with spaced SAPI5 voice names
Sprint: TTSNATIVE
Files touched: `tests/adapters-windows.Tests.ps1` (or the equivalent Pester test file for `scripts/tts-native.ps1` landing under the dpyzoo card)
Items:
- L2: The MSYS2 bridge test in `tests/tts-native.bats` only exercises simple voice names (`Zira`). Real SAPI5 voice names contain spaces (`"Microsoft David Desktop"`, `"Microsoft Zira Desktop"`). Bash-to-powershell.exe arg handoff through `-File "$ps_script" -Voice "$voice"` should survive spaces via Windows argv re-quoting, but the Pester suite on the Windows side (dpyzoo) should explicitly verify the SAPI5 parameter binder receives the intact voice name. Action: add a Pester scenario that binds a spaced voice name into `tts-native.ps1 -Voice` and asserts the binder sees the full string. Coordinate with the dpyzoo card status — this may land as an integration test after both cards are merged.

### Card 3: Replace hardcoded `/usr/bin/python3` in `tests/setup.bash` with PATH-resolved lookup
Sprint: TTSNATIVE
Files touched: `tests/setup.bash`
Items:
- L3: `tests/setup.bash:438` hardcodes `/usr/bin/python3`, which breaks `tests/tts.bats` on any host where `python3` is not at that path (Git Bash on Windows, some macOS installs, minimal Linux images). Pre-existing issue, not caused by `as44cd`, but surfaced during this card's review because the as44cd executor could not run `tests/tts.bats` locally (18 failures all traced to this path). It passes on `macos-latest` CI because `/usr/bin/python3` exists there, which masks the portability gap. Action: swap the hardcoded path for `$(command -v python3)` (with a helpful error if missing) or `python3` on PATH. Small hygiene fix. Adding a single BATS-side assertion that `setup.bash` resolves Python without a hardcoded absolute path would guard against regression.
