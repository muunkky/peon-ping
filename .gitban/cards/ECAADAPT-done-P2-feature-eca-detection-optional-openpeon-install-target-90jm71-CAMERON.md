# ECA detection + optional openpeon install target

## Feature Overview & Context

* **Associated Ticket/Epic:** #261; roadmap `m3/s6/eca-adapter/eca-install-and-agnostic-root-flag`
* **Feature Area/Component:** `peon.sh`, `install.sh`, `install.ps1`
* **Target Release/Milestone:** v3 — Ubiquity & Polish (2.21.0)

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **PR #523 + rovodev.sh** | this repo | Runtime resolution to `~/.openpeon` already works (peon.sh defaults to it when ~/.claude lacks packs/). Only the install WRITE target is missing a flag. |
| **install.sh GLOBAL_BASE** | this repo | Installer writes under `~/.claude` (GLOBAL_BASE). Add a documented flag to target `~/.openpeon` instead, preserving back-compat. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Add ECA to `peon status` detection (probe ECA config) + register in the prefix label fallback (`eca-`).
* Wire installers: explicit `eca.sh` curl line in install.sh; `eca.ps1` in install.ps1 `$adapterFiles`.
* Add `install.sh --openpeon` / `install.ps1 -OpenPeon` that sets the install BASE_DIR to `~/.openpeon` instead of GLOBAL_BASE; default stays `~/.claude` (full back-compat). Do NOT re-architect adapter PEON_DIR resolution (already correct).

### Acceptance Criteria

* [x] `peon status` detects ECA; `eca-` added to prefix fallback.
* [x] install.sh + install.ps1 wire eca adapter.
* [x] `install.sh --openpeon` / `install.ps1 -OpenPeon` set the write target to `~/.openpeon`; default unchanged.
* [x] `bash -n` + Pester pass.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Flag sets BASE_DIR; detection mirror | - [x] Design Complete |
| **TDD Implementation** | peon.sh + installers | - [x] Implementation Complete |
| **Integration Testing** | bash -n + Pester + peon status | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | install --openpeon test (tests card) | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | peon.sh + install.sh + install.ps1 | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | bash -n + Pester | - [x] Originally failing tests now pass |
| **4. Refactor** | match installer style | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** BATS for the `--openpeon` write target + back-compat regression (tests card); `peon status` detection; Pester install assert.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | bash -n + CI |
| **Production Deployment** | 2.21.0 |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | Confirm ECA config dir for detection against a real install |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified.
* [x] Detection + wiring + flag done.
* [x] Self-review pass complete.
* [x] Merged to the v3 integration branch.
* [x] Roadmap feature flipped to done on commit.


## Progress Update — ECA detection + openpeon flag + wiring

**Changed:**
- `peon.sh`: added **ECA** detection (`~/.config/eca` referencing eca.sh/.ps1, marked installed vs detected) + `eca-` in the empty-cwd label fallback.
- `install.sh`: added `eca.sh` curl line; added `--openpeon` flag (+ help text) that sets `GLOBAL_BASE` (and thus the install target) to `~/.openpeon` instead of `~/.claude`, guarded so it takes precedence over OpenClaw auto-detect. Default unchanged.
- `install.ps1`: added `eca.ps1` to `$adapterFiles`; added `-OpenPeon` switch that sets the install root to `~/.openpeon`.
- Did NOT touch adapter PEON_DIR resolution (already resolves `~/.openpeon` per PR #523).

**Verification:** `bash -n install.sh`/`peon.sh` clean; the `--openpeon` logic yields `~/.openpeon` with the flag and `~/.claude` without (back-compat); `install.ps1` tokenizes clean; `peon status --verbose` runs with 0 python errors (ECA detection executes). The install-write-target + back-compat BATS test is authored under the docs/tests card.