## Feedback Overview

* **Client/Source:** peon-ping TTSNATIVE sprint (dispatcher session 15a512fd on 2026-04-19)
* **Feedback Type:** Usability / harness behavior — structural block that stopped a card from making progress
* **Date Received:** 2026-04-19
* **gitban Version:** unknown (whichever ships with Claude Code plugins-cache on 2026-04)
* **Environment:** Claude Code on Windows 10 (Git Bash / MSYS2), sub-agents spawned via the Agent tool with and without `isolation: worktree`

**Required Checks:**
* [x] Client/source is documented above.
* [x] Feedback type is identified.
* [x] Date received is recorded.

### Initial Notes

During the TTSNATIVE sprint, a reviewer surfaced a minor profiling-hygiene observation on the first card: agents emit `agent_log_event` but not `agent_log_cmd`, so the JSONL summary's `total_commands` field reads `0`. Not breaking anything — just making the dispatcher's per-phase cost table uninformative.

The planner promoted this into a standalone gitban card against the peon-ping sprint (`j7yapo`) with scope "edit `.claude/skills/{executor,reviewer,router,planner}/SKILL.md` to add an `agent_log_cmd` example block". That card immediately hit two structural walls:

1. **Worktree isolation denies writes to `.claude/`.** The Agent harness's sub-agents (including those dispatched WITHOUT `isolation: "worktree"` — both the default executor and a general-purpose agent) run inside a worktree sandbox at `.claude/worktrees/agent-<id>/`. The harness denies `Edit`, `Write`, and mutating `Bash` operations targeting paths under `.claude/skills/` in the parent worktree. Probes: `Edit`, `Write <path>.probe`, `Bash echo > <path>.probe` all rejected. `Read` and `Grep` are allowed so analysis finishes, but the fix can't land.

2. **`.claude/` is gitignored in most consumer repos.** `git check-ignore .claude/skills/executor/SKILL.md` → ignored. `git ls-files .claude/skills/` → empty. Even if a main-thread agent could write the files, a `git add` without `-f` would silently drop them. A gitignore whitelist like `!.claude/skills/*/SKILL.md` plus a force-add baseline would work, but that's a gitban-integration decision, not something an ad-hoc executor should make.

3. **SKILL.md files are gitban-deployed anyway.** They originate in the gitban package, not the consumer repo, so any consumer-repo edit is ephemeral and gets overwritten by the next gitban sync. The right place to fix the guidance is the gitban repo's canonical skill sources.

The card has been blocked locally in the peon-ping sprint with a "needs gitban-repo fix" reason, and ready-to-paste draft content (the canonical `agent_log_cmd` insertion block plus role-specific material-op lists for executor/reviewer/router/planner) has been preserved on the card body for whoever picks this up upstream.

**Draft block (preserved from peon-ping card `j7yapo`)** — intended for insertion into executor SKILL.md's Structured Profiling section after the `agent_log_event` examples:

```markdown
#### Wrap material MCP calls with `agent_log_cmd`

The `agent_log_event` helper records a labelled JSONL entry but does NOT increment the command counter used in the summary. The dispatcher's cost-tracking summary reports `total_commands` and `total_duration_s`, and those figures come exclusively from `agent_log_cmd` invocations. An executor cycle that only emits events will produce `total_commands:0` and a misleading cost signal.

For every material MCP call, wrap it with an `agent_log_cmd` stub so the counter and duration totals are accurate:

    agent_log_cmd ": mcp read_card card_id=<id>"
    agent_log_cmd ": mcp toggle_checkboxes card_id=<id> count=<N>"
    agent_log_cmd ": mcp append_card card_id=<id> bytes=<N>"

Material operations for executor: `read_card`, `take_card`, `take_sprint`, `append_card`, `edit_card`, `toggle_checkboxes`, `get_remaining_checkboxes`, `update_card_metadata`, `move_to_todo`, `move_to_in_progress`, `block_card`, `complete_card`, `create_card`, `add_card_to_sprint`, `archive_card`, `upsert_roadmap`, `update_changelog`.

Non-material (skip): `list_cards`, `search_cards`, `render_board`, `read_roadmap`, `get_help`, `health_check`.
```

Role-specific material-op lists:
- **reviewer:** `read_card`, `search_cards`, `append_card`, `edit_card`, `move_to_todo`, `move_to_in_progress`, `block_card`, `update_card_metadata`.
- **router:** `read_card`, `list_cards`, `append_card`, `move_to_todo`, `move_to_in_progress`.
- **planner:** `search_cards`, `read_card`, `create_card`, `append_card`, `edit_card`, `add_card_to_sprint`, `update_card_metadata`, `move_to_todo`, `block_card`, `upsert_roadmap`.

The real helper name in `.gitban/hooks/agent-log.sh` is `agent_log_cmd` (lines 17–20 and 109–139). Some earlier drafts called it `agent_log_command` — use the real name.

### Response & Action

| Phase / Task | Status / Assignee / Link | Universal Check |
| :--- | :--- | :---: |
| **Initial Assessment** | Blocked in peon-ping sprint TTSNATIVE; routed here | - [x] Feedback assessed |
| **Priority Decision** | P2 — cosmetic profiling signal, no functional break | - [x] Priority assigned |
| **Response to Client** | This card itself | - [x] Client acknowledged |
| **Investigation** | Root cause documented above; draft content preserved | - [x] Root cause identified |
| **Implementation** | TBD — gitban team picks up | - [ ] Fix/improvement implemented |
| **Client Verification** | TBD — peon-ping will unblock `j7yapo` when guidance lands | - [ ] Client verified resolution |

### Resolution & Follow-up

| Task | Detail/Link |
| :--- | :--- |
| **Final Resolution** | Pending |
| **Client Communication** | This card; also cross-referenced on peon-ping card `j7yapo` (blocked) |
| **Related Work** | peon-ping sprint `TTSNATIVE`, card `j7yapo`, blocked with the reason and ready-to-paste content |

#### Follow-up & Lessons Learned

| Topic | Status / Action Required |
| :--- | :--- |
| **Pattern Recognition** | Any cross-cutting fix to gitban-deployed skill sources will hit this same wall if consumer sprints try to route it locally |
| **Documentation Needed** | Router/planner guidance: "if the fix target is a gitban-deployed SKILL.md, open gitban feedback instead of creating a local card" |
| **Further Investigation** | Could the Agent harness whitelist `.claude/skills/` writes? Or could gitban ship an "edit-my-skills" affordance that doesn't require filesystem access from the consumer? |
| **Process Improvement** | Add a dispatcher pre-check: if a card's scope pins `.claude/skills/**`, route it to gitban feedback rather than dispatching |

#### Completion Checklist

* [x] Feedback was assessed and prioritized.
* [x] Client was acknowledged and kept informed.
* [x] Root cause was identified [if applicable].
* [ ] Resolution was implemented or decision was documented.
* [ ] Client was notified of resolution.
* [x] Any follow-up work was created and tracked.
* [x] Lessons learned were documented.