
# Documentation Maintenance & Review

## Documentation Scope & Context

* **Related Work:** Reviewer follow-up from TTSNATIVE step 1 (card `h027ru`, review cycle 1). Inbox: `.gitban/agents/planner/inbox/TTSNATIVE-h027ru-planner-1.md`.
* **Documentation Type:** Agent SKILL.md process docs — guidance updates for how executor / reviewer / router / planner agents emit profiling logs.
* **Target Audience:** Claude agents (executor, reviewer, router, planner) and the dispatcher that reads their JSONL summaries for cost tracking.

**Required Checks:**
* [ ] Related work/context is identified above
* [ ] Documentation type and audience are clear
* [ ] Existing documentation locations are known (avoid creating duplicates)

## Problem Statement

Reviewer flagged a profiling signal gap during the h027ru review: the executor cycle reported `total_commands: 0` / `total_duration_s: 1` in `.gitban/agents/executor/logs/TTSNATIVE-h027ru-executor-1.jsonl` despite the cycle performing multiple material MCP calls (`read_card`, `toggle_checkboxes`, `append_card`, `take_sprint`, etc.). The dispatcher relies on these JSONL summaries for cost tracking; when `total_commands` is effectively zero the signal is useless and per-operation cost attribution degrades.

Root cause is documentation: the profiling section of each agent SKILL.md tells agents to `source .gitban/hooks/agent-log.sh` and call `agent_log_init` / `agent_log_event` / `agent_log_summary`, but none of them currently instruct agents to wrap material MCP operations with `agent_log_command` (or the equivalent timing helper in `agent-log.sh`). This is not a runtime bug — the hook exposes the helper, but the skills do not teach it.

Scope is general agent tooling and **not TTS-specific**; it does not belong in the TTSNATIVE follow-up tracker. It is sized at the SKILL.md level (multi-file documentation change across four agent roles) so it earns its own standalone card.

## Required Reading

* `.gitban/hooks/agent-log.sh` — read to confirm the exact helper signature (`agent_log_command`) and what it records (command name, duration, exit status, optional metadata).
* `.claude/skills/executor/SKILL.md` — current profiling section (executor-specific phrasing).
* `.claude/skills/reviewer/SKILL.md` — current profiling section.
* `.claude/skills/router/SKILL.md` — current profiling section.
* `.claude/skills/planner/SKILL.md` — current profiling section (see lines around "## Profiling" for the canonical block to update).
* Evidence log to eyeball before writing: `.gitban/agents/executor/logs/TTSNATIVE-h027ru-executor-1.jsonl` (shows the `total_commands: 0` degradation).

## Pre-Work Documentation Audit

Before editing, grep all four SKILL.md files to confirm no existing `agent_log_command` guidance is present, and check whether other skills (`dispatcher`, `sprintmaster`, `sprint-architect`, `sprint-reviewer`) reference profiling — if they do, add matching guidance to stay consistent.

* [ ] Repository root reviewed for doc cruft (stray .md files, outdated READMEs)
* [ ] `/docs` directory (or equivalent) reviewed for existing coverage
* [ ] Related service/component documentation reviewed
* [ ] Team wiki or internal docs reviewed

| Document Location | Current State | Action Required |
| :--- | :--- | :--- |
| **.claude/skills/executor/SKILL.md** | Has Profiling section with `agent_log_init` + `agent_log_event` + `agent_log_summary`. Missing `agent_log_command` guidance for material MCP ops. | Add an explicit subsection: "Wrap material MCP calls with `agent_log_command`." List example ops (`read_card`, `toggle_checkboxes`, `append_card`, `take_sprint`, `take_card`, `move_to_todo`, `move_to_in_progress`, `complete_card`). Show the exact invocation pattern. |
| **.claude/skills/reviewer/SKILL.md** | Same gap as executor. | Same addition, tailored to reviewer ops (`read_card`, `search_cards`, `append_card`, `move_to_todo`). |
| **.claude/skills/router/SKILL.md** | Same gap. | Same addition, tailored to router ops (`read_card`, `list_cards`). |
| **.claude/skills/planner/SKILL.md** | Same gap. Profiling section is at lines ~118-146 (the block this card will mirror in the other skills). | Same addition, tailored to planner ops (`search_cards`, `create_card`, `append_card`, `add_card_to_sprint`, `update_card_metadata`, `move_to_todo`). |
| **.gitban/hooks/agent-log.sh** | Reference only — exposes `agent_log_command`. | No code change expected. If the helper signature is unclear in any SKILL.md example, prefer linking to the hook rather than re-documenting it. |

**Documentation Organization Check:**
* [ ] No duplicate documentation found across locations
* [ ] Documentation follows team's organization standards
* [ ] Cross-references between docs are working
* [ ] Orphaned or outdated docs identified for cleanup

## Documentation Work

| Task | Status / Link to Artifact | Universal Check |
| :--- | :--- | :---: |
| **Add `agent_log_command` wrapping guidance to executor SKILL.md Profiling section** | pending | - [ ] Complete |
| **Add `agent_log_command` wrapping guidance to reviewer SKILL.md Profiling section** | pending | - [ ] Complete |
| **Add `agent_log_command` wrapping guidance to router SKILL.md Profiling section** | pending | - [ ] Complete |
| **Add `agent_log_command` wrapping guidance to planner SKILL.md Profiling section** | pending | - [ ] Complete |
| **Document an example pattern (before-and-after) showing a wrapped MCP call and the resulting JSONL fields** | pending | - [ ] Complete |
| **Audit remaining skills (dispatcher, sprintmaster, sprint-architect, sprint-reviewer) for profiling sections; update if present** | pending | - [ ] Complete |
| **Smoke check: run one executor-style cycle after edits; confirm `total_commands > 0` in the JSONL summary** | pending | - [ ] Complete |

**Documentation Quality Standards:**
* [ ] All code examples tested and working
* [ ] All commands verified
* [ ] All links working (no 404s)
* [ ] Consistent formatting and style
* [ ] Appropriate for target audience
* [ ] Follows team's documentation style guide

## Acceptance Criteria

- [ ] Every affected SKILL.md (executor, reviewer, router, planner at minimum) has an explicit instruction to wrap material MCP operations with `agent_log_command` or equivalent, with a concrete example block an agent can copy-paste.
- [ ] The guidance specifies which operations count as "material" (enumerated list — state mutations and content reads/writes — not every list/read_help call).
- [ ] A sample agent cycle run after the edits produces a JSONL summary with `total_commands >= 1` and non-zero durations per command.
- [ ] No code changes to `agent-log.sh` itself (confirm or explicitly note if signature clarification requires a tiny helper update).
- [ ] If any of dispatcher/sprintmaster/sprint-architect/sprint-reviewer SKILL.md files have a Profiling section, they receive the same guidance for symmetry.

## Validation & Closeout

| Task | Detail/Link |
| :--- | :--- |
| **Final Location** | Updates land in `.claude/skills/{executor,reviewer,router,planner}/SKILL.md` (plus any discovered in the dispatcher/sprintmaster/architect/reviewer audit). |
| **Path to final** | `.claude/skills/executor/SKILL.md`, `.claude/skills/reviewer/SKILL.md`, `.claude/skills/router/SKILL.md`, `.claude/skills/planner/SKILL.md` |

### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Documentation Gaps Identified?** | If audit finds more skills missing profiling entirely (not just `agent_log_command`), capture as a standalone follow-up rather than expanding this card mid-flight. |
| **Style Guide Updates Needed?** | Consider a shared "Profiling canonical block" snippet all SKILL.md files reference, to prevent drift. Propose only; do not implement here unless trivial. |
| **Future Maintenance Plan** | When adding a new agent skill, include the `agent_log_command` guidance from day one (note in skill-creator SKILL.md if it exists). |

### Completion Checklist

* [ ] All documentation tasks from work plan are complete
* [ ] Documentation is in the correct location (not in root dir or random places)
* [ ] Cross-references to related docs are added
* [ ] Documentation is peer-reviewed for accuracy
* [ ] No doc cruft left behind (old files cleaned up)
* [ ] Future maintenance plan identified [if applicable]
* [ ] Related work cards are updated [if applicable]
