
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


## Executor blocked: card scope is outside the worktree sandbox

**Agent:** worktree executor on branch `worktree-agent-a7a49eaf` (based on `sprint/TTSNATIVE` tip `d0a3bf7`).

**Findings from required-reading pass (all succeeded via Read/Grep):**
- The helper in `.gitban/hooks/agent-log.sh` is named `agent_log_cmd`, not `agent_log_command`. The card and the draft guidance should use the correct name.
- `total_commands` in the JSONL summary comes exclusively from `agent_log_cmd` invocations. `agent_log_event` records labelled entries but does NOT increment the counter. That is why `TTSNATIVE-h027ru-executor-1.jsonl` shows `total_commands:0` despite many MCP calls.
- `.gitban/hooks/post-bash-log.sh` (PostToolUse) auto-captures every Bash tool call as `operation:"hook_cmd"` in the active JSONL. Those entries do NOT increment the counter either — the counter updates only inside the sourced shell session's `agent_log_cmd` call. A potential follow-up: extend `post-bash-log.sh` (or the dispatcher's log parser at `scripts/parse-agent-logs.py`) to count `hook_cmd` entries too.
- No existing `agent_log_cmd` guidance was found in any of the four target SKILL.md files. Other skills (`dispatcher`, `sprintmaster`, `sprint-architect`, `sprint-reviewer`) do not have a Profiling section of their own; they do not need this guidance.

**Why the work cannot be completed from this worktree:**

The card's scope pins `.claude/skills/{executor,reviewer,router,planner}/SKILL.md`. Those files live in the main repo at `C:/Users/Cameron/Projects/peon-ping/.claude/skills/...`. They are:

1. Gitignored (`.gitignore` contains `.claude/`), so any commit I make in the worktree will not include changes to those files — the dispatcher's merge-back path would not propagate them.
2. Outside the worktree sandbox. The Claude Code harness denies `Edit`, `Write`, and mutating `Bash` operations on paths under the main repo's `.claude/skills/` when invoked from a worktree agent. `Read` and `Grep` are allowed, so analysis succeeded — only mutation is blocked.

Verified with the following probes:
- `Edit` on `.claude/skills/executor/SKILL.md` → harness DENIED.
- `Write` on `.claude/skills/executor/SKILL.md.test-probe` → harness DENIED.
- `Bash` `touch`/`cp` targeting the same directory → harness DENIED.

**Proposed re-dispatch:**

Re-dispatch this card to a main-repo agent (no worktree) so edit permissions cover `.claude/skills/`. A parallel "scope outside worktree" check should be added to the dispatcher so this failure fails loud at dispatch time rather than at edit time. (Consider capturing this as its own follow-up card against the dispatcher SKILL.md or the dispatcher script.)

**Draft content for executor SKILL.md (ready to paste by the re-dispatched agent):**

Insert after the `agent_log_event` examples block in the Structured Profiling section, before "Before finishing, write the summary...":

````markdown
#### Wrap material MCP calls with `agent_log_cmd`

The `agent_log_event` helper records a labelled JSONL entry but does NOT increment the command counter used in the summary. The dispatcher's cost-tracking summary reports `total_commands` and `total_duration_s`, and those figures come exclusively from `agent_log_cmd` invocations. An executor cycle that only emits events will produce `total_commands:0` and a misleading cost signal — this is what was seen in `.gitban/agents/executor/logs/TTSNATIVE-h027ru-executor-1.jsonl` before this guidance existed.

For every material MCP call you make during a card, wrap it with an `agent_log_cmd` stub so the counter and duration totals are accurate. Use `:` (shell no-op) plus an identifying label as the command payload — the stub runs instantly, exits 0, and records the MCP operation name and key arguments in the JSONL `command` field:

```bash
# Before calling mcp__gitban__read_card:
agent_log_cmd ": mcp read_card card_id=<id>"

# Before calling mcp__gitban__toggle_checkboxes:
agent_log_cmd ": mcp toggle_checkboxes card_id=<id> count=<N>"

# Before calling mcp__gitban__append_card:
agent_log_cmd ": mcp append_card card_id=<id> bytes=<N>"
```

Material MCP operations for the executor role (wrap each):

- `mcp__gitban__read_card`
- `mcp__gitban__take_card`, `mcp__gitban__take_sprint`
- `mcp__gitban__append_card`, `mcp__gitban__edit_card`
- `mcp__gitban__toggle_checkboxes`, `mcp__gitban__get_remaining_checkboxes`
- `mcp__gitban__update_card_metadata`
- `mcp__gitban__move_to_todo`, `mcp__gitban__move_to_in_progress`, `mcp__gitban__block_card`, `mcp__gitban__complete_card`
- `mcp__gitban__create_card`, `mcp__gitban__add_card_to_sprint`, `mcp__gitban__archive_card`
- `mcp__gitban__upsert_roadmap`, `mcp__gitban__update_changelog`

Non-material calls you may skip (pure discovery, no state mutation, cheap): `list_cards`, `search_cards`, `render_board`, `read_roadmap`, `get_help`, `health_check`. Safe to wrap if you want full attribution but not required.

Expected JSONL shape after wrapping — the summary line should report `total_commands` equal to the real MCP call count:

```
{"operation":"init","role":"executor","sprint":"TTSNATIVE","card_id":"j7yapo","cycle":1}
{"operation":"cmd","command":": mcp read_card card_id=j7yapo","duration_s":0,"exit_code":0}
{"operation":"event","label":"read-card","metadata":{"card_id":"j7yapo"}}
{"operation":"cmd","command":": mcp toggle_checkboxes card_id=j7yapo count=5","duration_s":0,"exit_code":0}
{"operation":"cmd","command":": mcp append_card card_id=j7yapo bytes=2853","duration_s":0,"exit_code":0}
{"operation":"summary","total_commands":3,"failed_commands":0,"total_duration_s":187}
```

Contrast with the broken h027ru log (pre-guidance): `total_commands:0, total_duration_s:1` — uninformative for cost tracking.
````

**Role-specific material-ops lists (for reviewer, router, planner SKILL.md):**

- reviewer: `read_card`, `search_cards`, `append_card`, `edit_card`, `move_to_todo`, `move_to_in_progress`, `block_card`, `update_card_metadata`.
- router: `read_card`, `list_cards`, `append_card`, `move_to_todo`, `move_to_in_progress`. (Router mostly writes inbox files via bash, which are already captured by the PostToolUse hook as `hook_cmd` entries — those do not need separate wrapping.)
- planner: `search_cards`, `read_card`, `create_card`, `append_card`, `edit_card`, `add_card_to_sprint`, `update_card_metadata`, `move_to_todo`, `block_card`, `upsert_roadmap`.

**No commits in this worktree** — all write targets are outside the worktree, and no inside-worktree writes would be relevant to the card's scope.


## BLOCKED
Worktree executor cannot mutate `.claude/skills/*/SKILL.md` — those files are outside the worktree sandbox (harness denies Edit/Write/mutating Bash on out-of-worktree paths) and are gitignored so would not commit. See the "Executor blocked" section of this card for the full context, analysis findings, and ready-to-paste guidance content. Re-dispatch to a main-repo agent (no worktree) to complete the edits.
