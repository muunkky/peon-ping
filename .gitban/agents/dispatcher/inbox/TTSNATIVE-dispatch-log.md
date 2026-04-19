# TTSNATIVE Dispatch Log

## Phase 0: Sprint prep

- Sprint `TTSNATIVE` claimed (5 cards, all already todo, CAMERON)
- Branched `sprint/TTSNATIVE` off local main at `a01941b`
- Committed untracked card files + hook tweaks (`6a43c4a`)
- Pushed to `fork/sprint/TTSNATIVE` — `origin` is upstream PeonPing (read-only), `fork` is muunkky/peon-ping (write)

### Harness quirk discovered

Claude Code Agent tool `isolation: "worktree"` branches worktrees from `origin/HEAD → origin/main` (upstream tip `0cf26af`), not from the current local branch. Fork's main has diverged from upstream by 3 commits (gitban-workspace tracking, TTSINTEG merge, tts-native design doc), so worktrees land on an incompatible base and the executor skill's `git merge-base --is-ancestor sprint/<tag> HEAD` check fails with `WRONG BASE`.

**Workaround:** prepend every executor prompt with an explicit reset preamble:

```
git fetch fork sprint/TTSNATIVE
git reset --hard FETCH_HEAD
```

This resets the worktree-agent-* branch to the sprint tip before the skill's base-check runs.

## Phase 1: h027ru — step 1 sprint planning verify

| Stage | Agent | Result |
|:------|:------|:-------|
| executor-1 | a3b401c4 | INTERNAL_ERROR — WRONG BASE (harness quirk) |
| executor-2 | a26b3a2c | APPROVAL-ready — all 9 checkboxes verified, profiling log committed (`081e4c8`) |
| reviewer-1 | ab266ec3 | APPROVAL (planning card; DoD met; minor hygiene observations) |
| router-1 | a2fbcbfb | Approval → closeout; 1 non-blocking follow-up → planner |
| closeout-1 | a8578a61 | Card moved to `done` (`bf495bf`, `2ed8a6f`); not archived |
| planner-1 | ae4269c5 | Created standalone card `j7yapo` (step 4b agent-log hygiene); renamed w3ciyq → step-4a |

### Sprint expansion

Planner split step 4 into parallel 4a (`w3ciyq` tracker) and 4b (`j7yapo` agent-logging hygiene). Step 5 preconditions updated to gate on both.

Remaining: step 2 (as44cd), step 3 (dpyzoo), step 4a (w3ciyq), step 4b (j7yapo), step 5 (gvleuv).

Sprint branch tip: `565c4de` (pushed to fork).
