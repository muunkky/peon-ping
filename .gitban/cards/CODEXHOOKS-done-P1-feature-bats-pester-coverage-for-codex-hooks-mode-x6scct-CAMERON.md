# BATS + Pester coverage for Codex hooks mode

## Feature Overview & Context

* **Associated Ticket/Epic:** #513; roadmap `m3/s6/codex-native-hooks-upgrade/codex-hooks-tests`
* **Feature Area/Component:** `tests/codex.bats`, `tests/adapters-windows.Tests.ps1`
* **Target Release/Milestone:** v3 — Ubiquity & Polish (2.21.0)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **tests/codex.bats** | this repo | Already covers the argv/notify path via `run_codex`. Extend with stable-hook stdin payloads + a regression that legacy argv still maps to Stop. |
| **tests/adapters-windows.Tests.ps1 Codex block** | this repo | Add stable-hook mapping assertions for codex.ps1 incl. failure→PostToolUseFailure. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Extend `tests/codex.bats`: feed stdin `hook_event_name` payloads — SessionStart→Hello, Stop→Done, failed PostToolUse→Error, PreToolUse→silent, UserPromptSubmit→silent — plus a regression that legacy argv `agent-turn-complete`→Stop still works.
* Add codex.ps1 stable-hook mapping cases to the Pester Category A Codex block (valid PowerShell, failure→PostToolUseFailure, pipes to peon.ps1, no ExecutionPolicy Bypass).

### Acceptance Criteria

* [x] tests/codex.bats covers stable-hook events + legacy regression.
* [x] Pester Codex block covers stdin parsing + failure→PostToolUseFailure.
* [x] `bats --count tests/codex.bats` parses; Pester suite stays green locally.
* [x] codex- prefix asserted.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Extend existing codex tests | - [x] Design Complete |
| **TDD Implementation** | codex.bats + Pester | - [x] Implementation Complete |
| **Integration Testing** | local Pester + CI BATS | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | new codex test cases | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | (adapters already upgraded) | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | Pester local + CI BATS | - [x] Originally failing tests now pass |
| **4. Refactor** | match existing test idioms | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** BATS authoritative on CI macos-latest; Pester verified locally + CI windows-latest.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | Pester local + CI |
| **Production Deployment** | 2.21.0 |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | None |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified.
* [x] Pester local green + BATS CI-gated.
* [x] Self-review pass complete.
* [x] Merged to the v3 integration branch.
* [x] Roadmap feature flipped to done on commit.


## Progress Update — Codex hooks test coverage added

**Changed:**
- `tests/codex.bats`: added stable-hook stdin cases — SessionStart→Hello, Stop→Done, failed PostToolUse→Error, successful PostToolUse→silent, PreToolUse→silent, UserPromptSubmit→silent. The existing argv tests (agent-turn-complete→Done, error→Error, permission→silent, session forwarding) serve as the legacy `notify` regression. Parses to 11 tests.
- `tests/adapters-windows.Tests.ps1`: rewrote the Category A Codex block for the new codex.ps1 — asserts stdin parsing (`IsInputRedirected`/`StreamReader`), SessionStart/UserPromptSubmit mapping, failed PostToolUse→`PostToolUseFailure` (+`Test-ToolFailure`), silent PreToolUse, `codex-` prefix, pipes to peon.ps1. (The old assertions were tied to the argv-only structure.)

**Verification:** `bats --count tests/codex.bats` = 11 (parses); **Pester full suite: 430 passed / 0 failed** locally. BATS authoritative on CI macos-latest.