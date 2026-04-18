
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

* [ ] Sprint tag `TTSNATIVE` is the filename prefix for every card in this sprint (`list_cards(sprint="TTSNATIVE")` returns all four non-planning cards).
* [ ] `v2/m5/tts-native` status is `in_progress` in the roadmap.
* [ ] Cards `as44cd`, `dpyzoo`, `w3ciyq`, `gvleuv` all exist in status `todo` with full acceptance criteria filled in (P1 cards must be detailed at creation time per gitban conventions).
* [ ] `take_sprint(sprint_name="TTSNATIVE")` has been invoked so the sprint is claimed.
* [ ] Every card's Required Reading references `docs/designs/tts-native.md` and `docs/adr/ADR-001-tts-backend-architecture.md` (the two governing documents).

## Completion Checklist

* [ ] Sprint tag verified
* [ ] Roadmap node flipped to `in_progress`
* [ ] All sibling cards exist in `todo` with full acceptance criteria
* [ ] `take_sprint` called
