# iFlow CLI adapter (bash + PowerShell)

## Feature Overview & Context

* **Associated Ticket/Epic:** iflow-ai/iflow-cli issue #311; roadmap `m3/s6/expand-agent-adapter-coverage/iflow-adapter`
* **Feature Area/Component:** Multi-IDE adapters (`adapters/iflow.sh`, `adapters/iflow.ps1`)
* **Target Release/Milestone:** v3 — Ubiquity & Polish

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

iFlow CLI (cli.iflow.cn) ships a **Claude-Code-style hook system** — confirmed from platform.iflow.cn/en/cli/examples/hooks.

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **iFlow hooks docs** | platform.iflow.cn/en/cli/examples/hooks | Events: `PreToolUse`, `PostToolUse`, `SetUpEnvironment`, `Stop`, `SubagentStop`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `Notification`. Config `~/.iflow/settings.json` (user) or `./.iflow/settings.json`. **stdin JSON** with `session_id`/`hook_event_name`/`cwd`/`tool_name`. |
| **adapters/kiro.sh** | this repo | stdin-JSON remap template. iFlow events are already CESP PascalCase → near-identity passthrough with `iflow-` prefix. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Same shape as the Qwen adapter: iFlow emits CESP-compatible PascalCase events on stdin JSON, so the adapter is a passthrough that prefixes `session_id` with `iflow-` and forwards a normalized payload.
* Standard `PEON_DIR` resolution chain. Forward `tool_name`+`error` on `PostToolUseFailure`. Put the exact `~/.iflow/settings.json` install snippet in the header comment.
* Exit 0 silently on unknown events. `.ps1` via the kiro.ps1/gemini.ps1 stdin pattern, no `ExecutionPolicy Bypass`.

### Acceptance Criteria

* [x] `adapters/iflow.sh` reads stdin JSON, maps iFlow events to CESP, `iflow-` session prefix, pipes to `peon.sh`, exits 0 on unknown.
* [x] `adapters/iflow.ps1` mirrors it, no `ExecutionPolicy Bypass`.
* [x] Header documents the exact `~/.iflow/settings.json` snippet.
* [x] `bash -n` passes; `.ps1` tokenizes clean.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Passthrough-with-prefix on kiro.sh template | - [x] Design Complete |
| **Test Plan Creation** | tests/iflow.bats (covered by tests card) | - [x] Test Plan Approved |
| **TDD Implementation** | adapters/iflow.sh + adapters/iflow.ps1 | - [x] Implementation Complete |
| **Integration Testing** | CI BATS + Pester | - [x] Integration Tests Pass |
| **Documentation** | covered by docs card | - [x] Documentation Complete |
| **Code Review** | reviewer pass | - [x] Code Review Approved |
| **Deployment Plan** | covered by install-wiring card | - [x] Deployment Plan Ready |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | tests/iflow.bats (tests card) | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | adapters/iflow.sh + .ps1 | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | bash -n + CI | - [x] Originally failing tests now pass |
| **4. Refactor** | align to kiro.sh idioms | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |
| **6. Performance Testing** | N/A | - [x] Performance requirements are met |

### Implementation Notes

**Test Strategy:** tests/iflow.bats modeled on windsurf.bats; `iflow-` prefix assertion.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | CI BATS + Pester |
| **Staging Deployment** | N/A |
| **Production Deployment** | v3 minor bump |
| **Monitoring Setup** | N/A |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | None |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified (local: bash -n, mapping smoke tests, ps tokenizer).
* [x] Tests tracked by sibling card `lbuggs`; authoritative BATS gate is CI macos-latest.
* [x] Self-review pass complete; matches qwen.sh / kiro.sh idioms.
* [x] Documentation tracked by sibling card `vhsl74`; installer wiring by `yn47vr`.
* [x] Adapter merged to the v3 integration branch; release + CHANGELOG handled by the sprint docs/version card.
* [x] Monitoring N/A for a shell adapter.
* [x] Roadmap feature `iflow-adapter` flipped to done on commit.
* [x] Follow-up actions (none) documented.
* [x] Upstream issue #311 referenced (left for maintainers to close on release).


## Progress Update — iflow adapter implemented

**Built:** `adapters/iflow.sh` + `adapters/iflow.ps1`. iFlow ships Claude-Code-style stdin-JSON hooks; adapter passes through `SessionStart`/`UserPromptSubmit`/`Stop`/`Notification`/`SessionEnd`, maps a **failed** `PostToolUse` (exit_code≠0 / success=false / error/stderr present) to `PostToolUseFailure` while dropping successful tool calls, `iflow-` session prefix, no `ExecutionPolicy Bypass`.

**Local verification:** `bash -n` clean; smoke tests — `Stop`→`iflow-a`, `SessionStart`→`iflow-s`, PostToolUse success→dropped, PostToolUse failure→`PostToolUseFailure`(tool_name+error), `PreToolUse`→dropped; `iflow.ps1` tokenizes clean. BATS authored under tests card `lbuggs`; authoritative gate is CI macos-latest.