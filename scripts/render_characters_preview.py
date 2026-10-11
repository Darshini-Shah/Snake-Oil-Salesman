import json, os, re
from PIL import Image, ImageDraw, ImageFont

with open('assets/maps/clean_map_cells.json') as f:
    map_data = json.load(f)

with open('assets/maps/world_environment_data.json') as f:
    env_data = json.load(f)

import sys
sys.path.append('scripts')
from build_full_world_environment import BUILDINGS

# Parse CHARACTERS_CONFIG from scripts/build_world_characters.gd
characters_list = []
with open('scripts/build_world_characters.gd') as f:
    gd_text = f.read()

pattern = r'\["([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*([0-9.]+),\s*([0-9.]+),\s*"([^"]+)",\s*(true|false)'
for m in re.finditer(pattern, gd_text):
    node_name, display_name, title, tex_path, px, py, facing, is_guard = m.groups()
    characters_list.append({
        'node_name': node_name,
        'display_name': display_name,
        'title': title,
        'tex_path': tex_path.replace('res://', ''),
        'x': float(px),
        'y': float(py),
        'facing': facing,
        'is_guard': is_guard == 'true'
    })

print(f"Parsed {len(characters_list)} characters from configuration.")

OCEAN_COLOR = (42, 86, 142, 255)
GRASS_COLOR = (146, 194, 76, 255)
SAND_COLOR = (230, 203, 148, 255)
CLIFF_COLOR = (156, 114, 82, 255)
PATH_COLOR = (226, 196, 140, 255)
PLAZA_COLOR = (185, 180, 175, 255)
BRIDGE_COLOR = (138, 96, 62, 255)

canvas = Image.new('RGBA', (4096, 2816), OCEAN_COLOR)
draw = ImageDraw.Draw(canvas)

# 1. Ground tiles
for c in map_data['ground']:
    gx, gy, src = c[0] * 16, c[1] * 16, c[2]
    col = GRASS_COLOR if src == 1 else SAND_COLOR if src == 5 else CLIFF_COLOR if src == 4 else OCEAN_COLOR
    draw.rectangle([gx, gy, gx+16, gy+16], fill=col)

# 2. Paths
for c in map_data['paths']:
    px, py, src = c[0] * 16, c[1] * 16, c[2]
    col = PLAZA_COLOR if src == 3 else BRIDGE_COLOR if src == 8 else PATH_COLOR
    draw.rectangle([px, py, px+16, py+16], fill=col)

tex_cache = {}
def get_tex(path, scale):
    key = (path, scale)
    if key not in tex_cache:
        real_p = path.replace('res://', '')
        if os.path.exists(real_p):
            im = Image.open(real_p).convert('RGBA')
            nw, nh = int(im.size[0] * scale), int(im.size[1] * scale)
            tex_cache[key] = im.resize((nw, nh), Image.Resampling.NEAREST)
        else:
            tex_cache[key] = None
    return tex_cache[key]

# Water lilies first
for w in env_data['water_lilies']:
    name, tex_path, x, y, scale = w
    im = get_tex(tex_path, scale)
    if im:
        canvas.paste(im, (int(x - im.size[0]/2), int(y - im.size[1]/2)), im)

# Collect y-sortable renderables: (y_sort, x, y, im)
renderables = []

for d in env_data['decors']:
    name, tex_path, x, y, scale = d
    im = get_tex(tex_path, scale)
    if im: renderables.append((y, x, y, im))

for b in env_data['bushes']:
    name, tex_path, x, y, scale = b
    im = get_tex(tex_path, scale)
    if im: renderables.append((y + 10, x, y, im))

for f in env_data['flowers']:
    name, tex_path, x, y, scale = f
    im = get_tex(tex_path, scale)
    if im: renderables.append((y, x, y, im))

for s in env_data['solids']:
    name, tex_path, x, y, scale, fp_w, fp_h, off_y = s
    im = get_tex(tex_path, scale)
    if im: renderables.append((y + off_y, x, y, im))

# Trees
for t in env_data['trees']:
    name, tex_path, x, y, scale, rad, off_y = t
    im = get_tex(tex_path, scale)
    if im: renderables.append((y + off_y, x, y, im))

# Buildings
for b in BUILDINGS:
    name, tex_path, bx, by, bw, bh, fp_w, fp_h, off_y, sf = b
    im = get_tex(tex_path, sf)
    if im: renderables.append((by + off_y, bx, by, im))

# Character sprites
# Direction rows: down=0, left=1, right=2, up=3. Idle frame is middle column (col 1: x from 32 to 64)
facing_to_row = {'down': 0, 'left': 1, 'right': 2, 'up': 3}

for ch in characters_list:
    cp = ch['tex_path']
    if os.path.exists(cp):
        c_sheet = Image.open(cp).convert('RGBA')
        row = facing_to_row.get(ch['facing'], 0)
        fw, fh = c_sheet.size[0] // 3, c_sheet.size[1] // 4
        # Middle column frame
        frame = c_sheet.crop((fw, row * fh, fw * 2, (row + 1) * fh))
        # Add character to y-sort: character stands on ground at ch['y']
        renderables.append((ch['y'], ch['x'], ch['y'], frame))

# Player character
p_sheet = Image.open('assets/characters/rpg_pack/player_salesman.png').convert('RGBA')
player_front = p_sheet.crop((32, 0, 64, 32))
renderables.append((2560, 2048, 2560, player_front))

# Sort by y_sort
renderables.sort(key=lambda r: r[0])

for y_sort, x, y, im in renderables:
    px = int(x - im.size[0] / 2)
    py = int(y - im.size[1] / 2)
    canvas.paste(im, (px, py), im)

# Save regional crops
media_dir = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage'
artifact_dir = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263'
os.makedirs(media_dir, exist_ok=True)

crops = {
    'char_preview_plaza.png': (1700, 650, 2650, 1650),
    'char_preview_citadel.png': (2900, 300, 3700, 950),
    'char_preview_west_village.png': (500, 750, 1650, 2150),
    'char_preview_farmlands.png': (2800, 950, 3750, 1950),
    'char_preview_academy_smugglers.png': (400, 150, 2400, 800),
    'char_preview_south_gates.png': (1750, 2150, 2350, 2650),
    'char_preview_mine.png': (2950, 1950, 3700, 2450),
}

for fname, box in crops.items():
    cropped = canvas.crop(box)
    cropped.save(os.path.join(media_dir, fname))
    cropped.save(os.path.join(artifact_dir, fname))
    print(f"Saved {fname} ({cropped.size[0]}x{cropped.size[1]})")

# Full overview
overview = canvas.resize((1024, 704), Image.Resampling.BILINEAR)
overview.save(os.path.join(media_dir, 'char_preview_island_overview.png'))
overview.save(os.path.join(artifact_dir, 'char_preview_island_overview.png'))
print("Saved char_preview_island_overview.png")

print("All character preview images generated successfully!")
