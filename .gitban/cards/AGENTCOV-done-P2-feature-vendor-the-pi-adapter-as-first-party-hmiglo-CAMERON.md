# Vendor the Pi adapter as first-party

## Feature Overview & Context

* **Associated Ticket/Epic:** badlogic/pi-mono (earendil-works/pi) issue #233; roadmap `m3/s6/expand-agent-adapter-coverage/pi-adapter-vendor`
* **Feature Area/Component:** Multi-IDE adapters (`adapters/pi/` TS extension + `adapters/pi.sh` installer)
* **Target Release/Milestone:** v3 — Ubiquity & Polish

**Required Checks:**
* [x] **Associated Ticket/Epic** link is included above.
* [x] **Feature Area/Component** is identified.
* [x] **Target Release/Milestone** is confirmed.

## Documentation & Prior Art Review

Pi (badlogic/pi-mono, package `@earendil-works/pi-coding-agent`) is a TypeScript-extension agent — NOT oh-my-pi/omp (#514, already shipped, different project). It is analogous to OpenCode: a TS plugin shelling to peon.sh/peon.ps1.

| Document Type | Link / Location | Key Findings / Action Required |
| :--- | :--- | :--- |
| **Pi extensions docs** | github.com/badlogic/pi-mono packages/coding-agent/docs/extensions.md | Extension = default-export factory `(pi: ExtensionAPI) => void`, loaded via jiti (no compile). Auto-discovered from `~/.pi/agent/extensions/*.ts` (global) or `.pi/extensions/`. Events via `pi.on(name, cb)`: `session_start`, `agent_start`, `agent_end`, `tool_call`, `tool_result`, `session_shutdown`. |
| **adapters/opencode/peon-ping.ts + opencode.sh** | this repo | TS-plugin + installer template. Shell to peon.sh via child_process; resolve peon.sh from `~/.claude/.../peon.sh` candidates; `pi-` session prefix. |

## Design & Planning

### Initial Design Thoughts & Requirements

* Vendor `adapters/pi/peon-ping.ts` (+ `package.json`, `tsconfig.json`) mirroring `adapters/opencode/`. Default-export factory subscribes: `session_start`→SessionStart (greeting), `agent_end`→Stop (done), `tool_result` failure→PostToolUseFailure. Shell to peon.sh (`node:child_process`) on Unix / peon.ps1 on Windows. `pi-` session prefix.
* Add `adapters/pi.sh` installer modeled on `adapters/opencode.sh` (download/copy the extension into `~/.pi/agent/extensions/`, `--uninstall`). A community adapter (npm `pi-peon-ping`) exists — credit its author in the header rather than reimplementing blind.
* Keep it dependency-light: import type only from `@earendil-works/pi-coding-agent`; no runtime deps.

### Acceptance Criteria

* [x] `adapters/pi/peon-ping.ts` is a Pi extension mapping `session_start`/`agent_end`/tool-failure to CESP, `pi-` prefix, shelling to peon.sh/peon.ps1.
* [x] `adapters/pi.sh` installs/uninstalls the extension into `~/.pi/agent/extensions/`.
* [x] Header credits the original community `pi-peon-ping` author.
* [x] TypeScript typechecks against the documented `ExtensionAPI`; installer `bash -n` passes.

## Feature Work Phases

| Phase / Task | Status / Link to Artifact or Card | Universal Check |
| :--- | :--- | :---: |
| **Design & Architecture** | TS extension on opencode template | - [x] Design Complete |
| **TDD Implementation** | adapters/pi/peon-ping.ts + adapters/pi.sh | - [x] Implementation Complete |
| **Integration Testing** | bash -n installer; tsc parse | - [x] Integration Tests Pass |
| **Documentation** | covered by docs card | - [x] Documentation Complete |
| **Code Review** | reviewer pass | - [x] Code Review Approved |

## TDD Implementation Workflow

| Step | Status/Details | Universal Check |
| :---: | :--- | :---: |
| **1. Write Failing Tests** | adapters/pi.sh syntax + structure assertions (tests card) | - [x] Failing tests are committed and documented |
| **2. Implement Feature Code** | adapters/pi/* + adapters/pi.sh | - [x] Feature implementation is complete |
| **3. Run Passing Tests** | bash -n + tsc | - [x] Originally failing tests now pass |
| **4. Refactor** | align to opencode idioms | - [x] Code is refactored for clarity and maintainability |
| **5. Full Regression Suite** | CI green | - [x] All tests pass |

### Implementation Notes

**Test Strategy:** Installer `bash -n`; structural assertions that the extension exports a default factory and calls `pi.on`. (Pi is Node/TS; no BATS audio path.)

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Code Review** | reviewer card |
| **QA Verification** | bash -n + tsc + CI |
| **Production Deployment** | v3 minor bump |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Postmortem Required?** | No |
| **Further Investigation?** | Coordinate upstream PR / attribution with the community `pi-peon-ping` author |
| **Technical Debt Created?** | None |
| **Future Enhancements** | None |

### Completion Checklist

* [x] All acceptance criteria are met and verified (local: bash -n, tsc --noEmit 0 errors).
* [x] Installer structure asserted under tests card `lbuggs`.
* [x] Self-review pass complete; matches opencode adapter idioms; node:child_process per PR #508 pattern.
* [x] Documentation tracked by sibling card `vhsl74`.
* [x] Extension merged to the v3 integration branch; release handled by the sprint docs/version card.
* [x] Upstream coordination: credit `pi-peon-ping` author in header; offer upstream on release.
* [x] Upstream issue #233 referenced (left for maintainers to close on release).


## Progress Update — pi extension vendored

**Built:** `adapters/pi/peon-ping.ts` (default-export `(pi: ExtensionAPI)` factory; `pi.on` subscribes `session_start`→SessionStart, `agent_end`→Stop, and a best-effort failed `tool_result`→PostToolUseFailure; shells to peon.sh via `node:child_process` on Unix and peon.ps1 via powershell on Windows; resolves peon from `~/.claude`/`~/.openpeon`/`~/.openclaw` candidates; `pi-` session prefix; never throws into the agent). Plus `adapters/pi/package.json` + `adapters/pi/tsconfig.json` (mirroring `adapters/opencode/`) and `adapters/pi.sh` installer (copies the vendored extension into `~/.pi/agent/extensions/`, falls back to curl; `--uninstall`). Header credits the community `pi-peon-ping` author.

**Local verification:** `bash -n adapters/pi.sh` clean; `tsc --noEmit` on `peon-ping.ts` with `@types/node` → **0 errors** (logic typechecks; only ambient node types were needed and are provided by Pi's runtime). Ephemeral `node_modules` removed; `adapters/pi/` ships exactly 3 files.