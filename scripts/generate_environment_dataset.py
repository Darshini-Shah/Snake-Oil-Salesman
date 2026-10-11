import json, random, math, os
from PIL import Image, ImageDraw

random.seed(1337) # Deterministic for consistent, reproducible world design

with open('assets/maps/clean_map_cells.json') as f:
    map_data = json.load(f)

path_tiles = set((c[0], c[1]) for c in map_data['paths'])
ground_map = {(c[0], c[1]): c[2] for c in map_data['ground']} # (x, y) -> src_id
water_boxes = map_data['water_colliders']
coast_boxes = map_data['coast_colliders']

BUILDINGS = [
    ("RoyalCastle", 3300, 460, 482, 340, 400, 90, 60),
    ("ScholarAcademy", 2056, 250, 312, 196, 260, 70, 45),
    ("SmugglerCave", 580, 520, 153, 153, 120, 50, 35),
    ("Lighthouse", 240, 1120, 148, 218, 120, 80, 50),
    ("PlazaFountain", 2056, 1128, 100, 106, 80, 80, 0),
    ("Windmill", 3450, 1120, 169, 209, 120, 70, 50),
    ("MineEntrance", 3440, 2100, 235, 144, 200, 60, 35),
    ("TownHall", 2056, 800, 275, 218, 240, 70, 50),
    ("MerchantShop", 1850, 1030, 192, 192, 140, 55, 45),
    ("WatchmakersHouse", 1850, 1260, 192, 192, 140, 55, 45),
    ("DoctorsClinic", 2270, 1030, 192, 192, 140, 55, 45),
    ("MayorsResidence", 2270, 1260, 192, 192, 140, 55, 45),
    ("Library", 2520, 1260, 192, 192, 140, 55, 45),
    ("MusiciansHouse", 1850, 1520, 192, 192, 140, 55, 45),
    ("PostHouse", 2270, 1520, 192, 192, 140, 55, 45),
    ("HuntersCabin", 1080, 420, 192, 192, 140, 55, 45),
    ("LumberjackHouse", 1400, 420, 192, 192, 140, 55, 45),
    ("ChurchBuilding", 1620, 780, 224, 230, 180, 70, 50),
    ("BrewersHouse", 1620, 1310, 192, 192, 140, 55, 45),
    ("FishermansHut", 620, 1040, 192, 192, 130, 45, 35),
    ("PottersHouse", 580, 1680, 192, 192, 140, 55, 45),
    ("SmallWoodenCottage", 580, 1940, 192, 192, 140, 55, 45),
    ("BeachCottage", 580, 2200, 192, 192, 140, 55, 45),
    ("BakeryBuilding", 1100, 960, 192, 192, 140, 55, 45),
    ("BlacksmithHouse", 1115, 1310, 192, 192, 135, 55, 45),
    ("TailorsHouse", 1100, 1590, 192, 192, 140, 55, 45),
    ("Tavern", 1100, 1870, 192, 192, 140, 55, 45),
    ("FloristsHouse", 1400, 960, 192, 192, 140, 55, 45),
    ("HerbalistHouse", 1400, 1310, 192, 192, 140, 55, 45),
    ("CarpentersHouse", 1400, 1590, 192, 192, 140, 55, 45),
    ("ToyMakersHouse", 1400, 1870, 192, 192, 140, 55, 45),
    ("FarmersHouse", 3080, 1120, 192, 192, 140, 55, 45),
    ("StorageBarn", 3080, 1420, 196, 158, 160, 70, 40),
    ("BeekeepersHut", 3550, 1420, 192, 192, 140, 55, 45),
    ("MillHouse", 3250, 1700, 192, 192, 140, 55, 45),
    ("CoastCabin", 3550, 1740, 192, 192, 140, 55, 45),
    ("MinersShed", 3180, 2100, 192, 192, 140, 55, 45),
]

def is_near_path(px, py, buffer_px=18):
    tx = int(px // 16)
    ty = int(py // 16)
    rad = int(math.ceil(buffer_px / 16))
    for dy in range(-rad, rad + 1):
        for dx in range(-rad, rad + 1):
            if (tx + dx, ty + dy) in path_tiles:
                tile_cx = (tx + dx) * 16 + 8
                tile_cy = (ty + dy) * 16 + 8
                dist = math.hypot(px - tile_cx, py - tile_cy)
                if dist < buffer_px:
                    return True
    return False

def is_in_water_or_coast(px, py, buffer_px=8):
    for b in water_boxes + coast_boxes:
        bx, by, bw, bh = b
        if (bx - buffer_px) <= px <= (bx + bw + buffer_px) and (by - buffer_px) <= py <= (by + bh + buffer_px):
            return True
    return False

def is_in_building(px, py, buffer_px=12):
    for bld in BUILDINGS:
        name, bx, by, bw, bh, fp_w, fp_h, off_y = bld
        f_left = bx - fp_w / 2 - buffer_px
        f_right = bx + fp_w / 2 + buffer_px
        f_top = by + off_y - fp_h / 2 - buffer_px
        f_bottom = by + off_y + fp_h / 2 + buffer_px + 28 # clearance in front of door
        if f_left <= px <= f_right and f_top <= py <= f_bottom:
            return True
    return False

def is_valid_land(px, py):
    tx = int(px // 16)
    ty = int(py // 16)
    src = ground_map.get((tx, ty), 0)
    return src != 0

trees = []        # (tex_path, x, y, scale)
bushes = []       # (tex_path, x, y, scale)
flowers = []      # (tex_path, x, y, scale)
water_lilies = [] # (tex_path, x, y, scale)
rocks_logs = []   # (tex_path, x, y, scale, is_solid)
crops_fences = [] # (tex_path, x, y, scale, is_solid)
details = []      # (tex_path, x, y, scale)

def add_tree(x, y, t_type=None, min_dist=48):
    if not is_valid_land(x, y): return False
    if is_near_path(x, y, buffer_px=22): return False
    if is_in_water_or_coast(x, y, buffer_px=12): return False
    if is_in_building(x, y, buffer_px=16): return False
    for _, tx, ty, _ in trees:
        if math.hypot(x - tx, y - ty) < min_dist:
            return False
    if t_type is None:
        r = random.random()
        if r < 0.40: t_type = 'tree_pine'
        elif r < 0.72: t_type = 'tree_oak'
        elif r < 0.88: t_type = 'tree_deciduous'
        else: t_type = 'cherry_tree'
    tex_path = f"res://assets/landmarks/{t_type}.png"
    scale = 1.6 if t_type == 'cherry_tree' else 1.8
    trees.append((tex_path, int(x), int(y), scale))
    return True

def add_bush(x, y, b_type=None, min_dist=24):
    if not is_valid_land(x, y): return False
    if is_near_path(x, y, buffer_px=14): return False
    if is_in_water_or_coast(x, y, buffer_px=8): return False
    if is_in_building(x, y, buffer_px=8): return False
    for _, bx, by, _ in bushes:
        if math.hypot(x - bx, y - by) < min_dist:
            return False
    b_types = [
        'flora_bush_dense', 'flora_bush_blueberries', 'flora_bush_orangeberries',
        'flora_bush_pinkflowers', 'flora_fern_tall', 'flora_fern_leafy',
        'flora_hosta_broadleaf', 'flora_hosta_blooming'
    ]
    if b_type is None:
        b_type = random.choice(b_types)
    tex_path = f"res://assets/flora/{b_type}.png"
    bushes.append((tex_path, int(x), int(y), 1.8))
    return True

def add_flower(x, y, f_type=None, min_dist=16):
    if not is_valid_land(x, y): return False
    if is_near_path(x, y, buffer_px=10): return False
    if is_in_water_or_coast(x, y, buffer_px=6): return False
    if is_in_building(x, y, buffer_px=6): return False
    for _, fx, fy, _ in flowers:
        if math.hypot(x - fx, y - fy) < min_dist:
            return False
    f_types = [
        'flora_lavender_purple', 'flora_lupine_blue', 'flora_lupine_pink', 'flora_lupine_purple',
        'flora_daffodil_yellow', 'flora_daffodil_orange', 'flora_daisy_cluster', 'flora_daisy_tall',
        'flora_foxglove_tall', 'flora_buttercup_mound', 'flora_clover_flowers', 'flora_clover_pink',
        'flora_strawberry_patch', 'flora_orange_blossom', 'flora_peach_blossom'
    ]
    if f_type is None:
        f_type = random.choice(f_types)
    tex_path = f"res://assets/flora/{f_type}.png"
    flowers.append((tex_path, int(x), int(y), 1.6))
    return True

def add_rock_or_log(x, y, r_type=None, is_solid=True, min_dist=24):
    if not is_valid_land(x, y): return False
    if is_near_path(x, y, buffer_px=14): return False
    if is_in_water_or_coast(x, y, buffer_px=6): return False
    if is_in_building(x, y, buffer_px=10): return False
    for _, rx, ry, _, _ in rocks_logs:
        if math.hypot(x - rx, y - ry) < min_dist:
            return False
    if r_type is None:
        r_types = [
            ('res://assets/flora/flora_boulder_buttercups.png', 1.8, True),
            ('res://assets/village_top_down/foliage/grass_boulder.png', 2.0, True),
            ('res://assets/village_top_down/foliage/grass_moss_rock.png', 2.0, False),
            ('res://assets/flora/flora_log_mossy.png', 1.8, True),
            ('res://assets/flora/flora_log_mushrooms.png', 1.8, True),
            ('res://assets/flora/flora_stump_mossy.png', 1.8, True),
            ('res://assets/flora/flora_stump_fungus.png', 1.8, True),
            ('res://assets/village_top_down/details/pebbles_1.png', 1.8, False),
            ('res://assets/village_top_down/details/pebbles_2.png', 1.8, False),
        ]
        chosen = random.choice(r_types)
        tex_path, scale, is_solid = chosen
    else:
        tex_path = r_type
        scale = 1.8
    rocks_logs.append((tex_path, int(x), int(y), scale, is_solid))
    return True

# --- 1. PLAZA ENCLOSURE TREES & HEDGES (Exact match to ref_center_zoom.png) ---
# North border of Plaza (behind & flanking Town Hall at y=720)
for px in range(1760, 2400, 52):
    if not (1940 <= px <= 2180): # gap for Town Hall facade
        add_tree(px, 710, 'tree_deciduous', min_dist=44)
        add_bush(px + 12, 745, 'flora_bush_dense', min_dist=20)

# West border of Plaza (separating Plaza from West Village at x=1750)
for py in range(760, 1420, 52):
    if not (1100 <= py <= 1180): # gap for Footbridge 2 road into plaza
        add_tree(1750, py, 'tree_oak', min_dist=44)
        add_bush(1775, py + 10, 'flora_bush_dense', min_dist=20)

# East border of Plaza (between Plaza and Farmlands at x=2390)
for py in range(760, 1420, 52):
    if not (1100 <= py <= 1180): # gap for East boulevard
        add_tree(2390, py, 'tree_oak', min_dist=44)
        add_bush(2370, py + 10, 'flora_bush_dense', min_dist=20)

# South border of Plaza (y=1390)
for px in range(1780, 2380, 52):
    if not (2010 <= px <= 2110): # gap for Grand South Boulevard
        add_tree(px, 1390, 'tree_deciduous', min_dist=44)

# Plaza Flowerbeds (framing the fountain and corners)
for fx in [1960, 2150]:
    for fy in [1070, 1180]:
        add_flower(fx, fy, 'flora_daisy_cluster', min_dist=14)
        add_flower(fx + 16, fy, 'flora_buttercup_mound', min_dist=14)

# --- 2. NORTH MOUNTAIN PINE RIDGE & SCHOLAR ACADEMY ---
# Pine forest cresting northern mountains
for _ in range(70):
    rx = random.randint(700, 2600)
    ry = random.randint(120, 480)
    add_tree(rx, ry, 'tree_pine', min_dist=46)
    if random.random() < 0.6:
        add_bush(rx + random.randint(-15, 15), ry + random.randint(10, 25), 'flora_fern_tall', min_dist=18)
    if random.random() < 0.4:
        add_rock_or_log(rx + random.randint(-20, 20), ry + random.randint(15, 30), min_dist=22)

# Smuggler Cave surroundings (x=580, y=520)
for _ in range(15):
    rx = 580 + random.randint(-120, 120)
    ry = 520 + random.randint(-80, 80)
    add_rock_or_log(rx, ry, 'res://assets/flora/flora_boulder_buttercups.png', True, min_dist=24)
    add_flower(rx + 10, ry + 10, 'flora_exotic_fungus', min_dist=16)

# --- 3. ROYAL CITADEL & CASTLE FOREST ---
# Thick forest wrapping the castle plateau
for _ in range(75):
    rx = random.randint(2800, 3750)
    ry = random.randint(180, 750)
    t = 'cherry_tree' if random.random() < 0.25 else 'tree_pine' if random.random() < 0.6 else 'tree_oak'
    add_tree(rx, ry, t, min_dist=46)
    if random.random() < 0.5:
        add_bush(rx + random.randint(-15, 15), ry + random.randint(10, 25), min_dist=20)

# --- 4. WEST VILLAGE BACKYARDS & GARDENS ---
# Florist Garden (x=1400, y=960) - dense blooming floral showcase
for _ in range(25):
    fx = 1400 + random.randint(-90, 90)
    fy = 960 + random.randint(-90, 90)
    f_type = random.choice(['flora_lavender_purple', 'flora_lupine_blue', 'flora_lupine_pink', 'flora_daffodil_yellow', 'flora_bush_pinkflowers'])
    add_flower(fx, fy, f_type, min_dist=15)

# Bakery Garden (x=1100, y=960) - cherry tree, herbs, strawberries
add_tree(1030, 880, 'cherry_tree', min_dist=40)
for _ in range(15):
    fx = 1100 + random.randint(-80, 80)
    fy = 960 + random.randint(-80, -20)
    add_flower(fx, fy, random.choice(['flora_strawberry_patch', 'flora_daisy_cluster', 'flora_clover_flowers']), min_dist=15)

# Village general yard trees and shrubs (West column x: 950..1200, East column x: 1300..1550)
for _ in range(50):
    rx = random.choice([random.randint(920, 1180), random.randint(1320, 1550)])
    ry = random.randint(750, 2050)
    add_tree(rx, ry, min_dist=46)
    add_bush(rx + random.randint(-15, 15), ry + random.randint(10, 25), min_dist=20)
    add_flower(rx + random.randint(-20, 20), ry + random.randint(15, 30), min_dist=16)

# Canal banks & Footbridge 2 riverbank flora (x: 600..750, y: 850..1400)
for _ in range(30):
    rx = random.randint(620, 760)
    ry = random.randint(860, 1380)
    add_tree(rx, ry, 'tree_oak', min_dist=44)
    add_rock_or_log(rx + 10, ry + 15, 'res://assets/village_top_down/foliage/grass_moss_rock.png', False, min_dist=20)
    add_bush(rx - 10, ry + 12, 'flora_fern_leafy', min_dist=18)

# --- 5. EAST FARMLAND VALLEY & WINDMILL MEADOW ---
# Fenced Crop Plots (Organized rectangular plots near x: 2850..3250, y: 1050..1350)
crop_texs = [
    'res://assets/landmarks/crops_wheat.png',
    'res://assets/landmarks/crops_carrots.png',
    'res://assets/landmarks/crops_greens.png'
]
# Plot 1: Wheat Field (x: 2860..3000, y: 1180..1320)
for cx in range(2860, 3010, 32):
    for cy in range(1180, 1320, 28):
        if is_valid_land(cx, cy) and not is_near_path(cx, cy, 14) and not is_in_building(cx, cy, 10):
            crops_fences.append(('res://assets/landmarks/crops_wheat.png', cx, cy, 1.8, False))

# Plot 2: Vegetable & Carrot Field (x: 3160..3300, y: 1180..1320)
for cx in range(3160, 3310, 34):
    for cy in range(1180, 1320, 28):
        if is_valid_land(cx, cy) and not is_near_path(cx, cy, 14) and not is_in_building(cx, cy, 10):
            c_tex = 'res://assets/landmarks/crops_carrots.png' if cy < 1250 else 'res://assets/landmarks/crops_greens.png'
            crops_fences.append((c_tex, cx, cy, 1.8, False))

# Fences enclosing the farm plots
for fx in range(2860, 3010, 60):
    if is_valid_land(fx, 1160) and not is_near_path(fx, 1160, 14) and not is_in_building(fx, 1160, 10):
        crops_fences.append(('res://assets/landmarks/fences_wood.png', fx, 1160, 1.8, True))
for fx in range(3160, 3310, 60):
    if is_valid_land(fx, 1160) and not is_near_path(fx, 1160, 14) and not is_in_building(fx, 1160, 10):
        crops_fences.append(('res://assets/landmarks/fences_wood.png', fx, 1160, 1.8, True))

# Beekeeper Apiary Wildflower Meadow (x: 3450..3650, y: 1350..1520)
for _ in range(40):
    bx = 3550 + random.randint(-110, 110)
    by = 1420 + random.randint(-80, 80)
    f_type = random.choice(['flora_clover_flowers', 'flora_clover_pink', 'flora_buttercup_mound', 'flora_lavender_purple', 'flora_strawberry_patch'])
    add_flower(bx, by, f_type, min_dist=14)

# Windmill surroundings (x=3450, y=1120)
add_tree(3540, 1060, 'tree_oak', min_dist=42)
for _ in range(15):
    wx = 3450 + random.randint(-80, 80)
    wy = 1120 + random.randint(-80, 80)
    add_flower(wx, wy, 'flora_buttercup_mound', min_dist=15)

# Farmland groves & hedgerows
for _ in range(40):
    rx = random.randint(2800, 3600)
    ry = random.randint(950, 1900)
    add_tree(rx, ry, 'tree_oak', min_dist=48)
    add_bush(rx + 10, ry + 12, min_dist=20)

# --- 6. SOUTHERN ARRIVAL BRIDGE & SW RIVER WATERFALL ---
# Arrival Bridge Welcoming Grove (framing the road at x: 2048, y: 2368)
add_tree(1940, 2380, 'tree_pine', min_dist=40)
add_tree(1900, 2420, 'tree_oak', min_dist=40)
add_tree(2160, 2380, 'tree_pine', min_dist=40)
add_tree(2200, 2420, 'tree_oak', min_dist=40)
add_bush(1950, 2440, 'flora_bush_dense', min_dist=18)
add_bush(2150, 2440, 'flora_bush_dense', min_dist=18)

# Center Pond Islet Pine Tree (matching ref_south_zoom.png!)
# Pond islet is around tile (108, 126) -> px: 1728, 2016
add_tree(1728, 2016, 'tree_pine', min_dist=20)

# Southern waterfall riverbank forest
for _ in range(50):
    rx = random.randint(1450, 1950)
    ry = random.randint(1850, 2450)
    add_tree(rx, ry, 'tree_pine' if random.random() < 0.6 else 'tree_oak', min_dist=44)
    add_bush(rx + 10, ry + 15, 'flora_fern_tall', min_dist=20)
    add_rock_or_log(rx - 10, ry + 18, min_dist=22)

# --- 7. WATER LILIES IN INLAND WATER BODIES ---
# SW River Pond (x: 1620..1820, y: 1950..2200)
for _ in range(16):
    lx = random.randint(1640, 1800)
    ly = random.randint(1960, 2180)
    # Check if in water
    for wb in water_boxes:
        if wb[0] <= lx <= wb[0] + wb[2] and wb[1] <= ly <= wb[1] + wb[3]:
            # make sure not on Footbridge 1
            if not (1536 <= lx <= 1728 and 1904 <= ly <= 1968):
                water_lilies.append(('res://assets/flora/flora_water_lilies.png', lx, ly, 1.6))
                break

# SE Wetland Lake (x: 2700..3250, y: 1900..2350)
for _ in range(18):
    lx = random.randint(2750, 3200)
    ly = random.randint(1950, 2300)
    for wb in water_boxes:
        if wb[0] <= lx <= wb[0] + wb[2] and wb[1] <= ly <= wb[1] + wb[3]:
            water_lilies.append(('res://assets/flora/flora_water_lilies.png', lx, ly, 1.6))
            break

# West Canal (x: 640..740, y: 1200..1400)
for _ in range(8):
    lx = random.randint(660, 720)
    ly = random.randint(1220, 1380)
    for wb in water_boxes:
        if wb[0] <= lx <= wb[0] + wb[2] and wb[1] <= ly <= wb[1] + wb[3]:
            water_lilies.append(('res://assets/flora/flora_water_lilies.png', lx, ly, 1.6))
            break

# --- 8. GROUND DETAILS (Pebbles, Grass Tufts, Clovers) ---
detail_types = [
    'res://assets/village_top_down/foliage/grass_tuft_tall.png',
    'res://assets/village_top_down/foliage/grass_clover.png',
    'res://assets/village_top_down/foliage/grass_wildflower_blue.png',
    'res://assets/village_top_down/foliage/grass_wildflower_gold.png',
    'res://assets/village_top_down/details/pebbles_1.png',
    'res://assets/village_top_down/details/pebbles_2.png',
]
for _ in range(250):
    dx = random.randint(400, 3700)
    dy = random.randint(300, 2500)
    if is_valid_land(dx, dy) and not is_in_water_or_coast(dx, dy, 6) and not is_in_building(dx, dy, 6):
        d_tex = random.choice(detail_types)
        details.append((d_tex, dx, dy, 1.6))

print("=== GENERATED WORLD ENVIRONMENT SUMMARY ===")
print(f"  Trees:         {len(trees)}")
print(f"  Bushes:        {len(bushes)}")
print(f"  Flowers:       {len(flowers)}")
print(f"  Water Lilies:  {len(water_lilies)}")
print(f"  Rocks & Logs:  {len(rocks_logs)}")
print(f"  Crops & Fences:{len(crops_fences)}")
print(f"  Ground Details:{len(details)}")
total = len(trees) + len(bushes) + len(flowers) + len(water_lilies) + len(rocks_logs) + len(crops_fences) + len(details)
print(f"  TOTAL ELEMENTS:{total}")

# Save to JSON
env_data = {
    'trees': trees,
    'bushes': bushes,
    'flowers': flowers,
    'water_lilies': water_lilies,
    'rocks_logs': rocks_logs,
    'crops_fences': crops_fences,
    'details': details
}
with open('assets/maps/world_environment_data.json', 'w') as f:
    json.dump(env_data, f, indent=2)

print("Saved assets/maps/world_environment_data.json!")
