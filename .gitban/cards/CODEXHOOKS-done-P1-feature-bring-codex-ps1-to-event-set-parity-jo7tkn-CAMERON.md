# Bring codex.ps1 to event-set parity

## Feature Overview & Context

* **Associated Ticket/Epic:** #513; roadmap `m3/s6/codex-native-hooks-upgrade/codex-hooks-windows-parity`
* **Feature Area/Component:** `adapters/codex.ps1`
* **Target Release/Milestone:** v3 — Ubiquity & Polish (2.21.0)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **adapters/codex.ps1 (current)** | this repo | Only switches on a single `$Event` param; NO stdin parsing; wrongly collapses error/fail* to Stop. |
| **adapters/kiro.ps1** | this repo | stdin `[Console]::OpenStandardInput` + `ConvertFrom-Json` pattern to mirror. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Rewrite `codex.ps1` to parse stdin JSON (kiro.ps1 pattern) and apply the same CESP mapping table as the upgraded codex.sh — including failure events → `PostToolUseFailure` (today it wrongly collapses error/fail* to Stop).
* Preserve the legacy-notify branch: argv `$Event` with no stdin still maps (agent-turn-complete→Stop, permission→Notification, error→failure).
* Keep `codex-` prefix; no `ExecutionPolicy Bypass`.

### Acceptance Criteria

* [x] `codex.ps1` parses stdin JSON and maps the stable events identically to codex.sh.
* [x] Failure events map to PostToolUseFailure (not Stop).
* [x] Legacy argv `$Event` fallback preserved; `codex-` prefix; no `ExecutionPolicy Bypass`.
* [x] Tokenizes clean.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | stdin parse + shared mapping table | - [x] Design Complete |
| **TDD Implementation** | adapters/codex.ps1 | - [x] Implementation Complete |
| **Integration Testing** | Pester + tokenizer | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | Pester codex cases (tests card) | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | codex.ps1 rewrite | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | tokenizer + Pester | - [x] Originally failing tests now pass |
| **4. Refactor** | mirror codex.sh table | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** Pester content/mapping assertions; tokenizer parse; failure→PostToolUseFailure asserted.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | Pester + CI |
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
* [x] Tests handled by sibling tests card.
* [x] Self-review pass complete.
* [x] Merged to the v3 integration branch.
* [x] Roadmap feature flipped to done on commit.


## Progress Update — codex.ps1 brought to parity

**Rewrote `adapters/codex.ps1`** to parse stdin JSON (kiro.ps1 `[Console]::OpenStandardInput` + `ConvertFrom-Json` pattern) and apply the same CESP mapping table as the upgraded codex.sh: SessionStart/UserPromptSubmit/Stop pass through; failed `PostToolUse`→`PostToolUseFailure` (fixes the old bug where error/fail* collapsed to Stop); `PreToolUse` + successful `PostToolUse` are silent (early `exit 0`, so peon.ps1 isn't invoked). Legacy argv `$Event` notify path preserved (agent-turn-complete→Stop, error→failure, permission→Notification). `codex-` prefix; **no `ExecutionPolicy Bypass`**.

**Local verification (actually run on Windows via pwsh, stub peon.ps1):** tokenizes clean; stdin SessionStart→SessionStart, Stop→Stop, PostToolUse failure→PostToolUseFailure(tool_name+error), PostToolUse success→silent, PreToolUse→silent; legacy argv error→PostToolUseFailure, agent-turn-complete→Stop. Pester cases added under the tests card.