import json, os, re, random
from PIL import Image, ImageDraw

with open('assets/maps/clean_map_cells.json') as f:
    map_data = json.load(f)

with open('assets/maps/world_environment_data.json') as f:
    env_data = json.load(f)

import sys
sys.path.append('scripts')
from build_full_world_environment import BUILDINGS

# 1. Parse Characters
characters_list = []
with open('scripts/build_world_characters.gd') as f:
    gd_text = f.read()

pattern = r'\["([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*([0-9.]+),\s*([0-9.]+),\s*"([^"]+)",\s*(true|false)'
for m in re.finditer(pattern, gd_text):
    node_name, display_name, title, tex_path, px, py, facing, is_guard = m.groups()
    characters_list.append({
        'name': node_name,
        'tex_path': tex_path.replace('res://', ''),
        'x': float(px),
        'y': float(py),
        'facing': facing
    })

# 2. Parse Animals
animals_list = []
with open('scripts/build_world_animals_and_particles.gd') as f:
    anim_gd_text = f.read()

anim_pattern = r'\["([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*([0-9]+),\s*([0-9]+),\s*([0-9.]+),\s*([0-9.]+),\s*"([^"]+)"'
for m in re.finditer(anim_pattern, anim_gd_text):
    an_name, an_type, tex_path, hf, vf, px, py, beh = m.groups()
    animals_list.append({
        'name': an_name,
        'type': an_type,
        'tex_path': tex_path.replace('res://', ''),
        'hf': int(hf),
        'vf': int(vf),
        'x': float(px),
        'y': float(py),
        'beh': beh
    })

print(f"Loaded {len(characters_list)} characters and {len(animals_list)} animals.")

OCEAN_COLOR = (42, 86, 142, 255)
GRASS_COLOR = (146, 194, 76, 255)
SAND_COLOR = (230, 203, 148, 255)
CLIFF_COLOR = (156, 114, 82, 255)
PATH_COLOR = (226, 196, 140, 255)
PLAZA_COLOR = (185, 180, 175, 255)
BRIDGE_COLOR = (138, 96, 62, 255)

canvas = Image.new('RGBA', (4096, 2816), OCEAN_COLOR)
draw = ImageDraw.Draw(canvas)

# Ground tiles
for c in map_data['ground']:
    gx, gy, src = c[0] * 16, c[1] * 16, c[2]
    col = GRASS_COLOR if src == 1 else SAND_COLOR if src == 5 else CLIFF_COLOR if src == 4 else OCEAN_COLOR
    draw.rectangle([gx, gy, gx+16, gy+16], fill=col)

# Paths
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

# Characters
facing_to_row = {'down': 0, 'left': 1, 'right': 2, 'up': 3}
for ch in characters_list:
    cp = ch['tex_path']
    if os.path.exists(cp):
        c_sheet = Image.open(cp).convert('RGBA')
        row = facing_to_row.get(ch['facing'], 0)
        fw, fh = c_sheet.size[0] // 3, c_sheet.size[1] // 4
        frame = c_sheet.crop((fw, row * fh, fw * 2, (row + 1) * fh))
        renderables.append((ch['y'], ch['x'], ch['y'], frame))

# Animals
for an in animals_list:
    ap = an['tex_path']
    if os.path.exists(ap):
        a_sheet = Image.open(ap).convert('RGBA')
        fw = a_sheet.size[0] // an['hf']
        fh = a_sheet.size[1] // an['vf']
        # Take frame 0 or 1
        frame = a_sheet.crop((0, 0, fw, fh))
        renderables.append((an['y'], an['x'], an['y'], frame))

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

# --- OVERLAY ATMOSPHERIC PARTICLES ---
overlay = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
o_draw = ImageDraw.Draw(overlay)

# 1. Smoke Puffs (Bakery, Forge, Tavern, Farmhouse, Shore Cabin, Campfire)
smoke_sources = [
    (1090, 890, (230, 230, 240, 180), 8), # Bakery
    (1115, 1310, (90, 90, 100, 190), 9), # Forge
    (1100, 1870, (220, 220, 230, 170), 8), # Tavern
    (3080, 1130, (225, 225, 235, 175), 8), # Farmhouse
    (3550, 1750, (220, 225, 230, 160), 7), # Shore cabin
    (1090, 520, (200, 200, 210, 180), 6), # Campfire
]

for sx, sy, col, count in smoke_sources:
    for i in range(count):
        # Drift up and slightly right
        dist = i * 6 + random.randint(-2, 2)
        px = sx + random.randint(-4, 4) + int(dist * 0.25)
        py = sy - dist - 4
        rad = 3 + int(i * 1.1)
        alpha = max(20, col[3] - i * 22)
        o_draw.ellipse([px - rad, py - rad, px + rad, py + rad], fill=(col[0], col[1], col[2], alpha))

# Forge sparks
for _ in range(8):
    spx = 1115 + random.randint(-6, 6)
    spy = 1315 - random.randint(2, 16)
    o_draw.ellipse([spx-1, spy-1, spx+1, spy+1], fill=(255, 180, 40, 220))

# Campfire embers
for _ in range(6):
    epx = 1090 + random.randint(-5, 5)
    epy = 520 - random.randint(3, 14)
    o_draw.ellipse([epx-1, epy-1, epx+1, epy+1], fill=(255, 120, 20, 220))

# 2. Central Plaza Fountain Water Spray
fx, fy = 2056, 1120
for _ in range(25):
    dx = random.randint(-12, 12)
    dy = -random.randint(6, 24)
    rad = random.randint(1, 3)
    o_draw.ellipse([fx + dx - rad, fy + dy - rad, fx + dx + rad, fy + dy + rad], fill=(200, 235, 255, random.randint(140, 220)))

# 3. Royal Citadel Cherry Blossom Petals
random.seed(42)
for _ in range(45):
    cpx = random.randint(2950, 3650)
    cpy = random.randint(320, 720)
    pw, ph = random.randint(2, 4), random.randint(2, 3)
    o_draw.ellipse([cpx, cpy, cpx + pw, cpy + ph], fill=(255, 185, 210, random.randint(150, 220)))

# 4. Farmlands Golden Pollen Motes
for _ in range(40):
    gx = random.randint(3050, 3650)
    gy = random.randint(1200, 1600)
    o_draw.ellipse([gx, gy, gx+2, gy+2], fill=(255, 230, 100, random.randint(140, 210)))

# 5. Southern Waterfall Mist
for _ in range(35):
    wx = 1740 + random.randint(-50, 50)
    wy = 2300 - random.randint(0, 35)
    rad = random.randint(4, 9)
    o_draw.ellipse([wx - rad, wy - rad, wx + rad, wy + rad], fill=(240, 250, 255, random.randint(70, 130)))

# 6. Watermill Splashes
for _ in range(16):
    mx = 3265 + random.randint(-10, 10)
    my = 1715 + random.randint(-8, 8)
    o_draw.ellipse([mx-1, my-1, mx+2, my+2], fill=(220, 245, 255, 200))

# Composite overlay
canvas = Image.alpha_composite(canvas, overlay)

# Save regional crops
media_dir = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage'
artifact_dir = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263'
os.makedirs(media_dir, exist_ok=True)

crops = {
    'animals_preview_farmlands.png': (2900, 950, 3750, 1850),
    'animals_preview_west_village.png': (900, 850, 1750, 2050),
    'animals_preview_citadel.png': (2900, 300, 3700, 950),
    'animals_preview_plaza.png': (1750, 750, 2550, 1550),
    'animals_preview_waterfall.png': (1400, 1800, 2400, 2700),
    'animals_preview_academy_forest.png': (950, 250, 2250, 750),
}

for fname, box in crops.items():
    cropped = canvas.crop(box)
    cropped.save(os.path.join(media_dir, fname))
    cropped.save(os.path.join(artifact_dir, fname))
    print(f"Saved {fname} ({cropped.size[0]}x{cropped.size[1]})")

# Full overview
overview = canvas.resize((1024, 704), Image.Resampling.BILINEAR)
overview.save(os.path.join(media_dir, 'animals_preview_island_overview.png'))
overview.save(os.path.join(artifact_dir, 'animals_preview_island_overview.png'))
print("Saved animals_preview_island_overview.png")

print("All animals and particle preview images rendered successfully!")
