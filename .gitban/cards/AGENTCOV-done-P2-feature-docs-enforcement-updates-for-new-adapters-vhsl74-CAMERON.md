# Docs + enforcement updates for new adapters

## Feature Overview & Context

* **Associated Ticket/Epic:** roadmap `m3/s6/expand-agent-adapter-coverage/new-adapters-docs-enforcement` (depends on install-wiring + tests)
* **Feature Area/Component:** `README.md`, `README_zh.md`, `docs/public/llms.txt`, `../openpeon/site/public/llms.txt`, `VERSION`, `CHANGELOG.md`
* **Target Release/Milestone:** v3 — Ubiquity & Polish

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

Per CLAUDE.md Change Enforcement Rules for a new IDE adapter.

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **CLAUDE.md enforcement rules** | this repo | New adapter ⇒ README Multi-IDE row + setup section, README_zh parity, docs/public/llms.txt, badge/intro count consistency, VERSION minor + CHANGELOG. |
| **README.md Multi-IDE section** | this repo | Existing OpenAI Codex / Rovo Dev rows + setup sections are the row/section template (incl. exact config snippet). |

## Design & Planning

### Initial Design Thoughts & Requirements

* Add Qwen Code, iFlow CLI, Trae, Pi as Multi-IDE table rows + per-agent setup sections (exact config snippet each), keeping the supported-count consistent across badge, intro, and table.
* Apply identical changes to `README_zh.md`.
* Update `docs/public/llms.txt` (supported-agents list + headline) and `../openpeon/site/public/llms.txt` if it lives in the workspace.
* Add homebrew formula detection/setup phases only for agents needing auto-registration (none of these require it; note N/A).
* Bump `VERSION` (minor) and add a `CHANGELOG.md` section once all four adapters land.

### Acceptance Criteria

* [x] README.md has Qwen/iFlow/Trae/Pi rows + setup sections; badge/intro/table counts consistent.
* [x] README_zh.md mirrors the changes.
* [x] docs/public/llms.txt updated (and openpeon llms.txt if present in workspace, else noted N/A).
* [x] VERSION bumped (minor) + CHANGELOG.md section added.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | Mirror Codex/Rovo Dev rows | - [x] Design Complete |
| **TDD Implementation** | README/README_zh/llms.txt/VERSION/CHANGELOG edits | - [x] Implementation Complete |
| **Integration Testing** | grep count-consistency check | - [x] Integration Tests Pass |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | N/A (docs); count-consistency grep is the check | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | doc edits | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | grep badge/intro/table counts equal | - [x] Originally failing tests now pass |
| **4. Refactor** | match existing row/section style | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** Manual count-consistency verification across badge/intro/Multi-IDE table in both READMEs; visual diff of the new setup sections against the Codex/Rovo Dev exemplars.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | count-consistency grep + CI |
| **Production Deployment** | v3 minor bump + CHANGELOG |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | Confirm `../openpeon` workspace presence; if absent, note its llms.txt as out-of-repo follow-up |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified (count-consistency grep across both READMEs + llms.txt).
* [x] Count consistency verified (badge/intro/table/setup all carry the 4 agents).
* [x] Self-review pass complete; mirrors the Codex/Rovo Dev row + setup-section exemplars.
* [x] Documentation updated: README.md, README_zh.md, docs/public/llms.txt, CHANGELOG.md.
* [x] VERSION bumped to 2.21.0; release handled at story closeout (tag + homebrew).
* [x] openpeon llms.txt is out-of-repo (follow-up); upstream issues referenced for maintainers.


## Progress Update — docs + version bump done

**Changed:**
- `README.md`: added Multi-IDE table rows + per-agent setup sections (Qwen Code, iFlow CLI, Trae, Pi) with exact config snippets; updated the Windows watcher note (added Trae) + Pi note; added 4 badges + 4 intro-prose entries.
- `README_zh.md`: mirrored all of the above in Chinese (table rows, Windows note, 4 setup sections, badges, intro).
- `docs/public/llms.txt`: added the 4 agents to the IDE list + headline; updated the FileSystemWatcher note (added Trae) and Pi cross-platform note.
- `VERSION` → **2.21.0** (single minor bump shared by the whole v3 m3/s6 sprint).
- `CHANGELOG.md`: new **v2.21.0** section documenting the four adapters + detection/installer wiring + tests.

**Verification:** count-consistency grep confirms all four agents present in badge line (in order), intro prose, Multi-IDE table, and setup sections of both READMEs; llms.txt updated. `../openpeon/site/public/llms.txt` is **not in this checkout** — logged as an out-of-repo follow-up. Homebrew formula needs no detection phase for these (none require auto-registration).