# ECA docs + tests (adapter and install root)

## Feature Overview & Context

* **Associated Ticket/Epic:** #261; roadmap `m3/s6/eca-adapter/eca-docs-tests`
* **Feature Area/Component:** `README.md`, `README_zh.md`, `docs/public/llms.txt`, `tests/eca.bats`, `tests/adapters-windows.Tests.ps1`, install BATS
* **Target Release/Milestone:** v3 — Ubiquity & Polish (2.21.0)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **README Multi-IDE table** | this repo | Add an ECA row + setup section (ECA hooks JSON from #261); badge/intro; document the optional `~/.openpeon` install target. |
| **tests/windsurf.bats / install.bats** | this repo | Test templates for the adapter + the install --openpeon write target. |

## Design & Planning

### Initial Design Thoughts & Requirements

* README + README_zh: add ECA to the Multi-IDE table + a setup section (ECA hooks config), badge/intro; document the optional `~/.openpeon` install target and how any tool references the shared runtime. llms.txt + openpeon llms.txt (if present); CHANGELOG note.
* `tests/eca.bats` (windsurf.bats structure): each ECA type → expected CESP sound; `eca-` prefix; db_cache_path-derived session id; paused/enabled/volume; graceful unknown-type exit. Pester ECA cases.
* BATS test for `install --openpeon` (runtime lands under `~/.openpeon` and is resolved when ~/.claude lacks packs/), plus a regression that the existing ~/.claude path still wins when present.

### Acceptance Criteria

* [x] README + README_zh ECA row + setup section + openpeon-target docs; badge/intro; llms.txt + CHANGELOG.
* [x] tests/eca.bats added; Pester ECA cases added; both green locally where runnable.
* [x] install --openpeon BATS test + back-compat regression.
* [x] count-consistency + bats parse + Pester pass.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Mirror existing rows/tests | - [x] Design Complete |
| **TDD Implementation** | docs + eca.bats + Pester + install test | - [x] Implementation Complete |
| **Integration Testing** | local Pester + CI BATS | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | eca.bats + install --openpeon + Pester | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | docs (adapter already exists) | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | Pester local + CI BATS | - [x] Originally failing tests now pass |
| **4. Refactor** | match existing idioms | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** BATS authoritative on CI macos-latest; Pester local + CI windows-latest; count-consistency grep.

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
| **Further Investigation?** | openpeon site llms.txt is out-of-repo (follow-up) |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified.
* [x] Docs + tests done; Pester local green + BATS CI-gated.
* [x] Self-review pass complete.
* [x] Merged to the v3 integration branch.
* [x] Roadmap feature flipped to done on commit.


## Progress Update — ECA docs + tests done

**Changed:**
- `README.md` + `README_zh.md`: ECA Multi-IDE row + setup section (ECA hooks JSON from #261) + the **tool-agnostic `~/.openpeon` install-root** docs (`install.sh --openpeon` / `install.ps1 -OpenPeon`); badge + intro.
- `docs/public/llms.txt`: ECA entry + headline + openpeon note; `CHANGELOG.md`: ECA + `--openpeon` bullet under v2.21.0.
- `tests/eca.bats` (11 tests, windsurf/qwen structure): each ECA type → expected CESP sound (sessionStart→Hello, postRequest→Done, preToolCall→Perm, preRequest→silent, chatEnd/malformed→silent), `eca-` prefix from db_cache_path, paused/enabled/volume.
- `tests/adapters-windows.Tests.ps1`: `eca` added to syntax + no-Bypass lists + a Category A ECA block.
- `tests/install.bats`: a `--openpeon` write-target test (runtime lands under `~/.openpeon`, not `~/.claude`) + a back-compat regression (default still lands in `~/.claude`, and `~/.openpeon` is NOT created without the flag).

**Verification:** `bats --count` — eca.bats 11, install.bats 48 (incl. the 2 new openpeon tests); ECA count-consistent across both READMEs (4 each) + llms.txt; **Pester full suite: 444 passed / 0 failed** locally. BATS authoritative on CI macos-latest. (openpeon site llms.txt is out-of-repo — follow-up.)