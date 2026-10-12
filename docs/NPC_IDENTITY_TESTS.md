# NPC identity implementation and verification

The current world contains **46 TownNPC instances and 9 TownGuard instances** in
`scenes/world_characters.tscn`, instanced by `scenes/main.tscn`. All 55 have exported
stable IDs, catalog assignments and distinct display names after `_ready()`.
The reusable NPC/guard scenes are templates, not additional world characters;
`npc_move.gd` is an unused area helper rather than another character implementation.
All 46 townspeople already belonged to the chat interaction group. Guards retain
their original detection/enemy groups and gain no chat interaction.

## Data and runtime behavior

`data/npcs/character_catalog.json` is the identity registry. Original characters
reference their existing JSON files; those authored fields override catalog
enrichment. Other entries supply identity, background, motivations, preferences,
fears, ambitions, habits, speech, knowledge, relationships and private details.
`docs/NPC_ROSTER.md` lists every identity and its actual district/role.

| Original character | Stable ID | Authoritative profile | Existing daily budget |
| --- | --- | --- | --- |
| Barnaby | `npc_barnaby_merchant` | `data/npcs/barnaby_merchant.json` | 350 |
| Marla | `npc_marla_baker` | `data/npcs/marla_baker.json` | 220 |
| Lord Cedric | `npc_cedric_aristocrat` | `data/npcs/cedric_aristocrat.json` | 1200 |
| Old Arthur | `npc_arthur_elder` | `data/npcs/arthur_elder.json` | 180 |

The four files are unchanged. Their budgets are now explicit scene values, so
loading identity no longer writes social/economy stats. All other NPC gold,
trust, suspicion and budget values come from existing scene settings/defaults.
This removes the accidental Barnaby overrides, rather than introducing balancing
values. New prose personalities are in `identity_personality`; numeric
`personality` uses the existing neutral fallback. The original four numeric
traits and topic affinities remain unchanged. No gameplay formula was edited.

The duplicate **Plaza Guard** pair is now **Sentry Alden** and **Sentry Nessa**.
Generic **Citadel Sentry**, **Bridge Guard**, and **Canal Guard** are now
**Sentry Edric**, **Sentry Bram**, and **Sentry Iona**. Other meaningful names
are preserved, including Sir Jeffrey, Sir Donald, Captain Stewart and Sentry Lucas.

Missing IDs, invalid JSON, invalid field types and mismatched profile files
produce warnings and a neutral profile using the character's own scene name/title.
No alternate character's profile is substituted. A malformed or ambiguous catalog
is rejected. Profile dictionaries and conversation histories are instance-local.
IDs for unassigned ad hoc runtime nodes isolate history but are not persistent IDs;
all existing world instances use explicit stable catalog IDs.

Scene generation looks up identity and original profile paths from the catalog.
The generator's gameplay/placement configuration is preserved. Tests pack generated
nodes and initialize them without replacing the world file. The existing packed
guard scene uses the inherited knight sprite; that actual runtime sprite is
preserved, including where the old generator listed a different unsaved child texture.

Qwen receives only the active NPC's bounded background, traits, summary, voice and
knowledge alongside existing bounded conversation history. Existing buyer/seller
outcomes, cancellation, transaction protections and dialogue-only authority remain
intact. Greetings, suggested messages and offline replies no longer treat every
unknown identity as Barnaby. Non-chat guards have profiles ready for future use.

## Automated results

Tests use the installed **Godot 4.7.2** and `tests/run_isolated.ps1`, with application
data and fixture saves under `.godot/qwen-test-userdata`. No real save is overwritten.
No dependency, model, asset or browser was installed or downloaded.

| Suite | Result |
| --- | --- |
| `test_npc_identity.gd` | 4,293 checks, 0 failures |
| `test_local_chat.gd` | 227 checks, 0 failures |
| `test_title_screen.gd` | 30 passed, 0 failed |
| `test_mobile_ui.gd` | Passed programmatic desktop/mobile presentation checks |
| `test_ui_presentation.gd` | Passed |
| `test_island_characters.gd` | Passed distribution, sprites, placement and interaction/facing checks |
| `test_island_buildings.gd` | Passed |
| `test_island_world.gd` | Passed |
| `test_island_animals_and_particles.gd` | Passed |
| `test_water_collisions.gd` | Passed |
| `test_gameplay_mechanics.gd` | 127 passed, 13 failed; identical failures reproduced from unchanged Git HEAD |
| `test_llm_connection.gd` | Skipped: no healthy llama.cpp server; live inference unverified |

The identity suite checks every character after saved and regenerated scene
initialization; original JSON fields; unchanged placement/sprites/stats; distinct
guard names; missing, malformed and wrong-owner profiles; active Qwen context;
real offline ChatUI exchanges across nine representative characters; isolated
histories; and equal gameplay results with/without narrative fields.

The title test's obsolete root-level NPC references were updated to the existing
`Characters/` container. Start/Continue, currency/day/reputation/inventory save/load,
player movement, chat movement blocking, pickups and inventory UI now complete.
The test runner also skips absent optional source folders.

The legacy mechanics suite still expects old root-level NPC/environment nodes and
old polygon collider configuration. Its **127 passed / 13 failed** result and
three null-access script errors were reproduced using unmodified HEAD scripts and
world scene in `.godot/npc-baseline-project`. These are pre-existing test failures;
world placement, environment and collision were not changed to satisfy them.
Baseline evidence: `.godot/npc-identity-work/baseline-mechanics.log`.

The host also logs a root certificate store error on headless startup, including
the baseline run. Loopback mock HTTP tests still pass. This is separate from the
explicitly skipped live inference test.

**Not performed:** visual desktop review, physical mobile testing, live Qwen
generation. **Unassigned existing characters:** none.

## Files changed

- Added `data/npcs/character_catalog.json`, `scripts/character_profiles.gd` and its
  Godot UID, `docs/NPC_ROSTER.md`, this report, `tests/test_npc_identity.gd` and its
  UID, and `tests/fixtures/npc_identity_baseline.json`.
- Updated `scenes/world_characters.tscn`, `scripts/npc.gd`, `scripts/guard.gd`,
  `scripts/build_world_characters.gd`, `scripts/local_llm.gd`, `scripts/chat_ui.gd`,
  `tests/run_isolated.ps1`, and `tests/test_title_screen.gd`.
- Ignored `.godot/npc-identity-work/` contains local authoring/audit helpers and
  verification logs; these are not runtime dependencies.

Save schema, save/load implementation, NPC-state persistence, gameplay formulas,
inventory, progression, player movement, world structure/resources/placement,
sprites, collision, camera and UI design are unchanged. No NPC-state saving was
implemented. No commit, push, reset or deployment was performed.
