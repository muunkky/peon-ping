# BATS + Pester coverage for Kiro IDE adapter

## Feature Overview & Context

* **Associated Ticket/Epic:** #509; roadmap `m3/s6/kiro-ide-adapter/kiro-ide-tests`
* **Feature Area/Component:** `tests/kiro-ide.bats`, `tests/adapters-windows.Tests.ps1`
* **Target Release/Milestone:** v3 — Ubiquity & Polish (2.21.0)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **tests/windsurf.bats / tests/kiro.bats** | this repo | argv-event BATS structure (`run_<adapter> <event>`); model kiro-ide.bats on it, kept separate from kiro.bats. |
| **tests/adapters-windows.Tests.ps1** | this repo | Add kiro-ide.ps1 to syntax + no-Bypass lists; add a Category A block. |

## Design & Planning

### Initial Design Thoughts & Requirements

* `tests/kiro-ide.bats` (windsurf.bats structure): agentStop→Done, promptSubmit→silent, preToolUse→permission flow, `kiro-ide-` prefix assertion, unknown→graceful exit, paused/enabled/volume.
* Extend `tests/adapters-windows.Tests.ps1`: add `kiro-ide` to the syntax + no-ExecutionPolicy-Bypass `-ForEach` lists; add a Category A "Kiro IDE Adapter" block (argv mapping, `kiro-ide-` prefix, pipes to peon.ps1).

### Acceptance Criteria

* [x] tests/kiro-ide.bats added (windsurf.bats structure), kept separate from kiro.bats.
* [x] Pester extended for kiro-ide.ps1 (syntax + no-Bypass + mapping).
* [x] `bats --count` parses; Pester stays green locally.
* [x] `kiro-ide-` prefix asserted.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Mirror windsurf/kiro tests | - [x] Design Complete |
| **TDD Implementation** | kiro-ide.bats + Pester | - [x] Implementation Complete |
| **Integration Testing** | local Pester + CI BATS | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | kiro-ide.bats + Pester additions | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | (adapter already exists) | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | Pester local + CI BATS | - [x] Originally failing tests now pass |
| **4. Refactor** | match existing test idioms | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** BATS authoritative on CI macos-latest; Pester local + CI windows-latest.

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


## Progress Update — Kiro IDE test coverage added

**Built:** `tests/kiro-ide.bats` (13 tests, modeled on rovodev.bats/windsurf.bats — kept separate from tests/kiro.bats): agentStop→Done, sessionStart→Hello, preToolUse→input.required (Perm), promptSubmit→silent, default(no arg)→agentStop, postToolUse/fileEdited/unknown→graceful exit, paused/enabled/volume, and a direct `kiro-ide-` session-prefix assertion via `.state.json`. Extended `tests/adapters-windows.Tests.ps1`: `kiro-ide` added to the syntax + no-ExecutionPolicy-Bypass lists, plus a Category A "Kiro IDE Adapter" block (argv mapping, `kiro-ide-` prefix, pipes to peon.ps1).

**Verification:** `bats --count tests/kiro-ide.bats` = 13 (parses); **Pester full suite: 438 passed / 0 failed** locally. BATS authoritative on CI macos-latest.