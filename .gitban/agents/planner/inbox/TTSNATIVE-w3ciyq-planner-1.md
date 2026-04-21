The reviewer flagged 1 non-blocking item, grouped into 1 card below.
Create ONE card per group. Do not split groups into multiple cards.
The planner is responsible for deduplication against existing cards.
All cards go into the current sprint unless marked BLOCKED with a reason.

### Card 1: Strengthen voice case-insensitivity Pester assertion
Sprint: TTSNATIVE
Files touched: tests/tts-native.Tests.ps1
Items:
- L1: The test at `tests/tts-native.Tests.ps1:446-470` (Describe "tts-native.ps1 voice case insensitivity") asserts only `SelectVoiceCalled | Should -BeTrue` and `SelectedVoice | Should -Not -BeNullOrEmpty` after invoking with an uppercase voice name. These assertions do not actually prove the uppercase name resolved to the canonical installed voice — they would still pass if the "default voice" fallback kicked in. Tighten the assertion to `$r.Trace.SelectedVoice | Should -Be $first` (canonical form, not `$upper`) so the test genuinely codifies the case-insensitive-match contract and would fail if someone swapped `-contains` for `-ccontains`. One-line change in the same file, same Describe block, no interface change. Source: `.gitban/agents/reviewer/inbox/TTSNATIVE-w3ciyq-reviewer-1.md` FOLLOW-UP L1.

Rationale for routing to planner (not executor close-out): This is a test-quality fix that requires re-running Pester to verify the strengthened assertion still passes against the real voice-selection code path. Close-out items cannot require rerunning the test suite, so this belongs in a follow-up card. It is a single-line additive change inside the already-landed Describe block — fits the aggregation tier naturally. Given the TTSNATIVE step-4a tracker (w3ciyq) is being closed out, consider appending to the sprint closeout card (gvleuv) Items section OR creating a standalone micro-card in the current sprint per your aggregation-tier criteria.
