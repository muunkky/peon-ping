The reviewer flagged 1 non-blocking item, grouped into 1 card below.
Create ONE card per group. Do not split groups into multiple cards.
The planner is responsible for deduplication against existing cards.
All cards go into the current sprint unless marked BLOCKED with a reason.

Note: The TTSNATIVE sprint already carries a follow-up tracker card (`w3ciyq` — "TTSNATIVE follow-up tracker") per the card plan in h027ru. If this item fits that tracker's aggregation scope, append it there rather than creating a new card. Otherwise, create a fresh card as specified below.

### Card 1: Agent profiling hygiene — use `agent_log_command` for material MCP operations
Sprint: TTSNATIVE
Files touched: `.gitban/hooks/agent-log.sh` (reference only — no change expected), agent skill docs under `.claude/skills/executor/SKILL.md`, `.claude/skills/reviewer/SKILL.md`, `.claude/skills/router/SKILL.md`, `.claude/skills/planner/SKILL.md` (whichever skills currently instruct agents on profiling). The primary deliverable is guidance/documentation update, not runtime code.
Items:
- L1: Encourage executor (and other agent) cycles to invoke `agent_log_command` for material MCP operations (e.g., `read_card`, `toggle_checkboxes`, `append_card`, `take_sprint`) so the JSONL summary reflects real work. Evidence: the h027ru executor cycle reported `total_commands: 0` / `total_duration_s: 1` despite performing multiple MCP calls; this degrades the profiling signal the dispatcher relies on for cost tracking. Action: update the relevant SKILL.md files to require `agent_log_command` wrapping (or equivalent) around material MCP calls, and document the expected pattern. This is a general agent-tooling concern — it is not specific to TTS work.
