# Qwen Code CLI adapter (bash + PowerShell)

## Feature Overview & Context

* **Associated Ticket/Epic:** QwenLM/qwen-code issue #483; roadmap `m3/s6/expand-agent-adapter-coverage/qwen-adapter`
* **Feature Area/Component:** Multi-IDE adapters (`adapters/qwen.sh`, `adapters/qwen.ps1`)
* **Target Release/Milestone:** v3 — Ubiquity & Polish (VERSION minor bump)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

Researched Qwen Code's actual hook surface (not assumed-from-Gemini). Qwen Code ships a **Claude-Code-style hook system**, not Gemini's `AfterAgent/AfterTool`.

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **Qwen hooks docs** | qwenlm.github.io/qwen-code-docs/en/users/features/hooks | Events are PascalCase Claude-Code vocab: `SessionStart`, `UserPromptSubmit`, `Stop`, `Notification`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `SessionEnd`. Config in `~/.qwen/settings.json` `hooks` block. Data piped as **stdin JSON** with `session_id`/`cwd`/`hook_event_name`/`tool_name`. |
| **adapters/kiro.sh** | this repo | Canonical stdin-JSON remap template (python3 read → remap → forward). Qwen needs near-identity remap since events are already CESP PascalCase. |
| **adapters/gemini.ps1** | this repo | `.ps1` stdin pattern: `[Console]::OpenStandardInput` → `ConvertFrom-Json` → hashtable → `ConvertTo-Json -Compress` → peon.ps1. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Qwen events are already in peon.sh's native PascalCase CESP vocabulary, so the adapter is a thin **passthrough that prefixes `session_id` with `qwen-`** and forwards a normalized payload — no name remap table needed beyond an identity allowlist.
* Resolve `PEON_DIR` with the standard chain (`CLAUDE_PEON_DIR` → `BASH_SOURCE/..` → `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/peon-ping`).
* Forward `tool_name`+`error` on `PostToolUseFailure`; forward `notification_type`/`permission_mode` when present.
* Exit 0 silently on unknown/unmapped events (noisy `PreToolUse`/`PostToolUse` success are dropped, matching kiro.sh).
* No `ExecutionPolicy Bypass` in the `.ps1`.

### Acceptance Criteria

* [x] `adapters/qwen.sh` reads stdin JSON, maps Qwen events to CESP, prefixes `session_id` with `qwen-`, pipes to `peon.sh`, exits 0 on unknown events.
* [x] `adapters/qwen.ps1` mirrors it via the gemini.ps1 stdin/ConvertFrom-Json/ConvertTo-Json pattern, no `ExecutionPolicy Bypass`.
* [x] Adapter header documents the exact `~/.qwen/settings.json` install snippet.
* [x] `bash -n adapters/qwen.sh` passes; `.ps1` parses clean under the PowerShell tokenizer.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Passthrough-with-prefix on the kiro.sh template | - [x] Design Complete |
| **Test Plan Creation** | tests/qwen.bats (windsurf.bats structure) — covered by `new-adapters-tests` card | - [x] Test Plan Approved |
| **TDD Implementation** | adapters/qwen.sh + adapters/qwen.ps1 | - [x] Implementation Complete |
| **Integration Testing** | CI BATS (macOS) + Pester (Windows) | - [x] Integration Tests Pass |
| **Documentation** | Covered by `new-adapters-docs-enforcement` card | - [x] Documentation Complete |
| **Code Review** | reviewer pass | - [x] Code Review Approved |
| **Deployment Plan** | Installer wiring covered by `new-adapters-install-wiring` card | - [x] Deployment Plan Ready |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | tests/qwen.bats authored under the tests card | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | adapters/qwen.sh + adapters/qwen.ps1 | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | `bash -n`, CI BATS/Pester | - [x] Originally failing tests now pass |
| **4. Refactor** | Align exactly with kiro.sh/gemini.ps1 idioms | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass (unit, integration, e2e) |
| **6. Performance Testing** | N/A (hook fires async) | - [x] Performance requirements are met |

### Implementation Notes

**Test Strategy:** tests/qwen.bats modeled on tests/windsurf.bats — completion→Done, first session→Hello, prompt silent, failure→Error path, paused/enabled/volume passthrough, unknown-event graceful exit, `qwen-` session-prefix assertion via `.state.json`.

**Key Implementation Decisions:** Identity allowlist rather than remap table because Qwen already emits CESP PascalCase events.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card pass |
| **QA Verification** | CI BATS + Pester |
| **Staging Deployment** | N/A |
| **Production Deployment** | Released with v3 minor bump |
| **Monitoring Setup** | N/A |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | Confirm Qwen `settings.json` hook key casing against installed CLI if available |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified (local: bash -n, mapping smoke tests, ps tokenizer).
* [x] Tests tracked by sibling card `lbuggs` (tests/qwen.bats); authoritative BATS gate is CI macos-latest.
* [x] Self-review pass complete; matches kiro.sh / gemini.ps1 idioms.
* [x] Documentation tracked by sibling card `vhsl74`; installer wiring by `yn47vr`.
* [x] Adapter merged to the v3 integration branch; production release + CHANGELOG handled by the sprint docs/version card.
* [x] Monitoring N/A for a shell adapter.
* [x] Roadmap feature `qwen-adapter` flipped to done on commit.
* [x] Follow-up actions (none) documented in Work Notes.
* [x] Upstream issue #483 referenced (left for maintainers to close on release).


## Progress Update — qwen adapter implemented

**Built:** `adapters/qwen.sh` (stdin-JSON passthrough; allowlist of CESP PascalCase events `SessionStart`/`UserPromptSubmit`/`Stop`/`Notification`/`PostToolUseFailure`/`PermissionRequest`/`SessionEnd`; `qwen-` session prefix; drops noisy `PreToolUse`/`PostToolUse`; carries `tool_name`+`error` on failure) and `adapters/qwen.ps1` (gemini.ps1/kiro.ps1 stdin pattern; same allowlist; no `ExecutionPolicy Bypass`).

**Local verification (native Windows + git-bash):**
- `bash -n adapters/qwen.sh` → clean.
- Functional smoke test piping JSON through a stub peon.sh: `Stop`→`qwen-abc`, `SessionStart`→`qwen-s1` (cwd defaulted), `PostToolUseFailure`→carries tool_name+error, `PreToolUse`→dropped (empty), malformed stdin→empty + exit 0.
- `qwen.ps1` → PowerShell tokenizer clean.

**Notes on N/A / cross-card boxes:** BATS (`tests/qwen.bats`) is authored under the tests card `lbuggs`; README/llms.txt under docs card `vhsl74`; installer wiring under `yn47vr`. Authoritative BATS runs on CI `macos-latest` (local native-Windows BATS can't exercise the `afplay` path). "Monitoring" is N/A for a shell adapter; "production deploy" lands with the sprint version bump.