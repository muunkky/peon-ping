# Map stable Codex hook event set in codex.sh

## Feature Overview & Context

* **Associated Ticket/Epic:** OpenAI Codex hooks (#513); roadmap `m3/s6/codex-native-hooks-upgrade/codex-hooks-event-mapping`
* **Feature Area/Component:** `adapters/codex.sh`
* **Target Release/Milestone:** v3 — Ubiquity & Polish (2.21.0)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **Codex hooks guide** | codex.danielvaughan.com hooks guide | Stable hook events: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop` — delivered as **stdin JSON** with `hook_event_name`; permission handled via PreToolUse. |
| **adapters/codex.sh (current)** | this repo | Already reads argv `$1` AND stdin JSON; event_key-normalizes and collapses most events to Stop. The legacy `notify` callback fires turn-yield only. Need to extend the mapping, not rewrite I/O. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Extend the python mapping so a PascalCase `hook_event_name` from stdin JSON maps correctly: `SessionStart`→SessionStart, `UserPromptSubmit`→UserPromptSubmit, `Stop`→Stop, `PostToolUse`→`PostToolUseFailure` only on failure (else silent), `PreToolUse`→drop (too noisy; fires every tool).
* Keep the **legacy notify argv path** intact: `agent-turn-complete`/`complete`/`done`→Stop, `error`/`fail*`→PostToolUseFailure, `permission*`/`approve*`→Notification permission_prompt. Unknown → Stop (back-compat).
* Restructure to capture python output and only pipe to peon.sh when non-empty (so dropped events don't invoke peon.sh), matching kiro.sh/qwen.sh.
* Keep `codex-` session prefix and existing field extraction (cwd, tool_name, error, summary).

### Acceptance Criteria

* [x] stdin `hook_event_name` SessionStart/UserPromptSubmit/Stop map correctly; PreToolUse + successful PostToolUse are silent; failed PostToolUse → PostToolUseFailure.
* [x] Legacy argv notify path unchanged (agent-turn-complete→Stop, error→failure, permission→Notification).
* [x] `bash -n adapters/codex.sh` passes; smoke tests confirm mapping.
* [x] `codex-` prefix preserved.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Extend event_key mapping + conditional pipe | - [x] Design Complete |
| **TDD Implementation** | adapters/codex.sh | - [x] Implementation Complete |
| **Integration Testing** | smoke tests + CI BATS | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | tests/codex.bats extended (tests card) | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | codex.sh mapping | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | bash -n + smoke + CI | - [x] Originally failing tests now pass |
| **4. Refactor** | keep notify path intact | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** Smoke-test each stable event + legacy regression locally via a stub peon.sh; authoritative BATS on CI.

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
| **Further Investigation?** | Confirm Codex PostToolUse failure payload shape against a real run |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified.
* [x] Tests handled by sibling tests card.
* [x] Self-review pass complete.
* [x] Merged to the v3 integration branch.
* [x] Roadmap feature flipped to done on commit.


## Progress Update — codex.sh mapping upgraded

**Changed `adapters/codex.sh`:** extended the python mapping to handle the stable Codex hook event set from stdin JSON `hook_event_name` (PascalCase) while preserving the legacy `notify` argv path. Now: `SessionStart`→SessionStart, `UserPromptSubmit`→UserPromptSubmit, `Stop`→Stop, `PostToolUse`→`PostToolUseFailure` only when the tool failed (else silent), `PreToolUse`→silent (fires every tool). Legacy notify preserved: `agent-turn-complete`/`complete`/`done`→Stop, `error`/`fail*`→PostToolUseFailure, `permission*`/`approve*`→Notification permission_prompt; unknown→Stop. Restructured to capture python output and only pipe to peon.sh when non-empty (so dropped events don't invoke it). `codex-` prefix + field extraction kept.

**Local verification (`bash -n` clean + 10 smoke cases):** legacy argv agent-turn-complete→Stop, error→PostToolUseFailure(tool_name+error), permission-required→Notification permission_prompt; stdin SessionStart→SessionStart, UserPromptSubmit→UserPromptSubmit, Stop→Stop(+transcript_summary), PostToolUse failure→PostToolUseFailure, PostToolUse success→silent, PreToolUse→silent, stdin session_id→codex-sess-42. All existing codex.bats behaviors preserved.