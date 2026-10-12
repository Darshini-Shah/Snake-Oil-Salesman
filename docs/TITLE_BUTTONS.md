# Title button replacement

The four new images in `C:/Zekrui` were identified from their printed labels:

| Source | Final asset |
| --- | --- |
| `ChatGPT Image Oct 13, 2026, 02_11_47 AM-1.png` (Start) | `assets/ui/title_buttons/start.png` |
| `ChatGPT Image Oct 13, 2026, 02_11_49 AM-2.png` (Continue) | `assets/ui/title_buttons/continue.png` |
| `ChatGPT Image Oct 13, 2026, 02_11_51 AM-3.png` (Settings) | `assets/ui/title_buttons/settings.png` |
| `ChatGPT Image Oct 13, 2026, 02_11_53 AM-4.png` (Quit) | `assets/ui/title_buttons/quit.png` |

All final images are 1611 x 430 RGBA with genuine transparency. The shared crop
is [281, 140, 1892, 570], retaining the artwork pixels exactly. No resizing,
recoloring or external source changes occurred. `preparation.json` records source
hashes and processing details. `scripts/prepare_title_buttons.py` reproduces them
using the existing Pillow installation.

This replacement overwrites the four existing texture paths. It requires no
additional scene or runtime script edits. The existing TextureButtons retain
the original menu slots, spacing, nearest filtering, alpha click masks, arrow
cursor, hover/focus/pressed feedback, and disabled Continue appearance. Background,
logo, callbacks, settings interface, confirmation behavior and gameplay are
unchanged. No obsolete title button PNGs remain in the project.

## Verification of these replacement images

Godot 4.7.2 reimported the textures and ran the real OpenGL renderer.
Screenshots were captured and inspected at 1152 x 648, 1280 x 720,
1920 x 1080 and 1600 x 720 landscape. The new images appear below the logo and
above the cat, with no black rectangles, duplicate graphics, overlap or layout
shift. The existing background cover behavior on wide landscape is preserved.

| Test rerun | Result |
| --- | --- |
| Rendered `test_title_buttons.gd` | 156 checks, 0 failures; actual Quit exits with code 0 |
| Headless `test_title_buttons.gd` | 118 checks, 0 failures |
| Existing `test_title_screen.gd` | 30 passed, 0 failed |
| `test_ui_presentation.gd` | 0 failures |
| `test_mobile_ui.gd` | 0 failures |

Native Godot GUI routing received synthetic mouse, keyboard, controller D-pad
and touch events. Verified: Start opens gameplay and retains save confirmation;
Continue loads valid saves and remains disabled without a save; Settings opens
and closes; Quit exits; transparent pixels reject clicks; hover and pressed
feedback work. Gameplay capture and assertions confirm the existing village loads.
Physical input/device testing was not performed. Existing gamepad face-button
activation is not mapped by the project's ui_accept action; D-pad focus works.

No missing textures, broken paths, UID errors or new parser/runtime errors appeared.
The host's previously observed root certificate store startup error remains.
All saves used isolated `.godot/qwen-test-userdata`, preserving real user saves.
Broader gameplay/NPC suites were not rerun for this asset-only update; the earlier
legacy mechanics suite's known 13 failures remain outside this change.

Captured images: `.godot/qwen-test-project/.godot/title_buttons_review/`.
Run logs: `.godot/title-button-work/replacement-rendered.log` and
`.godot/title-button-work/replacement-regressions.log`.

Files updated for this replacement: the four PNGs, `preparation.json`,
`scripts/prepare_title_buttons.py`, expected image dimensions/center coordinates
in `tests/test_title_buttons.gd`, and this report. Existing Godot import metadata
continues to use the same paths and UIDs.
