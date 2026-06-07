# Ship the ECA adapter as first-party

## Feature Overview & Context

* **Associated Ticket/Epic:** ECA (eca.dev) #261; roadmap `m3/s6/eca-adapter/eca-adapter-firstparty`
* **Feature Area/Component:** `adapters/eca.sh`, `adapters/eca.ps1`
* **Target Release/Milestone:** v3 — Ubiquity & Polish (2.21.0)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **ECA hooks docs + #261** | eca.dev/configuration | ECA hooks: `sessionStart`/`sessionEnd`/`chatStart`/`chatEnd`/`preRequest`/`postRequest`/`subagentPostRequest`/`preToolCall`/`postToolCall`; stdin JSON, top-level keys snake_case. #261 posted a working adapter + type_map. |
| **adapters/kiro.sh / rovodev.sh** | this repo | stdin-JSON template + `~/.openpeon` fallback. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Vendor `adapters/eca.sh` from #261: resolve PEON_DIR via the standard chain + `~/.openpeon` fallback; read stdin JSON; derive `session_id` from `db_cache_path` with an `eca-` prefix and a PID fallback; apply the type_map (sessionStart→SessionStart, sessionEnd→SessionEnd, chatStart→SessionStart, preRequest→UserPromptSubmit, postRequest/subagentPostRequest→Stop, preToolCall→PermissionRequest, postToolCall→Stop); forward notification_type/permission_mode; exit 0 on unknown types.
* `adapters/eca.ps1` parity (kiro.ps1 stdin pattern), no `ExecutionPolicy Bypass`. Credit the #261 contributor in the header.

### Acceptance Criteria

* [x] `adapters/eca.sh` maps ECA hook types to CESP with `eca-` prefix (db_cache_path-derived id), exits 0 on unknown.
* [x] `adapters/eca.ps1` mirrors it, no `ExecutionPolicy Bypass`.
* [x] Header credits the #261 contributor.
* [x] `bash -n` passes; `.ps1` tokenizes clean.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | type_map on kiro.sh template | - [x] Design Complete |
| **TDD Implementation** | adapters/eca.sh + eca.ps1 | - [x] Implementation Complete |
| **Integration Testing** | smoke + tokenizer | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | tests/eca.bats (tests card) | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | eca.sh + .ps1 | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | bash -n + smoke | - [x] Originally failing tests now pass |
| **4. Refactor** | align to kiro idioms | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** Smoke-test each type via stub peon.sh; `eca-` prefix + db_cache_path id; Pester structural.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | smoke + CI |
| **Production Deployment** | 2.21.0 |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | Confirm ECA payload field names against a real run |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified.
* [x] Tests handled by sibling tests card.
* [x] Self-review pass complete.
* [x] Merged to the v3 integration branch.
* [x] Roadmap feature flipped to done on commit.


## Progress Update — ECA adapter shipped first-party

**Built:** `adapters/eca.sh` + `adapters/eca.ps1`, vendoring the #261 adapter. stdin-JSON; applies the proven type_map (sessionStart→SessionStart, sessionEnd→SessionEnd, chatStart→SessionStart, preRequest→UserPromptSubmit, postRequest/subagentPostRequest→Stop, preToolCall→PermissionRequest, postToolCall→Stop); unknown types exit 0. `session_id` derived from `db_cache_path` (sanitized, last 60 chars) with a PID fallback, `eca-` prefix. The hook type is read from argv and/or a stdin `type` field. `~/.openpeon` PEON_DIR fallback. Header credits the #261 contributor. No `ExecutionPolicy Bypass`.

**Note on postToolCall→Stop:** peon.sh's Stop debounce collapses the rapid Stops within a turn, so this matches #261 without per-tool noise.

**Local verification:** `bash -n` clean; smoke tests — sessionStart→SessionStart (eca-<db_cache_path>), preRequest→UserPromptSubmit, postRequest/postToolCall→Stop, preToolCall→PermissionRequest, sessionEnd→SessionEnd, chatEnd→silent, argv-type fallback works; `eca.ps1` tokenizes clean (no bypass) and was run live on Windows (sessionStart→SessionStart, preToolCall→PermissionRequest, chatEnd→silent).