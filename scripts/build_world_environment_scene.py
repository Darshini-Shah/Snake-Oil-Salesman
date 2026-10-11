import json, random, math, os
from PIL import Image, ImageDraw

random.seed(2026)

# Load map data
with open('assets/maps/clean_map_cells.json') as f:
    map_data = json.load(f)

path_tiles = set((c[0], c[1]) for c in map_data['paths'])
ground_map = {(c[0], c[1]): c[2] for c in map_data['ground']} # (x, y) -> src_id
water_boxes = map_data['water_colliders']
coast_boxes = map_data['coast_colliders']

# 37 Buildings
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

trees = []        # (name, tex_path, x, y, scale, col_radius, col_offset_y)
bushes = []       # (name, tex_path, x, y, scale)
flowers = []      # (name, tex_path, x, y, scale)
water_lilies = [] # (name, tex_path, x, y, scale)
solids = []       # (name, tex_path, x, y, scale, fp_w, fp_h, off_y)
non_solids = []   # (name, tex_path, x, y, scale)

def add_tree(x, y, t_type=None, min_dist=46):
    if not is_valid_land(x, y): return False
    if is_near_path(x, y, buffer_px=22): return False
    if is_in_water_or_coast(x, y, buffer_px=12): return False
    if is_in_building(x, y, buffer_px=16): return False
    for _, _, tx, ty, _, _, _ in trees:
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
    col_rad = 10.0
    col_off = 26.0 if t_type != 'tree_pine' else 30.0
    trees.append((f"Tree_{len(trees)}", tex_path, int(x), int(y), scale, col_rad, col_off))
    return True

def add_bush(x, y, b_type=None, min_dist=22):
    if not is_valid_land(x, y): return False
    if is_near_path(x, y, buffer_px=14): return False
    if is_in_water_or_coast(x, y, buffer_px=8): return False
    if is_in_building(x, y, buffer_px=8): return False
    for _, _, bx, by, _ in bushes:
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
    bushes.append((f"Bush_{len(bushes)}", tex_path, int(x), int(y), 1.8))
    return True

def add_flower(x, y, f_type=None, min_dist=15):
    if not is_valid_land(x, y): return False
    if is_near_path(x, y, buffer_px=10): return False
    if is_in_water_or_coast(x, y, buffer_px=6): return False
    if is_in_building(x, y, buffer_px=6): return False
    for _, _, fx, fy, _ in flowers:
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
    flowers.append((f"Flower_{len(flowers)}", tex_path, int(x), int(y), 1.6))
    return True

def add_solid(name_prefix, tex_path, x, y, scale=1.8, fp_w=24, fp_h=16, off_y=0, min_dist=20):
    if not is_valid_land(x, y): return False
    if is_near_path(x, y, buffer_px=14): return False
    if is_in_water_or_coast(x, y, buffer_px=8): return False
    if is_in_building(x, y, buffer_px=10): return False
    for _, _, sx, sy, _, _, _, _ in solids:
        if math.hypot(x - sx, y - sy) < min_dist:
            return False
    solids.append((f"{name_prefix}_{len(solids)}", tex_path, int(x), int(y), scale, fp_w, fp_h, off_y))
    return True

def add_decor(name_prefix, tex_path, x, y, scale=1.6, min_dist=16):
    if not is_valid_land(x, y): return False
    if is_in_water_or_coast(x, y, buffer_px=6): return False
    if is_in_building(x, y, buffer_px=6): return False
    for _, _, nx, ny, _ in non_solids:
        if math.hypot(x - nx, y - ny) < min_dist:
            return False
    non_solids.append((f"{name_prefix}_{len(non_solids)}", tex_path, int(x), int(y), scale))
    return True

# --- 1. PLAZA ENCLOSURE & CIVIC CENTER (ref_center_zoom.png) ---
# Trees enclosing Kurtos Plaza cobblestones
for px in range(1760, 2400, 48):
    if not (1940 <= px <= 2180): # Town Hall passage
        add_tree(px, 710, 'tree_deciduous', min_dist=42)
        add_bush(px + 12, 745, 'flora_bush_dense', min_dist=20)
for py in range(760, 1420, 48):
    if not (1100 <= py <= 1180): # East-west road gap
        add_tree(1750, py, 'tree_oak', min_dist=42)
        add_bush(1775, py + 10, 'flora_bush_dense', min_dist=20)
        add_tree(2390, py, 'tree_oak', min_dist=42)
        add_bush(2370, py + 10, 'flora_bush_dense', min_dist=20)
for px in range(1780, 2380, 48):
    if not (2010 <= px <= 2110): # South Boulevard gap
        add_tree(px, 1390, 'tree_deciduous', min_dist=42)

# Plaza Corners Streetlamps (4 lamps)
for lx, ly in [(1830, 960), (2280, 960), (1830, 1300), (2280, 1300)]:
    solids.append((f"PlazaLamp_{lx}_{ly}", "res://assets/objects/decor/streetlamp.png", lx, ly, 1.8, 12, 10, 18))

# Plaza Flowerbeds
for fx in [1950, 1980, 2130, 2160]:
    for fy in [1060, 1190]:
        add_flower(fx, fy, 'flora_daisy_cluster', min_dist=12)
        add_flower(fx, fy + 14, 'flora_buttercup_mound', min_dist=12)

# --- 2. NORTH MOUNTAIN PINE RIDGE & SCHOLAR ACADEMY ---
for _ in range(85):
    rx = random.randint(700, 2600)
    ry = random.randint(120, 500)
    add_tree(rx, ry, 'tree_pine', min_dist=44)
    if random.random() < 0.6:
        add_bush(rx + random.randint(-15, 15), ry + random.randint(10, 25), 'flora_fern_tall', min_dist=18)
    if random.random() < 0.4:
        add_solid("MountainBoulder", "res://assets/flora/flora_boulder_buttercups.png", rx + random.randint(-20, 20), ry + random.randint(15, 30), 1.8, 24, 16, 4)

# Smuggler Cave (x=580, y=520)
for _ in range(18):
    rx = 580 + random.randint(-120, 120)
    ry = 520 + random.randint(-80, 80)
    add_solid("CaveRock", "res://assets/flora/flora_boulder_buttercups.png", rx, ry, 1.8, 24, 16, 4, min_dist=22)
    add_flower(rx + 10, ry + 10, 'flora_exotic_fungus', min_dist=14)

# --- 3. ROYAL CITADEL FOREST (NORTHEAST) ---
for _ in range(90):
    rx = random.randint(2800, 3750)
    ry = random.randint(180, 780)
    t = 'cherry_tree' if random.random() < 0.25 else 'tree_pine' if random.random() < 0.6 else 'tree_oak'
    add_tree(rx, ry, t, min_dist=44)
    if random.random() < 0.5:
        add_bush(rx + random.randint(-15, 15), ry + random.randint(10, 25), min_dist=18)

# --- 4. WEST VILLAGE RESIDENTIAL & CANAL ---
# Florist Greenhouse garden (x=1400, y=960)
for _ in range(35):
    fx = 1400 + random.randint(-100, 100)
    fy = 960 + random.randint(-100, 100)
    f_type = random.choice(['flora_lavender_purple', 'flora_lupine_blue', 'flora_lupine_pink', 'flora_daffodil_yellow', 'flora_bush_pinkflowers', 'flora_potted_herbs'])
    add_flower(fx, fy, f_type, min_dist=14)

# Bakery garden (x=1100, y=960)
add_tree(1030, 880, 'cherry_tree', min_dist=38)
for _ in range(20):
    fx = 1100 + random.randint(-90, 90)
    fy = 960 + random.randint(-90, -20)
    add_flower(fx, fy, random.choice(['flora_strawberry_patch', 'flora_daisy_cluster', 'flora_clover_flowers']), min_dist=14)

# Lumberjack Lodge timber logs
for _ in range(5):
    lx = 1400 + random.randint(-70, 70)
    ly = 420 + random.randint(30, 70)
    add_solid("TimberLog", "res://assets/objects/decor/timber_log.png", lx, ly, 1.8, 28, 12, 0, min_dist=18)

# Village yards trees, shrubs, and flowers
for _ in range(70):
    rx = random.choice([random.randint(920, 1180), random.randint(1320, 1560)])
    ry = random.randint(750, 2050)
    add_tree(rx, ry, min_dist=44)
    add_bush(rx + random.randint(-15, 15), ry + random.randint(10, 25), min_dist=18)
    add_flower(rx + random.randint(-20, 20), ry + random.randint(15, 30), min_dist=14)

# Canal banks & Footbridge 2 riverbank flora (x: 600..760, y: 860..1400)
for _ in range(35):
    rx = random.randint(620, 760)
    ry = random.randint(860, 1380)
    add_tree(rx, ry, 'tree_oak', min_dist=42)
    add_solid("CanalRock", "res://assets/village_top_down/foliage/grass_moss_rock.png", rx + 10, ry + 15, 2.0, 16, 12, 2, min_dist=18)
    add_bush(rx - 10, ry + 12, 'flora_fern_leafy', min_dist=16)

# Southwest coast & beach
for _ in range(40):
    rx = random.randint(450, 750)
    ry = random.randint(1550, 2350)
    add_tree(rx, ry, 'tree_pine', min_dist=44)
    add_solid("BeachBoulder", "res://assets/village_top_down/foliage/grass_boulder.png", rx + 12, ry + 16, 2.0, 18, 12, 2, min_dist=18)

# --- 5. EAST FARMLAND VALLEY & WINDMILL MEADOW ---
# Plot 1: Golden Wheat Field (x: 2860..3010, y: 1180..1320)
for cx in range(2860, 3020, 30):
    for cy in range(1180, 1320, 26):
        if is_valid_land(cx, cy) and not is_near_path(cx, cy, 14) and not is_in_building(cx, cy, 10):
            add_decor("CropsWheat", "res://assets/landmarks/crops_wheat.png", cx, cy, 1.8, min_dist=18)

# Plot 2: Carrot Field (x: 3160..3310, y: 1180..1250)
for cx in range(3160, 3310, 32):
    for cy in range(1180, 1250, 26):
        if is_valid_land(cx, cy) and not is_near_path(cx, cy, 14) and not is_in_building(cx, cy, 10):
            add_decor("CropsCarrot", "res://assets/landmarks/crops_carrots.png", cx, cy, 1.8, min_dist=18)

# Plot 3: Cabbage / Greens Field (x: 3160..3310, y: 1260..1330)
for cx in range(3160, 3310, 32):
    for cy in range(1260, 1330, 26):
        if is_valid_land(cx, cy) and not is_near_path(cx, cy, 14) and not is_in_building(cx, cy, 10):
            add_decor("CropsGreens", "res://assets/landmarks/crops_greens.png", cx, cy, 1.8, min_dist=18)

# Farm signs & sacks
add_decor("SignWheat", "res://assets/objects/decor/sign_wheat.png", 2850, 1160, 1.8, min_dist=10)
add_decor("SackWheat", "res://assets/objects/decor/sack_wheat.png", 2870, 1160, 1.8, min_dist=10)
add_decor("SignCarrot", "res://assets/objects/decor/sign_carrot.png", 3150, 1160, 1.8, min_dist=10)
add_decor("SackCarrot", "res://assets/objects/decor/sack_carrot.png", 3170, 1160, 1.8, min_dist=10)

# Fences around plots
for fx in range(2860, 3020, 58):
    add_solid("FarmFence1", "res://assets/landmarks/fences_wood.png", fx, 1165, 1.8, 50, 16, 0, min_dist=40)
for fx in range(3160, 3310, 58):
    add_solid("FarmFence2", "res://assets/landmarks/fences_wood.png", fx, 1165, 1.8, 50, 16, 0, min_dist=40)

# Beekeeper Apiary Wildflower Meadow (x: 3450..3650, y: 1350..1520)
for _ in range(45):
    bx = 3550 + random.randint(-110, 110)
    by = 1420 + random.randint(-80, 80)
    f_type = random.choice(['flora_clover_flowers', 'flora_clover_pink', 'flora_buttercup_mound', 'flora_lavender_purple', 'flora_strawberry_patch'])
    add_flower(bx, by, f_type, min_dist=13)

# Windmill surroundings
add_tree(3540, 1060, 'tree_oak', min_dist=38)
for _ in range(20):
    wx = 3450 + random.randint(-80, 80)
    wy = 1120 + random.randint(-80, 80)
    add_flower(wx, wy, 'flora_buttercup_mound', min_dist=14)

# Deep Stone Mine (x: 3440, y: 2100) - ore crystals, boulders, mining timbers
for _ in range(12):
    mx = 3440 + random.randint(-110, 110)
    my = 2100 + random.randint(-60, 60)
    if is_valid_land(mx, my) and not is_in_building(mx, my, 8):
        add_solid("MineOre", "res://assets/objects/decor/gold_ore.png" if random.random() < 0.5 else "res://assets/objects/decor/blue_ore.png", mx, my, 1.8, 16, 12, 0, min_dist=16)

# Farmland groves & hedgerows
for _ in range(50):
    rx = random.randint(2800, 3600)
    ry = random.randint(950, 1950)
    add_tree(rx, ry, 'tree_oak', min_dist=46)
    add_bush(rx + 10, ry + 12, min_dist=18)

# --- 6. SOUTHERN ARRIVAL BRIDGE & RIVER WATERFALL ---
# Arrival Bridge Welcoming Gate & Streetlamps (x=2048, y=2368)
solids.append(("BridgeLamp_Left", "res://assets/objects/decor/streetlamp.png", 2000, 2370, 1.8, 12, 10, 18))
solids.append(("BridgeLamp_Right", "res://assets/objects/decor/streetlamp.png", 2096, 2370, 1.8, 12, 10, 18))
add_tree(1940, 2380, 'tree_pine', min_dist=38)
add_tree(1900, 2420, 'tree_oak', min_dist=38)
add_tree(2160, 2380, 'tree_pine', min_dist=38)
add_tree(2200, 2420, 'tree_oak', min_dist=38)
add_bush(1950, 2440, 'flora_bush_dense', min_dist=18)
add_bush(2150, 2440, 'flora_bush_dense', min_dist=18)

# Center Pond Islet Pine Tree (matching ref_south_zoom.png!)
add_tree(1728, 2016, 'tree_pine', min_dist=20)

# Waterfall riverbank forest
for _ in range(55):
    rx = random.randint(1450, 1950)
    ry = random.randint(1850, 2450)
    add_tree(rx, ry, 'tree_pine' if random.random() < 0.6 else 'tree_oak', min_dist=42)
    add_bush(rx + 10, ry + 15, 'flora_fern_tall', min_dist=18)
    add_solid("RiverRock", "res://assets/village_top_down/foliage/grass_moss_rock.png", rx - 10, ry + 18, 2.0, 16, 12, 2, min_dist=18)

# --- 7. WATER LILIES IN INLAND WATER BODIES ---
for wb in water_boxes:
    x, y, w, h = wb
    if w >= 32 and h >= 32:
        count = max(1, (w * h) // 3500)
        for _ in range(count):
            lx = x + random.randint(10, w - 10)
            ly = y + random.randint(10, h - 10)
            if (1536 <= lx <= 1728 and 1904 <= ly <= 1968): continue # Footbridge 1
            if (704 <= lx <= 800 and 1120 <= ly <= 1296): continue # Footbridge 2
            water_lilies.append((f"WaterLily_{len(water_lilies)}", "res://assets/flora/flora_water_lilies.png", lx, ly, 1.6))

# --- 8. GROUND DETAILS ACROSS MEADOWS ---
detail_types = [
    'res://assets/village_top_down/foliage/grass_tuft_tall.png',
    'res://assets/village_top_down/foliage/grass_clover.png',
    'res://assets/village_top_down/foliage/grass_wildflower_blue.png',
    'res://assets/village_top_down/foliage/grass_wildflower_gold.png',
    'res://assets/village_top_down/details/pebbles_1.png',
    'res://assets/village_top_down/details/pebbles_2.png',
]
for _ in range(320):
    dx = random.randint(400, 3700)
    dy = random.randint(300, 2500)
    if is_valid_land(dx, dy) and not is_in_water_or_coast(dx, dy, 6) and not is_in_building(dx, dy, 6):
        d_tex = random.choice(detail_types)
        add_decor("GroundDetail", d_tex, dx, dy, 1.6, min_dist=18)

print("=== COMPLETE ENVIRONMENT DATASET GENERATED ===")
print(f"  Trees (Solid trunk):     {len(trees)}")
print(f"  Bushes:                  {len(bushes)}")
print(f"  Flowers & Herbs:         {len(flowers)}")
print(f"  Water Lilies:            {len(water_lilies)}")
print(f"  Solids (Rocks/Fences):   {len(solids)}")
print(f"  Decor & Crops:           {len(non_solids)}")
total = len(trees) + len(bushes) + len(flowers) + len(water_lilies) + len(solids) + len(non_solids)
print(f"  TOTAL WORLD ELEMENTS:    {total}")

# Save JSON
env_data = {
    'trees': trees,
    'bushes': bushes,
    'flowers': flowers,
    'water_lilies': water_lilies,
    'solids': solids,
    'non_solids': non_solids,
}
with open('assets/maps/world_environment_data.json', 'w') as f:
    json.dump(env_data, f, indent=2)

print("✅ Saved assets/maps/world_environment_data.json")
