"""Rebuild the text Theme resource from the bundled, unmodified Kibyra PNGs."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACK = 'res://assets/ui/medieval_fantasy/'
parts = ['[gd_resource type="Theme" format=3]\n']
for name, number in [('wood', 49), ('inset', 49)]:
    parts.append(f'[ext_resource type="Texture2D" path="{PACK}UI Icons 2/icon{number}.png" id="{name}"]\n')

def style(name, texture, padding, tint=None):
    text = f'[sub_resource type="StyleBoxTexture" id="{name}"]\ntexture = ExtResource("{texture}")\n'
    for edge in ['left', 'top', 'right', 'bottom']:
        text += f'texture_margin_{edge} = 12.0\ncontent_margin_{edge} = {float(padding)}\n'
    if tint:
        text += f'modulate_color = Color({tint})\n'
    parts.append(text)

style('panel', 'inset', 16)
style('compact', 'inset', 8)
style('normal', 'wood', 12)
style('hover', 'wood', 12, '1.18, 1.12, 1.03, 1')
style('pressed', 'wood', 12, '0.75, 0.7, 0.62, 1')
style('disabled', 'wood', 12, '0.6, 0.58, 0.54, 1')
style('input', 'inset', 12)
parts.append('''[sub_resource type="StyleBoxFlat" id="focus"]
bg_color = Color(0, 0, 0, 0)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(1, 0.83, 0.46, 1)

[resource]
default_font_size = 16
Panel/styles/panel = SubResource("panel")
PanelContainer/styles/panel = SubResource("panel")
Inset/base_type = &"PanelContainer"
Inset/styles/panel = SubResource("compact")
WorldLabel/base_type = &"Label"
WorldLabel/styles/normal = SubResource("compact")
WorldLabel/font_sizes/font_size = 12
WorldLabel/colors/font_color = Color(1, 0.9, 0.68, 1)
Label/colors/font_color = Color(0.96, 0.89, 0.74, 1)
Label/colors/font_shadow_color = Color(0.09, 0.06, 0.04, 1)
Label/constants/shadow_offset_y = 1
RichTextLabel/colors/default_color = Color(0.96, 0.89, 0.74, 1)
RichTextLabel/font_sizes/normal_font_size = 16
RichTextLabel/font_sizes/bold_font_size = 16
RichTextLabel/font_sizes/italics_font_size = 16
Button/colors/font_color = Color(1, 0.94, 0.78, 1)
Button/colors/font_hover_color = Color(1, 0.97, 0.85, 1)
Button/colors/font_pressed_color = Color(1, 0.88, 0.6, 1)
Button/colors/font_disabled_color = Color(0.68, 0.63, 0.53, 1)
Button/constants/h_separation = 8
Button/styles/normal = SubResource("normal")
Button/styles/hover = SubResource("hover")
Button/styles/pressed = SubResource("pressed")
Button/styles/disabled = SubResource("disabled")
Button/styles/focus = SubResource("focus")
LineEdit/styles/normal = SubResource("input")
LineEdit/styles/read_only = SubResource("disabled")
LineEdit/styles/focus = SubResource("focus")
LineEdit/colors/font_color = Color(1, 0.94, 0.8, 1)
LineEdit/colors/font_placeholder_color = Color(0.74, 0.68, 0.57, 1)
LineEdit/colors/caret_color = Color(1, 0.83, 0.46, 1)
LineEdit/colors/selection_color = Color(0.43, 0.3, 0.15, 1)
TooltipPanel/styles/panel = SubResource("panel")
TooltipLabel/colors/font_color = Color(1, 0.94, 0.8, 1)
VScrollBar/styles/scroll = SubResource("compact")
VScrollBar/styles/grabber = SubResource("normal")
VScrollBar/styles/grabber_highlight = SubResource("hover")
VScrollBar/styles/grabber_pressed = SubResource("pressed")
HScrollBar/styles/scroll = SubResource("compact")
HScrollBar/styles/grabber = SubResource("normal")
HScrollBar/styles/grabber_highlight = SubResource("hover")
HScrollBar/styles/grabber_pressed = SubResource("pressed")
''')
(ROOT / 'ui/themes/medieval_theme.tres').write_text('\n'.join(parts), encoding='utf-8')
