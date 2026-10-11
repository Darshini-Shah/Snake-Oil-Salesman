import json
import math
from PIL import Image

# 1. Load authentic sheets
sheet = Image.open('assets/terrain/terrain_tileset_sheet.png').convert('RGBA')
bridge_sheet = Image.open('assets/village_top_down/TILESET VILLAGE TOP DOWN/BRIDGE - DAY.png').convert('RGBA')

W_TILES = 256
H_TILES = 176

# Tile crops
t_water = sheet.crop((13*16, 6*16, 14*16, 7*16))
t_grass = sheet.crop((3*16, 3*16, 4*16, 4*16))
t_dgrass = sheet.crop((11*16, 3*16, 12*16, 4*16))
t_sand = sheet.crop((7*16, 3*16, 8*16, 4*16))
t_wood_wall = sheet.crop((6*16, 10*16, 7*16, 11*16))
t_wood_vert = sheet.crop((7*16, 8*16, 8*16, 9*16))
t_wcliff_south = sheet.crop((11*16, 10*16, 12*16, 11*16))

# Load original land mask
with open('assets/maps/clean_map_cells.json') as f:
    orig_data = json.load(f)

raw_land = set()
for c in orig_data['ground']:
    tx, ty, sid, ax, ay = c
    if not (ax == 13 and ay == 6):
        raw_land.add((tx, ty))

# Define clean island landmask:
# Main island: y <= 147
# Southern arrival pier: y >= 172, x: 124..132
# Everything else for y > 147 is deep ocean water
island_land = set()
for (tx, ty) in raw_land:
    if ty <= 147:
        island_land.add((tx, ty))
    elif ty >= 172 and 124 <= tx <= 132:
        island_land.add((tx, ty))

def is_land(tx, ty):
    return (tx, ty) in island_land

# True deep ocean water outside island
ocean_water = set()
for y in range(H_TILES):
    for x in range(W_TILES):
        if not is_land(x, y):
            ocean_water.add((x, y))

def touches_ocean(tx, ty):
    # Only checks external ocean, not inland water
    for ox in (-1, 0, 1):
        for oy in (-1, 0, 1):
            if ox == 0 and oy == 0: continue
            nx, ny = tx + ox, ty + oy
            if (nx, ny) in ocean_water and (ny > 147 or nx <= 18 or nx >= 242 or ny <= 14):
                return True
    return False

# Autotile resolver for standard 5x5 blob centered at (cx, cy)
def resolve_autotile(tx, ty, shape_set, cx, cy):
    n = (tx, ty - 1) in shape_set
    s = (tx, ty + 1) in shape_set
    w = (tx - 1, ty) in shape_set
    e = (tx + 1, ty) in shape_set
    nw = (tx - 1, ty - 1) in shape_set
    ne = (tx + 1, ty - 1) in shape_set
    sw = (tx - 1, ty + 1) in shape_set
    se = (tx + 1, ty + 1) in shape_set
    
    # Outer corners
    if not n and not w: return (cx - 1, cy - 2)
    elif not n and not e: return (cx + 1, cy - 2)
    elif not s and not w: return (cx - 1, cy + 2)
    elif not s and not e: return (cx + 1, cy + 2)
    # Straight edges
    elif not n: return (cx, cy - 2)
    elif not s: return (cx, cy + 2)
    elif not w: return (cx - 2, cy)
    elif not e: return (cx + 2, cy)
    # Inner corners
    elif not nw: return (cx - 1, cy - 1)
    elif not ne: return (cx + 1, cy - 1)
    elif not sw: return (cx - 1, cy + 1)
    elif not se: return (cx + 1, cy + 1)
    # Center
    else: return (cx, cy)

print("1. Sculpting island features...")

# --- A. INLAND RIVERS & WATERFALLS ---
inland_water = set()

def add_river_ribbon(pts, width=1):
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]
        x1, y1 = pts[i+1]
        dist = math.hypot(x1 - x0, y1 - y0)
        steps = max(1, int(dist * 2))
        for s in range(steps + 1):
            t = s / steps
            px = x0 + (x1 - x0) * t
            py = y0 + (y1 - y0) * t
            for ox in range(-width, width + 1):
                for oy in range(-width, width + 1):
                    if math.hypot(ox, oy) <= width:
                        pt = (int(round(px + ox)), int(round(py + oy)))
                        if is_land(pt[0], pt[1]) and pt[1] <= 147:
                            inland_water.add(pt)

# West River (flows to waterfall at x=119..121, y=147)
add_river_ribbon([
    (96, 92), (98, 105), (102, 118), (108, 128), (114, 138), (120, 147)
], width=1)

# East River (flows to waterfall at x=135..137, y=147)
add_river_ribbon([
    (160, 96), (156, 110), (150, 122), (144, 134), (136, 147)
], width=1)

# Northwest Creek
add_river_ribbon([
    (54, 52), (50, 60), (46, 68), (40, 72), (32, 75)
], width=1)

# Scenic Ponds
def add_pond(cx, cy, rx, ry):
    for tx in range(cx - rx - 1, cx + rx + 2):
        for ty in range(cy - ry - 1, cy + ry + 2):
            if is_land(tx, ty) and ty <= 147:
                if ((tx - cx)/rx)**2 + ((ty - cy)/ry)**2 <= 1.0:
                    inland_water.add((tx, ty))

add_pond(98, 104, 5, 3)   # West scenic pond
add_pond(162, 74, 6, 4)   # East lake
add_pond(178, 96, 5, 3)   # Farmland pond

# River bridges
river_bridges = set()
for tx in range(106, 111):
    for ty in range(125, 128):
        river_bridges.add((tx, ty))
        inland_water.discard((tx, ty))

for tx in range(145, 150):
    for ty in range(125, 128):
        river_bridges.add((tx, ty))
        inland_water.discard((tx, ty))

for tx in range(44, 48):
    for ty in range(67, 70):
        river_bridges.add((tx, ty))
        inland_water.discard((tx, ty))

# --- B. SANDY BEACHES & FARMLANDS ---
sandy_beaches = set()

# Southwest curved beach bay
for tx in range(24, 88):
    for ty in range(132, 148):
        if is_land(tx, ty) and (tx, ty) not in inland_water:
            if touches_ocean(tx, ty):
                sandy_beaches.add((tx, ty))

# Southeast curved beach bay
for tx in range(166, 198):
    for ty in range(134, 148):
        if is_land(tx, ty) and (tx, ty) not in inland_water:
            if touches_ocean(tx, ty):
                sandy_beaches.add((tx, ty))

# East windmill harbor beach
for tx in range(232, 252):
    for ty in range(64, 98):
        if is_land(tx, ty):
            if touches_ocean(tx, ty):
                sandy_beaches.add((tx, ty))

# Farmland tilled soil
farmland_soil = set()
for tx in range(196, 226):
    for ty in range(68, 92):
        if is_land(tx, ty) and (tx, ty) not in inland_water:
            farmland_soil.add((tx, ty))

# --- C. CONTOURED ELEVATION TERRACES ---
def make_contour(cx, cy, rx, ry, seed=1):
    contour = set()
    for tx in range(cx - rx - 3, cx + rx + 4):
        for ty in range(cy - ry - 3, cy + ry + 4):
            if is_land(tx, ty) and ty <= 147 and (tx, ty) not in inland_water and (tx, ty) not in sandy_beaches:
                nx = (tx - cx) / rx
                ny = (ty - cy) / ry
                dist = nx*nx + ny*ny
                angle = math.atan2(ny, nx)
                wobble = 0.12 * math.sin(angle * 3 + seed) + 0.08 * math.cos(angle * 5 + seed)
                if dist <= (1.0 + wobble):
                    contour.add((tx, ty))
    return contour

# 1. Northwest Mountain (3 Tiers)
nw_tier1 = make_contour(36, 30, 18, 14, seed=1) # Foothills
for tx in range(34, 39):
    for ty in range(41, 46): nw_tier1.discard((tx, ty)) # Stairs cut-out

nw_tier2 = make_contour(35, 26, 11, 9, seed=2)  # Cave Terrace
for tx in range(33, 38):
    for ty in range(31, 35): nw_tier2.discard((tx, ty)) # Cave opening

nw_tier3 = make_contour(34, 23, 7, 5, seed=3)   # Summit Peak

# 2. Northern Scholar Summit
scholar_tier1 = make_contour(128, 16, 20, 9, seed=4)
for tx in range(126, 131):
    for ty in range(23, 27): scholar_tier1.discard((tx, ty)) # Grand stairs

# 3. Northeast Royal Citadel Plateau
citadel_tier1 = make_contour(208, 32, 28, 18, seed=5)
for tx in range(178, 186):
    for ty in range(46, 52): citadel_tier1.discard((tx, ty)) # Royal stairs

# 4. Southeast Deep Stone Mine (3 Tiers)
mine_tier1 = make_contour(208, 124, 28, 15, seed=6) # Lower quarry
for tx in range(186, 194):
    for ty in range(106, 114): mine_tier1.discard((tx, ty)) # Trail access

mine_tier2 = make_contour(214, 126, 16, 10, seed=7) # Upper cave terrace
for tx in range(206, 212):
    for ty in range(116, 122): mine_tier2.discard((tx, ty))

mine_tier3 = make_contour(222, 128, 10, 7, seed=8)  # High pine ridge

# --- D. PATHWAYS & TOWN PLAZA ---
paths_network = set()

def add_path_corridor(pts, width=2):
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]
        x1, y1 = pts[i+1]
        dist = math.hypot(x1 - x0, y1 - y0)
        steps = max(1, int(dist * 2))
        for s in range(steps + 1):
            t = s / steps
            px = x0 + (x1 - x0) * t
            py = y0 + (y1 - y0) * t
            for ox in range(-width, width + 1):
                for oy in range(-width, width + 1):
                    if math.hypot(ox, oy) <= width:
                        pt = (int(round(px + ox)), int(round(py + oy)))
                        if is_land(pt[0], pt[1]) and pt[1] <= 147 and pt not in inland_water:
                            paths_network.add(pt)

# Main Grand Avenue
add_path_corridor([(128, 147), (128, 115), (128, 88)], width=2)

# Town Plaza Central Square
for tx in range(116, 141):
    for ty in range(74, 91):
        if is_land(tx, ty):
            paths_network.add((tx, ty))

# Radial Arteries
add_path_corridor([(116, 82), (85, 82), (55, 82), (24, 82)], width=2) # West to Lighthouse
add_path_corridor([(128, 74), (128, 48), (128, 25)], width=2)          # North to Scholar Summit
add_path_corridor([(140, 82), (165, 82), (180, 82), (184, 65), (184, 50)], width=2) # East to Citadel
add_path_corridor([(180, 82), (190, 98), (196, 110), (208, 118)], width=2)          # South to Mines
add_path_corridor([(85, 82), (85, 112), (105, 112), (126, 112)], width=1)           # West Village loop
add_path_corridor([(85, 82), (85, 55), (105, 55), (126, 55)], width=1)
add_path_corridor([(55, 82), (48, 65), (36, 48), (35, 34)], width=1)                # NW Mountain trail

paths_network |= river_bridges

# --- E. DARK GRASS FOREST GROVES ---
dark_grass = set()
def add_forest_grove(cx, cy, rx, ry, seed=1):
    for tx in range(cx - rx - 2, cx + rx + 3):
        for ty in range(cy - ry - 2, cy + ry + 3):
            if is_land(tx, ty) and ty <= 147 and (tx, ty) not in paths_network and (tx, ty) not in inland_water and (tx, ty) not in sandy_beaches:
                nx = (tx - cx) / rx
                ny = (ty - cy) / ry
                dist = nx*nx + ny*ny
                angle = math.atan2(ny, nx)
                wobble = 0.18 * math.sin(angle * 4 + seed)
                if dist <= (1.0 + wobble):
                    dark_grass.add((tx, ty))

add_forest_grove(36, 26, 12, 8, 1)    # Mountain woods
add_forest_grove(78, 38, 16, 10, 2)   # NW forest
add_forest_grove(164, 30, 14, 10, 3)  # North pine woods
add_forest_grove(210, 32, 18, 10, 4)  # Citadel forest grove
add_forest_grove(212, 65, 12, 8, 5)   # Castle base grove
add_forest_grove(166, 75, 10, 8, 6)   # Farmland woods
add_forest_grove(112, 128, 10, 8, 7)  # SW river woods
add_forest_grove(144, 128, 10, 8, 8)  # SE river woods
add_forest_grove(206, 128, 16, 10, 9) # Mine pine woods
add_forest_grove(72, 98, 12, 8, 10)   # Village orchard woods
add_forest_grove(54, 118, 12, 8, 11)  # SW coastal woods

dark_grass |= nw_tier3
dark_grass |= mine_tier3

print("2. Assembling pixel-perfect layers...")

# 1. Ground Layer
ground_cells = []
for ty in range(H_TILES):
    for tx in range(W_TILES):
        if not is_land(tx, ty) or (tx, ty) in inland_water:
            ground_cells.append([tx, ty, 0, 13, 6])
        elif (tx, ty) in sandy_beaches or (tx, ty) in farmland_soil:
            ground_cells.append([tx, ty, 0, 7, 3])
        elif (tx, ty) in dark_grass:
            ax, ay = resolve_autotile(tx, ty, dark_grass, 11, 3)
            ground_cells.append([tx, ty, 0, ax, ay])
        else:
            ground_cells.append([tx, ty, 0, 3, 3])

# 2. Paths Layer
paths_cells = []
# Southern Wooden Bridge: width 5 (cols 126..130), length y: 148..175
for ty in range(148, 176):
    for tx in range(126, 131):
        col_in_bridge = tx - 126
        bx = 0 if col_in_bridge == 0 else (5 if col_in_bridge == 4 else 2)
        by = (ty - 148) % 3
        paths_cells.append([tx, ty, 8, bx, by])

# Golden dirt roads & town plaza
for (tx, ty) in paths_network:
    if (tx, ty) not in river_bridges and (tx, ty) not in inland_water:
        paths_cells.append([tx, ty, 0, 7, 3])
    elif (tx, ty) in river_bridges:
        paths_cells.append([tx, ty, 8, 2, 1])

# Fill Mine Tier 1 floor with golden quarry sand on paths layer
for (tx, ty) in mine_tier1:
    if (tx, ty) not in mine_tier2 and (tx, ty) not in paths_network:
        paths_cells.append([tx, ty, 0, 7, 3])

# 3. Cliffs Layer
cliff_dict = {}

# A. Coastal Water Cliffs with foam along rocky coasts (strictly on outer sea perimeter)
for ty in range(10, 148):
    for tx in range(10, 246):
        if (tx, ty) in island_land and (tx, ty) not in sandy_beaches:
            if touches_ocean(tx, ty):
                ax, ay = resolve_autotile(tx, ty, island_land, 11, 8)
                if (ax, ay) != (11, 8):
                    cliff_dict[(tx, ty)] = (0, ax, ay)

# Straight south coast water cliff along y = 147
for tx in range(20, 236):
    if (tx, 147) in island_land and (tx, 147) not in sandy_beaches:
        if 126 <= tx <= 130: continue # bridge
        if 119 <= tx <= 121: continue # west waterfall
        if 135 <= tx <= 137: continue # east waterfall
        cliff_dict[(tx, 147)] = (0, 11, 10)

# Waterfalls beside south bridge
for tx in (119, 120, 121): cliff_dict[(tx, 147)] = (0, 11, 10)
for tx in (135, 136, 137): cliff_dict[(tx, 147)] = (0, 11, 10)

# B. Elevated Land Plateaus & Stepped Terraces
def place_terrace_cliffs(terrace_set):
    for (tx, ty) in terrace_set:
        ax, ay = resolve_autotile(tx, ty, terrace_set, 3, 8)
        if (ax, ay) != (3, 8):
            cliff_dict[(tx, ty)] = (0, ax, ay)

place_terrace_cliffs(nw_tier1)
place_terrace_cliffs(nw_tier2)
place_terrace_cliffs(nw_tier3)

place_terrace_cliffs(scholar_tier1)
place_terrace_cliffs(citadel_tier1)

place_terrace_cliffs(mine_tier1)
# Wooden retaining walls on mine lower terrace
for tx in range(188, 202):
    cliff_dict[(tx, 118)] = (0, 6, 10)
for ty in range(112, 118):
    cliff_dict[(188, ty)] = (0, 7, 8)

place_terrace_cliffs(mine_tier2)
place_terrace_cliffs(mine_tier3)

cliff_cells = []
for (tx, ty), (sid, ax, ay) in cliff_dict.items():
    cliff_cells.append([tx, ty, sid, ax, ay])

# --- C. COLLIDERS (WATERTIGHT NON-OVERLAPPING BARRIERS) ---
coast_colliders = [
    # Top ocean barrier (above island)
    [0, 0, 4096, 160],
    # Left ocean barrier (west of island)
    [0, 160, 240, 2400],
    # Right ocean barrier (east of island)
    [3856, 160, 240, 2400],
    # Bottom-left ocean barrier (south-west of bridge)
    [0, 2368, 2016, 448],
    # Bottom-right ocean barrier (south-east of bridge)
    [2096, 2368, 2000, 448],
    # West ocean channel flanking bridge
    [1920, 2368, 96, 448],
    # East ocean channel flanking bridge
    [2096, 2368, 96, 448]
]

water_colliders = [
    # West scenic pond
    [1536, 1632, 128, 64],
    # East lake
    [2560, 1152, 128, 80],
    # Farmland pond
    [2816, 1504, 96, 64]
]

# Save clean_map_cells.json
map_data = {
    "ground": ground_cells,
    "cliffs": cliff_cells,
    "paths": paths_cells,
    "coast_colliders": coast_colliders,
    "water_colliders": water_colliders
}

with open('assets/maps/clean_map_cells.json', 'w') as f:
    json.dump(map_data, f)

print(f"Saved clean_map_cells.json: {len(ground_cells)} ground, {len(cliff_cells)} cliffs, {len(paths_cells)} paths.")

# --- 4. RENDER VISUAL PREVIEWS WITH SOLID COMPOSITING ---
canvas = Image.new('RGBA', (W_TILES * 16, H_TILES * 16), (36, 159, 222, 255))

# 1. Ground Layer
for c in ground_cells:
    tx, ty, sid, ax, ay = c
    px, py = tx * 16, ty * 16
    if ax == 13 and ay == 6:
        canvas.paste(t_water, (px, py))
    elif ax == 7 and ay == 3:
        canvas.paste(t_sand, (px, py))
    elif ax == 3 and ay == 3:
        canvas.paste(t_grass, (px, py))
    else:
        bg = t_grass.copy()
        dg = sheet.crop((ax * 16, ay * 16, (ax + 1) * 16, (ay + 1) * 16))
        bg.paste(dg, (0, 0), dg)
        canvas.paste(bg, (px, py))

# 2. Paths Layer
for c in paths_cells:
    tx, ty, sid, ax, ay = c
    px, py = tx * 16, ty * 16
    if sid == 8:
        patch = bridge_sheet.crop((ax * 16, ay * 16, (ax + 1) * 16, (ay + 1) * 16))
        canvas.paste(patch, (px, py), patch)
    else:
        tile = sheet.crop((ax * 16, ay * 16, (ax + 1) * 16, (ay + 1) * 16))
        canvas.paste(tile, (px, py), tile)

# 3. Cliffs Layer
for c in cliff_cells:
    tx, ty, sid, ax, ay = c
    px, py = tx * 16, ty * 16
    tile = sheet.crop((ax * 16, ay * 16, (ax + 1) * 16, (ay + 1) * 16))
    canvas.paste(tile, (px, py), tile)

# 4. Player at spawn
player_sheet = Image.open('assets/characters/rpg_pack/player_salesman.png').convert('RGBA')
player_sprite = player_sheet.crop((32, 0, 64, 32))
canvas.paste(player_sprite, (2048 - 16, 2560 - 16), player_sprite)

# Overview
overview = canvas.resize((1024, 704), Image.Resampling.BILINEAR)
out_overview = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/island_masterpiece_overview.png'
overview.save(out_overview)

# Player zoom (arrival pier)
zoom_crop = canvas.crop((1587, 2298, 2509, 2816))
out_zoom = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/island_masterpiece_player_zoom.png'
zoom_crop.resize((1152, 648), Image.Resampling.NEAREST).save(out_zoom)

# Mine zoom
se_crop = canvas.crop((170*16, 100*16, 244*16, 150*16))
out_se = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/island_masterpiece_mine_zoom.png'
se_crop.resize((1024, 704), Image.Resampling.NEAREST).save(out_se)

# Mountain zoom
nw_crop = canvas.crop((16*16, 12*16, 60*16, 52*16))
out_nw = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/island_masterpiece_nw_zoom.png'
nw_crop.resize((1024, 704), Image.Resampling.NEAREST).save(out_nw)

# Citadel zoom
citadel_crop = canvas.crop((176*16, 12*16, 240*16, 56*16))
out_citadel = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/island_masterpiece_citadel_zoom.png'
citadel_crop.resize((1024, 704), Image.Resampling.NEAREST).save(out_citadel)

print("Saved all masterpiece visual previews successfully!")
