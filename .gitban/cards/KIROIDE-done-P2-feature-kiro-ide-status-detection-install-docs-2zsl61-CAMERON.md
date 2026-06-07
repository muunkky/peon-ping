# Kiro IDE status detection, install, docs

## Feature Overview & Context

* **Associated Ticket/Epic:** #509; roadmap `m3/s6/kiro-ide-adapter/kiro-ide-status-install-docs`
* **Feature Area/Component:** `peon.sh`, `install.sh`, `install.ps1`, `README.md`, `README_zh.md`, `docs/public/llms.txt`
* **Target Release/Milestone:** v3 — Ubiquity & Polish (2.21.0)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **README Kiro row + setup** | this repo | Single "Kiro" row today; split into "Kiro CLI" and "Kiro IDE" with separate setup sections. |
| **peon.sh detection + prefix fallback** | this repo | Add Kiro IDE detection (`.kiro/hooks/*.kiro.hook`) distinct from CLI's `~/.kiro/agents`; add `kiro-ide-` to the prefix label fallback. |

## Design & Planning

### Initial Design Thoughts & Requirements

* `peon.sh`: add Kiro IDE detection (probe `.kiro/hooks` for a peon-ping `.kiro.hook`, or `~/.kiro` IDE config) distinct from the CLI's `~/.kiro/agents`; add `kiro-ide-` to the empty-cwd prefix label fallback.
* `install.sh`: add explicit curl line for `kiro-ide.sh`; `install.ps1`: add `kiro-ide.ps1` to `$adapterFiles`.
* README + README_zh: split the Kiro row into "Kiro CLI" + "Kiro IDE"; add a dedicated Kiro IDE setup section (`.kiro/hooks/*.kiro.hook` examples) beside the CLI one; update badge/intro; update llms.txt. CHANGELOG note under 2.21.0.

### Acceptance Criteria

* [x] `peon status` distinguishes Kiro CLI from Kiro IDE.
* [x] install.sh + install.ps1 wire kiro-ide adapter.
* [x] README + README_zh split Kiro CLI/IDE rows + setup sections; badge/intro updated; llms.txt + CHANGELOG updated.
* [x] `bash -n` + Pester + count-consistency pass.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Mirror existing detection/wiring | - [x] Design Complete |
| **TDD Implementation** | peon.sh + installers + docs | - [x] Implementation Complete |
| **Integration Testing** | peon status + bash -n + Pester | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | detection/wiring asserts (tests card) | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | peon.sh + installers + docs | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | peon status + Pester | - [x] Originally failing tests now pass |
| **4. Refactor** | match existing style | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** `peon status --verbose` distinguishes CLI vs IDE; count-consistency grep; Pester install assert.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | peon status + CI |
| **Production Deployment** | 2.21.0 |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | Confirm Kiro IDE config dir location against a real install |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified.
* [x] Docs + detection + wiring done.
* [x] Self-review pass complete.
* [x] Merged to the v3 integration branch.
* [x] Roadmap feature flipped to done on commit.


## Progress Update — Kiro IDE detection + wiring + docs

**Changed:**
- `peon.sh`: added **Kiro CLI** detection (`~/.kiro/agents/*.json` referencing kiro.sh/.ps1) AND **Kiro IDE** detection (project `.kiro/hooks/*.kiro.hook` referencing kiro-ide.sh/.ps1) — neither existed before, so `peon status` now distinguishes the two. Added `kiro-ide-`/`kiro-` to the empty-cwd label fallback (kiro-ide- ordered first).
- `install.sh`: added `kiro-ide.sh` curl line; `install.ps1`: added `kiro-ide.ps1` to `$adapterFiles`.
- `README.md` + `README_zh.md`: split the single "Kiro" Multi-IDE row into **Kiro CLI** + **Kiro IDE** rows; renamed the setup section to "Kiro CLI setup" and added a dedicated "Kiro IDE setup" section (`.kiro/hooks/*.kiro.hook` example); split the badge + intro entries.
- `docs/public/llms.txt`: split Kiro into CLI/IDE + headline; `CHANGELOG.md`: added the Kiro IDE bullet under v2.21.0.

**Verification:** `bash -n peon.sh`/`install.sh` clean; `install.ps1` tokenizes clean; `peon status --verbose` runs `rc=0` (IDEs block renders; the new detection Python executes with no error).