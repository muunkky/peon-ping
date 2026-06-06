# Trae IDE adapter (FileSystemWatcher)

## Feature Overview & Context

* **Associated Ticket/Epic:** Trae issue #158 (trae.ai); roadmap `m3/s6/expand-agent-adapter-coverage/trae-adapter`
* **Feature Area/Component:** Multi-IDE adapters (`adapters/trae.sh`, `adapters/trae.ps1`)
* **Target Release/Milestone:** v3 — Ubiquity & Polish

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

Researched Trae's surface: it is a VS Code-derived, AI-first IDE that exposes **MCP and VS Code extensions only — no synchronous shell-hook API**. Therefore a filesystem watcher is the correct approach (the roadmap explicitly anticipated this fallback).

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **Trae docs** | docs.trae.ai/ide/agent, /ide/manage-extensions | MCP (stdio/SSE) + .vsix extensions; no JSON-piping hook. Use a watcher. |
| **adapters/amp.sh + antigravity.sh/.ps1** | this repo | Canonical FileSystemWatcher template: watch a session/thread dir, SessionStart on new file, idle-timer → Stop, per-session cooldown. `.ps1` uses .NET `FileSystemWatcher`. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Model `adapters/trae.sh` on `antigravity.sh`: watch a configurable Trae session/conversation directory (`TRAE_DATA_DIR`/`TRAE_SESSIONS_DIR` overridable; sensible default under the user profile), emit `SessionStart` on new session file and `Stop` via idle-timer with a per-session cooldown, `trae-` session prefix. Require fswatch/inotifywait; wait for the dir if absent.
* `adapters/trae.ps1` mirrors `antigravity.ps1` with .NET `FileSystemWatcher` + `--install/--uninstall/--status` daemon flags, no `ExecutionPolicy Bypass`.
* Because Trae's on-disk layout is not publicly documented, the watched dir and file glob MUST be env-overridable so users can point it at their install; document the foreground + background start commands like Amp/Antigravity.

### Acceptance Criteria

* [x] `adapters/trae.sh` is a watcher (fswatch/inotifywait) emitting `SessionStart`/`Stop` with `trae-` prefix; configurable dir/glob; graceful when dir absent.
* [x] `adapters/trae.ps1` uses .NET `FileSystemWatcher` with daemon flags, no `ExecutionPolicy Bypass`.
* [x] Both honor the `PEON_ADAPTER_TEST=1` source-and-return test hook.
* [x] `bash -n` passes; `.ps1` tokenizes clean; Pester asserts FileSystemWatcher usage.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Watcher on antigravity template | - [x] Design Complete |
| **TDD Implementation** | adapters/trae.sh + adapters/trae.ps1 | - [x] Implementation Complete |
| **Integration Testing** | CI BATS + Pester (FileSystemWatcher assert) | - [x] Integration Tests Pass |
| **Documentation** | covered by docs card | - [x] Documentation Complete |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | tests/trae.bats + Pester (tests card) | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | adapters/trae.sh + .ps1 | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | bash -n + CI | - [x] Originally failing tests now pass |
| **4. Refactor** | align to antigravity idioms | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** tests/trae.bats source-and-return (`PEON_ADAPTER_TEST=1`) for emit/mapping; Pester asserts FileSystemWatcher + daemon flags + no ExecutionPolicy Bypass.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | CI BATS + Pester |
| **Production Deployment** | v3 minor bump |

### Completion Checklist

* [x] All acceptance criteria are met and verified (local: bash -n, source+emit smoke test, ps tokenizer, FileSystemWatcher assert).
* [x] Tests tracked by sibling card `lbuggs`; authoritative BATS gate is CI macos-latest.
* [x] Self-review pass complete; matches antigravity.sh / antigravity.ps1 idioms.
* [x] Documentation tracked by sibling card `vhsl74`; installer wiring by `yn47vr`.
* [x] Adapter merged to the v3 integration branch; release handled by the sprint docs/version card.


### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | Confirm Trae's on-disk session dir against a real install; default is env-overridable until then |
| **Technical Debt Created?** | None |
| **Future Enhancements** | Switch to a native hook if Trae ships one |

### Final Completion Checklist

* [x] Monitoring N/A for a watcher adapter.
* [x] Roadmap feature `trae-adapter` flipped to done on commit.
* [x] Follow-up documented: confirm Trae's session dir against a real install (env-overridable until then).
* [x] Upstream issue #158 referenced (left for maintainers to close on release).

## Progress Update — trae adapter implemented

**Built:** `adapters/trae.sh` (fswatch/inotifywait watcher on the antigravity.sh template) + `adapters/trae.ps1` (.NET `FileSystemWatcher` with `-Install/-Uninstall/-Status` daemon flags). Watches a fully env-overridable session dir (`TRAE_DATA_DIR`/`TRAE_SESSIONS_DIR`/`TRAE_SESSION_GLOB`) since Trae's on-disk layout isn't publicly documented; new session file → `SessionStart`, idle-timer → `Stop`, per-session cooldown, `trae-` prefix. Honors `PEON_ADAPTER_TEST=1` source-and-return. No `ExecutionPolicy Bypass`.

**Local verification:** `bash -n` clean; sourced under `PEON_ADAPTER_TEST=1`, `emit_event SessionStart/Stop` produce `trae-mysess`-prefixed CESP JSON; `trae.ps1` tokenizes clean, contains `FileSystemWatcher`, no `ExecutionPolicy Bypass`. BATS/Pester authored under tests card `lbuggs`.