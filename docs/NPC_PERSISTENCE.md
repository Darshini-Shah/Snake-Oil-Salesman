# NPC runtime persistence

The existing GameState save system now writes `save_version: 2` and `npc_states`,
a dictionary keyed by the 55 stable catalog IDs. The existing player/global keys
and `user://save_game.dat` path remain. No character catalog or authored profile
is embedded in the save.

Each townsperson saves these existing mutable fields:

- `trust`, `suspicion`, `gold`, `max_daily_spend`, `spent_today`
- `successful_scam_count`, `failed_scam_count`
- `is_refusing_to_talk`, `refusal_timer` (remaining game seconds)
- `memories` (up to eight existing event entries)
- `conversation_history` (up to five complete player/NPC exchanges)

Remaining budget is derived by the unchanged economy calculation from gold, cap
and spend. Purchase outcomes are represented by the existing counters and event
memory; the game has no separate transaction ledger, quest flags or mutable
relationship object to serialize. Narrative relationships remain static profiles.
Guards save only their meaningful mutable `is_hostile` flag. Alert/detection state,
player proximity, facing, speech bubbles and network/UI state are reconstructed
by their existing scene behavior, not stored as gameplay records.

`npc_state_codec.gd` centralizes capture, validation and application. Entries carry
an owner ID and kind; foreign owners/kinds and unknown IDs are rejected. Numeric
values must be finite: trust/suspicion are integers in 0..100; financial values
and counters are nonnegative exact JSON integers. Refusal duration must be finite
and nonnegative. Invalid/missing fields retain scene defaults. Memories and history
are copied independently per NPC; text is limited to 16,384 characters per entry.
Save files larger than 16 MiB and non-object/malformed JSON are rejected safely.

## Lifecycle and conversation commits

NPC/guard `_ready()` loads the static profile and initializes presentation before
registering with GameState. Registration records scene defaults, then applies the
pending saved fields for that ID. Weak references avoid keeping freed scenes alive;
scene exit captures state for later scene entry. Duplicate live IDs cannot override
another character's state. Existing profile synchronization points expose restored
stats and history to dialogue and economy systems.

Load cancels current chat requests before replacing state. ChatUI supplies the
complete pre-request history when a save occurs during a pending reply, including
the oldest turn that the ten-turn cap temporarily evicts. Only complete `PLAYER`
and matching NPC speaker pairs are serialized. Foreign speakers, forged roles,
orphan/incomplete turns and transient thinking markers are rejected. Scene teardown
also cancels pending work before NPC arrays are captured. HTTP requests, model paths,
endpoint settings and thinking UI are never serialized. Committed dialogue is saved
after the existing interaction finishes, so counters, events and the reply are all
included after the earlier currency/reputation autosaves.

Start retains its existing confirmation and calls the existing reset method, which
clears cached state and restores live scene defaults before saving. Continue loads
the existing player data and pending NPC state before gameplay initialization.
Loading into an existing scene also resets defaults before applying saved fields.
Unversioned/version-1 saves retain player/global data and use NPC scene defaults.
Missing characters/partial entries default independently; future unknown IDs are
ignored. No migration rewrites a save merely by reading it.

Day rollover retains the original rules: spend resets to zero, suspicion falls by
20 within 0..100, refusal clears, conversation history clears. Gold, trust, scam
counters and event memory retain their previous behavior. The same rule applies
to cached characters that currently have no scene nodes. Loading mid-day neither
resets spending nor applies rollover.

Startup debug inventory initialization no longer autosaves before Continue can
read progress. Normal saves write/flush a sibling `.tmp` file and replace the
existing save only after success. A failed write preserves the prior file. Tests
exercise both protections using isolated data only.

## Reproduction and verification

```powershell
./tests/run_isolated.ps1 -Tests @('test_npc_persistence.gd')
```

The runner executes the scene suite, then a writer process that saves and invokes
Quit, and a fresh reader process that checks startup did not change the file and
invokes Continue. All fixtures use `.godot/qwen-test-userdata`; actual player saves
are never read, changed or deleted during testing. The suite instantiates the real
title/gameplay scenes, checks all 55 IDs/profiles/positions/sprites, modifies distinct
states, saves, recreates the scene, continues, interacts, saves/reloads repeatedly,
and verifies day/budget, old/partial/malformed-save and memory behavior. It includes
pending fallback and real loopback HTTP requests, stale replies, cached scene
re-entry and failed atomic writing. Title actions in this suite use their actual
connected signals; the rendered menu regression additionally sends native Godot
mouse/keyboard/controller/touch events through GUI routing.

## Final results (Godot 4.7.2)

| Suite / phase | Passed | Failed |
| --- | ---: | ---: |
| Real-scene persistence, including reversed character initialization | 9,442 | 0 |
| Separate process writer / actual Quit callback | 280 | 0 |
| Fresh process startup / actual Continue callback | 593 | 0 |
| Existing NPC identity | 4,293 | 0 |
| Existing local chat / loopback HTTP | 227 | 0 |
| Existing title/save/world | 30 | 0 |
| Golden title buttons, headless | 118 | 0 |
| Golden title buttons, real OpenGL renderer / native GUI events | 156 | 0 |
| Mobile UI, UI presentation, island characters/world/buildings/animals, water collisions | All seven suites passed | 0 |
| Legacy gameplay mechanics | 127 | 13 |
| Live llama.cpp inference | Skipped: no healthy server | No inference pass claimed |

All 12 non-legacy suites passed. The persistence suite/phases total **10,315
checks, zero failures**. The 13 legacy failed assertions and three null-access
script errors were freshly reproduced before implementation, then compared with
the final run: the failure descriptions are identical. No new regression or new
parser/runtime error remains in the passing suites. Deliberately failed atomic
writing produces its expected handled warning.

Logs are under `.godot/npc-persistence-work/` and `.godot/test_*.log`.
The rendered title menu was captured and inspected at all four existing test
resolutions. All tracked files outside the seven explicitly modified runtime/test/
documentation files match their pre-task SHA-256 hashes. In particular, all 55
static profiles, the catalog/four original JSON files, world scenes/positions,
golden title assets, local LLM implementation, economy/scam formulas, movement,
inventory and HUD files are unchanged. Only new helper/test files and their Godot
UIDs were added.

Physical mouse/controller/mobile testing and live Qwen inference remain separate
manual checks; synthetic GUI routing is not claimed as physical interaction.
The host's pre-existing root certificate store startup error is unrelated to
persistence. No downloads, browser launches, dependencies or Git writes are needed.
