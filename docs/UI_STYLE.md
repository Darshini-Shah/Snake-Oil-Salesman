# Medieval interface

The existing UI uses `res://ui/themes/medieval_theme.tres` and the supplied
**Free Medieval Fantasy UI Pack by Kibyra**. The original extracted directory
was moved to `assets/ui/medieval_fantasy/`, retaining all 208 individual assets,
the original sheets, packaging artwork, and `Readme.txt` (including its license).
No pack files were deleted or recolored. World artwork remains in
`assets/village_top_down/` and was not modified.

## Existing interface inventory

- `scenes/ui/hud.tscn`: currency/goal, day, reputation, inventory summary,
  advance-day button, positive/negative notifications and end-result display.
- `scenes/ui/chat_ui.tscn`: proximity interaction button, NPC identity frame,
  name, trust/suspicion/budget, scrolling conversation, text input, suggested
  scam pitch, send and close buttons.
- `scenes/ui/virtual_joystick.tscn`: touch control, using the existing optional
  base/knob texture properties without modifying its movement/input script.
- `assets/characters/npc.tscn`: world-space interaction prompt and speech bubble.
- `assets/characters/guard.tscn`: alert label.
- `assets/objects/item_chest.tscn`: pickup prompt.
- `assets/objects/village_building.tscn`: building nameplate only. The sprite,
  collision geometry, positioning and building script are unchanged.

This checkout launches directly into `scenes/main.tscn`. There is no main menu,
pause menu, settings screen, credits screen, save/continue button, separate
inventory window, or separate shop screen to migrate. Inventory is a HUD line;
sales/scams are handled in the conversation panel; the ending is a notification.
No new navigation or gameplay systems were introduced to fill those gaps.

## Reuse and asset mapping

The theme supplies `StyleBoxTexture` frames with twelve-pixel nine-slice margins,
preserving corners instead of stretching the whole icon. `UI Icons 2/icon49.png`
is the wooden frame used by panels, buttons, fields and tooltips. Hover, pressed
and disabled states use restrained modulation; keyboard focus uses a thin gold
outline. `Inset` is the compact panel variant and `WorldLabel` is the small
framed label variant. Button/input handlers and unique node names are preserved.

HUD icons from `UI Icons 3`: `icon4` (coins), `icon59` (hourglass), `icon63`
(crown/reputation), and `icon33` (satchel). Trust and suspicion remain clearly
labelled text. The joystick uses round wooden controls `UI Icons 2/icon23` and
`icon24`, with its original radii, touch region and input math.

No font is supplied by this pack. The existing Godot font remains for readable
conversation text, with a shared 16-pixel default and warm parchment colors.
UI roots and world labels explicitly use nearest texture filtering; imported
PNGs use lossless compression and no mipmaps. There is no project-wide change
to rendering, resolution, camera, map or movement settings.

The HUD row wraps using an `HFlowContainer`, with inventory on its own line.
Long inventory lists truncate visually and expose all names in a tooltip.
The dialogue panel anchors to viewport edges, wraps NPC names, and puts social
stats on a separate line. Notification placement follows the actual HUD height.
Designed/reviewed landscape sizes: 1152x648, 960x540 and 640x480. Small physical
windows may still scale with the project's existing canvas stretch settings.

To rebuild the theme after changing its source mapping, run
`python ui/themes/build_theme.py`. The generated `.tres` is the runtime resource;
Python is not needed by the game.

## Validation

Using Godot 4.7.2:

```
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_gameplay_mechanics.gd
godot --headless --path . --script tests/test_ui_presentation.gd
godot --path . --script tests/test_ui_presentation.gd -- --capture
```

The presentation test checks viewport containment, readable dialogue height,
theme loading, existing button/submit connections, suggested-pitch input, long
inventory text and ending notifications. It explicitly tests each logical
viewport size independently of the project's existing window scaling. Captures
go into ignored `.godot/ui_review/`; tests do not write saves.

The import found no parser/resource errors, the gameplay suite passed 62 checks,
and presentation checks passed all three sizes. Rendered HUD, conversation,
inventory and end-result captures were inspected. The environment reported
unrelated certificate-store and editor/shader-cache write errors.

After the user moved Godot into the project root, the final headless and rendered
presentation suites were rerun successfully, including joystick texture checks.
Fresh captures were inspected after adjusting dialogue spacing at 640x480.
All eight changed scene/theme files also passed a static resource/reference
check. Manual review remains useful for button hover/focus feel, Android touch
and soft-keyboard behavior, and unusual aspect ratios on actual target devices.
