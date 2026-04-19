
# Step 1: Sprint Planning — TTSNATIVE (Platform-native TTS backends)

Planning-phase card. Its single end state: **the TTSNATIVE sprint is named, the roadmap is flipped to `in_progress`, and all feature/chore/spike cards exist in `todo`.** Closeout lives on step 5 (`gvleuv`); do not duplicate it here.

## Sprint Definition

* **Sprint Tag**: TTSNATIVE
* **Sprint Goal**: Ship `scripts/tts-native.sh` and `scripts/tts-native.ps1` so `tts.enabled: true` produces spoken output on every supported platform using its built-in engine, with zero setup beyond what the OS already provides.
* **Roadmap Node**: `v2/m5/tts-native` — moves `planned` → `in_progress` at sprint start; set to `done` by step 5.
* **Design Doc**: `docs/designs/tts-native.md`
* **ADR**: `docs/adr/ADR-001-tts-backend-architecture.md`
* **Sprint DoD (owned by step 5, recorded here for reference)**: both scripts exist, are copied by installers, BATS/Pester unit tests pass in CI, and audible speech is produced on at least one macOS/Linux/Windows host via the hook pipeline's existing `speak()` / `Invoke-TtsSpeak` entry points.

## Card Plan

| Step | Card | Type | Notes |
| :---: | :--- | :--- | :--- |
| 2 | `as44cd` — Unix `tts-native.sh` + BATS | feature | macOS `say`, Linux piper/espeak-ng chain, MSYS2 bridge, `--list-voices`, `install.sh` wiring |
| 3 | `dpyzoo` — Windows `tts-native.ps1` + Pester | feature | SAPI5 via `System.Speech.Synthesis`, `-ListVoices`, `install.ps1` wiring, structural tests |
| 4 | `w3ciyq` — TTSNATIVE follow-up tracker | chore | Aggregation card; planner appends mid-sprint; resolved before step 5 |
| 5 | `gvleuv` — TTSNATIVE sprint closeout | spike | Archive, changelog, roadmap flip, retrospective |

**Parallelism:** steps 2 and 3 modify disjoint files (`scripts/tts-native.sh` + Unix tests vs. `scripts/tts-native.ps1` + Pester tests) and have no code-level dependency between them. They can be executed in parallel. Step 4 runs late-sprint once most follow-ups have landed. Step 5 runs last.

## Acceptance Criteria

- [x] Sprint tag `TTSNATIVE` is the filename prefix for every card in this sprint (`list_cards(sprint="TTSNATIVE")` returns all four non-planning cards).
- [x] `v2/m5/tts-native` status is `in_progress` in the roadmap.
- [x] Cards `as44cd`, `dpyzoo`, `w3ciyq`, `gvleuv` all exist in status `todo` with full acceptance criteria filled in (P1 cards must be detailed at creation time per gitban conventions).
- [x] `take_sprint(sprint_name="TTSNATIVE")` has been invoked so the sprint is claimed.
- [x] Every card's Required Reading references `docs/designs/tts-native.md` and `docs/adr/ADR-001-tts-backend-architecture.md` (the two governing documents).

## Completion Checklist

- [x] Sprint tag verified
- [x] Roadmap node flipped to `in_progress`
- [x] All sibling cards exist in `todo` with full acceptance criteria
- [x] `take_sprint` called


## Executor Work Log — cycle 1

**Status at pickup:** Sprint planning artefacts already landed in commits `6a43c4a` (sprint open) and `2775813` (h027ru → in_progress) on `sprint/TTSNATIVE`. This executor cycle verified and ticked each acceptance criterion against live state rather than recreating work.

### Verification evidence

| AC | Check | Evidence |
| :--- | :--- | :--- |
| Sprint tag prefix | `list_cards(sprint="TTSNATIVE")` returns 5 cards — h027ru + four non-planning siblings; every filename begins with `TTSNATIVE-` | gitban `list_cards` result |
| `v2/m5/tts-native` `in_progress` | `read_roadmap(path="v2/m5/tts-native")` reports `status: in_progress` | roadmap YAML |
| Cards exist in `todo` with full ACs | `as44cd` (Unix tts-native.sh, 15 detailed ACs), `dpyzoo` (Windows tts-native.ps1, 15 detailed ACs), `w3ciyq` (follow-up tracker, aggregation chore), `gvleuv` (sprint closeout spike) — all `status: todo`, `handle: CAMERON` | read_card × 4 |
| `take_sprint` invoked | `take_sprint(sprint_name="TTSNATIVE", handle="CAMERON")` returned 0 moved / 5 ignored — proof that every card is already out of backlog and claimed | take_sprint response |
| Required Reading references | Both `docs/designs/tts-native.md` and `docs/adr/ADR-001-tts-backend-architecture.md` appear in the Documentation & Prior Art Review table of `as44cd` and `dpyzoo`, and in the preconditions/workflow of `gvleuv`; `w3ciyq` is an aggregation chore and references the sprint feature scope | card read-outs |
| Governance docs present on disk | `docs/adr/ADR-001-tts-backend-architecture.md` (28,661 bytes) and `docs/designs/tts-native.md` (39,066 bytes) both exist on `sprint/TTSNATIVE` | `ls -la` |

### Actions performed this cycle

- `take_sprint(sprint_name="TTSNATIVE", handle="CAMERON")` — idempotent confirmation that all cards are claimed.
- Toggled all 9 checkboxes (5 Acceptance Criteria + 4 Completion Checklist) on this card.
- Appended this work-log summary.

### Parent-agent sprint setup commits (context only — not authored this cycle)

- `6a43c4a` chore(sprint): open sprint/TTSNATIVE with cards and hook updates
- `2775813` chore(sprint): advance h027ru to in_progress

### Deferred / not in scope

Per the card body ("Closeout lives on step 5 (`gvleuv`); do not duplicate it here"), the executor leaves this card in `in_progress` for reviewer sign-off. Closeout artefacts (archive, changelog, VERSION bump, roadmap `done` flip, retrospective) are owned by `gvleuv` and explicitly out of scope here.

### Worktree / branching

- Branch: `worktree-agent-a26b3a2c` (dispatcher-managed worktree branch)
- Base check: `git merge-base --is-ancestor sprint/TTSNATIVE HEAD` → `base ok` after the instructed reset to `fork/sprint/TTSNATIVE` tip (`2775813`).
- No code files were modified this cycle; all changes are `.gitban/` card-state mutations.


## Review Log — cycle 1

- **Verdict:** APPROVAL
- **Commit reviewed:** `081e4c8`
- **Review report:** `.gitban/agents/reviewer/inbox/TTSNATIVE-h027ru-reviewer-1.md`
- **Router routing:**
  - Executor inbox: `.gitban/agents/executor/inbox/TTSNATIVE-h027ru-executor-1.md` (close-out instructions; commit disk-side card/work-log changes)
  - Planner inbox: `.gitban/agents/planner/inbox/TTSNATIVE-h027ru-planner-1.md` (1 non-blocking follow-up: L1 — agent profiling hygiene, route to `w3ciyq` tracker if in scope)
- **Minor observations noted in review (non-blocking, no action required on this card):**
  - Work-log byte-size drift for `docs/designs/tts-native.md` (claimed 39,066; on-disk 38,534). Cosmetic.
  - Executor profiling log contains two `init` rows in the same cycle (harmless); the L1 follow-up covers the `agent_log_command` gap.
- Gate 1 (completion claim) and Gate 2 (implementation quality) both PASS. Planning-only card; deliverable is gitban state, not runtime code.
