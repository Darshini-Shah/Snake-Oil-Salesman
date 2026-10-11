import json, os
from PIL import Image, ImageDraw

with open('assets/maps/clean_map_cells.json') as f:
    map_data = json.load(f)

with open('assets/maps/world_environment_data.json') as f:
    env_data = json.load(f)

from build_full_world_environment import BUILDINGS

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

# Render water lilies first onto water bodies
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

# Sort by y_sort
renderables.sort(key=lambda r: r[0])

for y_sort, x, y, im in renderables:
    px = int(x - im.size[0] / 2)
    py = int(y - im.size[1] / 2)
    canvas.paste(im, (px, py), im)

# Player
p_sheet = Image.open('assets/characters/rpg_pack/player_salesman.png')
player_front = p_sheet.crop((32, 0, 64, 32))
canvas.paste(player_front, (830, 1136), player_front)
canvas.paste(player_front, (1070, 1010), player_front)

# Crop West Village
crop_wv = canvas.crop((500, 750, 1600, 1550))
crop_wv.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/flora_preview_west_village.png')

# Crop Plaza
crop_pz = canvas.crop((1700, 650, 2650, 1650))
crop_pz.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/flora_preview_plaza.png')

# Crop Farmlands
crop_cf = canvas.crop((2800, 250, 3850, 1850))
crop_cf.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/flora_preview_farmlands.png')

# Crop South Waterfall & Arrival Bridge
crop_sb = canvas.crop((1400, 1800, 2400, 2750))
crop_sb.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/flora_preview_south_waterfall.png')

# Crop Citadel Forest
crop_citadel = canvas.crop((2800, 150, 3850, 850))
crop_citadel.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/flora_preview_citadel_forest.png')

# Crop Mine & Wetlands
crop_mine = canvas.crop((2600, 1550, 3750, 2450))
crop_mine.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/flora_preview_mine_wetlands.png')

# Crop North Academy & Mountain
crop_north = canvas.crop((1400, 100, 2600, 700))
crop_north.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/flora_preview_north_academy.png')

# Crop User Screenshot Area (South Waterfall Grove & Footbridge 1)
crop_user = canvas.crop((1300, 1850, 2150, 2350))
crop_user.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/user_screenshot_region_fixed.png')
crop_user.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/user_screenshot_region_fixed.png')

# Overview
overview = canvas.resize((1024, 704), Image.Resampling.BILINEAR)
overview.save('/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/flora_preview_island_overview.png')

# Also copy all previews directly to artifacts folder
for f in ['flora_preview_island_overview.png', 'flora_preview_plaza.png', 'flora_preview_west_village.png', 'flora_preview_farmlands.png', 'flora_preview_citadel_forest.png', 'flora_preview_south_waterfall.png', 'flora_preview_north_academy.png', 'flora_preview_mine_wetlands.png']:
    sp = f'/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/{f}'
    dp = f'/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/{f}'
    if os.path.exists(sp):
        Image.open(sp).save(dp)

print("All fixed flora preview images rendered!")
