
# Step 5: TTSNATIVE sprint closeout

Closes out the TTSNATIVE sprint. Runs only after steps 2, 3, and 4 are done. Single end state: **`v2/m5/tts-native` is `done` in the roadmap, all TTSNATIVE cards are archived, the changelog is bumped, and audible-speech regression is verified on each supported platform.**

This is a CLI-tool project with a solo maintainer. Inapplicable template rows (ops team training, stakeholder comms, successor project handoff, celebration events) have been deliberately removed — the closeout checklist reflects what actually needs doing, not what the generic template suggests.

## Preconditions

* [ ] step 2 (`as44cd`) merged — `scripts/tts-native.sh` on main, BATS green on macOS CI.
* [ ] step 3 (`dpyzoo`) merged — `scripts/tts-native.ps1` on main, Pester green on Windows CI.
* [ ] step 4a (`w3ciyq`) resolved — every appended item either checked or promoted to a standalone card; no unresolved items remain.
* [ ] step 4b (`j7yapo`) resolved — agent profiling hygiene (`agent_log_command`) documentation merged across executor/reviewer/router/planner SKILL.md; smoke-checked a cycle produces `total_commands >= 1` in its JSONL summary.

## Audit Checklist

| Audit Area | What to verify |
| :--- | :--- |
| **Design doc still accurate** | `docs/designs/tts-native.md` matches shipped interface; record any drift in the retrospective, don't silently edit |
| **ADR-001 still accurate** | No deviations from the calling convention, stdin contract, or silent-failure policy |
| **Test coverage** | `tests/tts-native.bats`, `tests/tts-native.Tests.ps1`, and the `adapters-windows.Tests.ps1` structural additions are all green on CI; existing `tests/tts.bats` still passes against the mock backend |
| **Performance regression** | `[exit] duration_ms` with `tts.enabled: true` is within ±50ms of the `tts.enabled: false` baseline on macOS, Linux (espeak-ng host), and Windows |
| **Audibility** | `peon notifications test` produces spoken output on at least one host per supported platform |
| **No debt introduced** | macOS volume and piper+aplay volume limitations are documented in `docs/designs/tts-native.md` §Risks; no `TODO`/`FIXME` added during the sprint remains unresolved |

Explicitly not in scope for this sprint: user-facing README updates, `docs/public/llms.txt` updates, and the `peon tts` CLI subcommands — all shipped separately by the `tts-cli` and `tts-docs` features.

## Closeout Workflow

1. **Archive done cards**

   ```python
   archive_cards(
       archive_name="2026-04-TTSNATIVE-Sprint",
       all_done=True,
       preview=False,
   )
   ```

2. **Flip roadmap node to done**

   ```python
   upsert_roadmap(
       content={"status": "done", "completion_date": "2026-04-XX"},
       path="v2/m5/tts-native",
   )
   ```

   **Do not mark `v2/m5` done** — `tts-cli`, `tts-notifications`, `tts-docs`, `tts-elevenlabs`, and `tts-piper` are still `planned`. The milestone stays `in_progress`.

3. **Bump changelog (minor version — new feature)**

   ```python
   update_changelog(
       entry={
           "version": "X.Y.0",
           "date": "2026-04-XX",
           "changes": [
               "Added platform-native TTS backends — tts.enabled: true now produces speech on macOS, Linux, and Windows",
               "macOS: say; Linux: piper/espeak-ng priority chain; Windows: SAPI5 via System.Speech.Synthesis",
               "tts-native.sh --list-voices and tts-native.ps1 -ListVoices enumerate installed voices per platform",
           ],
       },
       mode="append",
   )
   ```

   Bump `VERSION`, commit `chore: bump version to X.Y.0`, tag `vX.Y.0`, push tags (per `RELEASING.md`).

4. **Generate sprint summary**

   ```python
   generate_archive_summary(
       archive_folder_name="sprint-2026-04-ttsnative-sprint-<timestamp>",
       mode="enhanced",
       executive_summary="Shipped platform-native TTS backends for macOS, Linux, and Windows. v2/m5/tts-native is done; m5 stays in_progress.",
       lessons_learned={
           "what_went_well": [],
           "what_could_improve": [],
       },
       next_steps=[
           "tts-cli (unblocked by this sprint)",
           "tts-notifications (unblocked by this sprint)",
       ],
   )
   ```

## Retrospective

Populate at closeout. Keep brief — this is a solo sprint; the retro exists so future sprints benefit, not for ceremony.

* **What went well:** _(populate)_
* **What could improve:** _(populate)_
* **Debt or follow-ups created:** _(populate; expected: none beyond the already-documented volume limitations)_

## Acceptance Criteria

* [ ] All TTSNATIVE cards moved to `done`, archived to `sprint-2026-04-ttsnative-sprint-<timestamp>` via `archive_cards`.
* [ ] `v2/m5/tts-native` status is `done` in the roadmap; `v2/m5` milestone remains `in_progress`.
* [ ] `CHANGELOG.md` has a new entry for the shipped feature; `VERSION` bumped (minor); tag `vX.Y.0` pushed.
* [ ] `generate_archive_summary` executed with retrospective populated (not empty arrays).
* [ ] Performance regression verified on macOS, Linux, and Windows (`[exit] duration_ms` within ±50ms of baseline).
* [ ] Audible-speech smoke check passed on at least one host per supported platform.
* [ ] `tests/tts.bats`, `tests/tts-native.bats`, `tests/tts-native.Tests.ps1`, and `tests/adapters-windows.Tests.ps1` all green on CI post-merge.
* [ ] Follow-up tracker (`w3ciyq`, step 4a) has no unresolved items — every appended item is either checked or promoted to a standalone card.
* [ ] Agent profiling hygiene card (`j7yapo`, step 4b) is done — SKILL.md updates merged; JSONL summary smoke-check showed `total_commands >= 1`.
* [ ] Any TTSNATIVE card still in `todo`, `in_progress`, or `blocked` at closeout time is explicitly triaged — moved to backlog (`move_to_backlog`), promoted to a next-sprint card, or resolved — before `archive_cards` runs.

## Completion Checklist

* [ ] Incomplete cards triaged (moved to backlog or promoted) before archive
* [ ] Cards archived
* [ ] Roadmap flipped
* [ ] Changelog + `VERSION` bumped and tagged
* [ ] Sprint summary generated
* [ ] Retrospective populated in this card
* [ ] Performance + audibility smoke checks recorded
