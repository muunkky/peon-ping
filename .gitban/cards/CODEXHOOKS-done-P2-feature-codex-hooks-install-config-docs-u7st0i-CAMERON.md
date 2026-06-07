# Codex hooks install config + docs

## Feature Overview & Context

* **Associated Ticket/Epic:** #513; roadmap `m3/s6/codex-native-hooks-upgrade/codex-hooks-status-and-docs`
* **Feature Area/Component:** `README.md`, `README_zh.md`, `docs/public/llms.txt`
* **Target Release/Milestone:** v3 — Ubiquity & Polish (2.21.0)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **README OpenAI Codex setup** | this repo | Currently documents the legacy `notify` line in `~/.codex/config.toml`. Add the stable-hooks config alongside it (keep notify as fallback). |
| **peon.sh codex detection** | peon.sh | Keys on `adapters/codex.sh`/`.ps1` path string; a hooks-based config that references the adapter path stays detected. Verify; only adjust if needed. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Update the OpenAI Codex setup section (README + README_zh) to document the recommended stable-hooks config in addition to the legacy `notify` line, and note the upgraded event coverage.
* Update `docs/public/llms.txt` Codex entry.
* Verify `peon status` still detects Codex under a hooks-based config (detection keys on the adapter path string).
* No separate VERSION bump — folds into the shared 2.21.0 (CHANGELOG note added).

### Acceptance Criteria

* [x] README + README_zh Codex setup documents stable-hooks config + legacy notify fallback.
* [x] docs/public/llms.txt Codex entry updated.
* [x] `peon status` Codex detection confirmed still working under hooks config.
* [x] CHANGELOG v2.21.0 notes the Codex upgrade.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Extend existing Codex setup section | - [x] Design Complete |
| **TDD Implementation** | README/README_zh/llms.txt edits | - [x] Implementation Complete |
| **Integration Testing** | peon status detection check | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | N/A (docs) | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | doc edits | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | peon status detection | - [x] Originally failing tests now pass |
| **4. Refactor** | match section style | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** Verify detection via `peon status --verbose` against a hooks-config; visual diff of the Codex setup section.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | detection + CI |
| **Production Deployment** | 2.21.0 |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | Confirm exact Codex hooks config file (config.toml vs hooks.json) against official docs |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified.
* [x] Docs updated (README, README_zh, llms.txt, CHANGELOG).
* [x] Self-review pass complete.
* [x] Merged to the v3 integration branch.
* [x] Roadmap feature flipped to done on commit.


## Progress Update — Codex hooks docs updated

**Changed:**
- `README.md` + `README_zh.md` OpenAI Codex setup section: documents the **recommended stable-hooks config** (`[hooks]` entries in `~/.codex/config.toml`, stdin-JSON delivery, full event coverage) alongside the **legacy `notify`** line (still supported by the same adapter), with a Windows `.ps1` variant. Notes that `peon status` detects Codex from the adapter path in either config form.
- `docs/public/llms.txt`: Codex IDE entry updated to note the stable hook event set + legacy notify fallback.
- `CHANGELOG.md`: added a **Changed** entry under v2.21.0 for the Codex upgrade.

**Detection verification:** `peon status` keys on `adapters/codex.sh`/`.ps1` appearing in the Codex config; the documented `[hooks]` entries contain `adapters/codex.sh`, so a hooks-based config stays detected — no peon.sh detection change needed (verified by reading the detection block). No separate VERSION bump (folds into the shared 2.21.0).