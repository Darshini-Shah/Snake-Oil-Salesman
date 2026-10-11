import json, random, math, os
from PIL import Image

random.seed(2026) # Deterministic

with open('assets/maps/clean_map_cells.json') as f:
    map_data = json.load(f)

path_tiles = set((c[0], c[1]) for c in map_data['paths'])
ground_map = {(c[0], c[1]): c[2] for c in map_data['ground']} # (x, y) -> src_id
water_boxes = map_data['water_colliders']
coast_boxes = map_data['coast_colliders']

# 37 Buildings Config: [name, tex_path, bx, by, bw, bh, fp_w, fp_h, off_y, sf]
BUILDINGS = [
    ("RoyalCastle", "res://assets/landmarks/royal_castle.png", 3300, 460, 482, 340, 400, 90, 60, 2.0),
    ("ScholarAcademy", "res://assets/landmarks/academy.png", 2056, 250, 312, 196, 260, 70, 45, 1.85),
    ("SmugglerCave", "res://assets/landmarks/mountain_cave.png", 580, 520, 153, 153, 120, 50, 35, 1.8),
    ("Lighthouse", "res://assets/landmarks/lighthouse.png", 240, 1120, 148, 218, 120, 80, 50, 1.8),
    ("PlazaFountain", "res://assets/landmarks/fountain.png", 2056, 1128, 100, 106, 80, 80, 0, 1.6),
    ("Windmill", "res://assets/landmarks/windmill.png", 3450, 1120, 169, 209, 120, 70, 50, 2.2),
    ("MineEntrance", "res://assets/landmarks/mine_entrance.png", 3440, 2100, 235, 144, 200, 60, 35, 1.85),
    ("TownHall", "res://assets/landmarks/town_hall.png", 2056, 800, 275, 218, 240, 70, 50, 1.85),
    ("MerchantShop", "res://assets/Tiny Top-Down Village/General Store.png", 1850, 1030, 192, 192, 140, 55, 45, 2.4),
    ("WatchmakersHouse", "res://assets/Tiny Top-Down Village/Watchmakers House.png", 1850, 1260, 192, 192, 140, 55, 45, 2.4),
    ("DoctorsClinic", "res://assets/Tiny Top-Down Village/Doctors House.png", 2270, 1030, 192, 192, 140, 55, 45, 2.4),
    ("MayorsResidence", "res://assets/Tiny Top-Down Village/Mayors Residence.png", 2270, 1260, 192, 192, 140, 55, 45, 2.4),
    ("Library", "res://assets/Tiny Top-Down Village/Library.png", 2520, 1260, 192, 192, 140, 55, 45, 2.4),
    ("MusiciansHouse", "res://assets/Tiny Top-Down Village/Musicians House.png", 1850, 1520, 192, 192, 140, 55, 45, 2.4),
    ("PostHouse", "res://assets/Tiny Top-Down Village/Post House.png", 2270, 1520, 192, 192, 140, 55, 45, 2.4),
    ("HuntersCabin", "res://assets/Tiny Top-Down Village/Hunters Cabin.png", 1080, 420, 192, 192, 140, 55, 45, 2.4),
    ("LumberjackHouse", "res://assets/Tiny Top-Down Village/Lumberjack House.png", 1400, 420, 192, 192, 140, 55, 45, 2.4),
    ("ChurchBuilding", "res://assets/landmarks/church.png", 1620, 780, 224, 230, 180, 70, 50, 1.85),
    ("BrewersHouse", "res://assets/Tiny Top-Down Village/Brewers House.png", 1620, 1310, 192, 192, 140, 55, 45, 2.4),
    ("FishermansHut", "res://assets/Tiny Top-Down Village/Fishermans Hut.png", 620, 1040, 192, 192, 130, 45, 35, 2.4),
    ("PottersHouse", "res://assets/Tiny Top-Down Village/Potters House.png", 580, 1680, 192, 192, 140, 55, 45, 2.4),
    ("SmallWoodenCottage", "res://assets/Tiny Top-Down Village/Small Wooden Cottage.png", 580, 1940, 192, 192, 140, 55, 45, 2.4),
    ("BeachCottage", "res://assets/Tiny Top-Down Village/Stone Village House.png", 580, 2200, 192, 192, 140, 55, 45, 2.4),
    ("BakeryBuilding", "res://assets/Tiny Top-Down Village/Bakery.png", 1100, 960, 192, 192, 140, 55, 45, 2.4),
    ("BlacksmithHouse", "res://assets/Tiny Top-Down Village/Blacksmith House.png", 1115, 1310, 192, 192, 135, 55, 45, 2.4),
    ("TailorsHouse", "res://assets/Tiny Top-Down Village/Tailors House.png", 1100, 1590, 192, 192, 140, 55, 45, 2.4),
    ("Tavern", "res://assets/Tiny Top-Down Village/Tavern.png", 1100, 1870, 192, 192, 140, 55, 45, 2.4),
    ("FloristsHouse", "res://assets/Tiny Top-Down Village/Florists House.png", 1400, 960, 192, 192, 140, 55, 45, 2.4),
    ("HerbalistHouse", "res://assets/Tiny Top-Down Village/Herbalist House.png", 1400, 1310, 192, 192, 140, 55, 45, 2.4),
    ("CarpentersHouse", "res://assets/Tiny Top-Down Village/Carpenters House.png", 1400, 1590, 192, 192, 140, 55, 45, 2.4),
    ("ToyMakersHouse", "res://assets/Tiny Top-Down Village/Toy Makers House.png", 1400, 1870, 192, 192, 140, 55, 45, 2.4),
    ("FarmersHouse", "res://assets/Tiny Top-Down Village/Farmers House.png", 3080, 1120, 192, 192, 140, 55, 45, 2.4),
    ("StorageBarn", "res://assets/landmarks/barn.png", 3080, 1420, 196, 158, 160, 70, 40, 2.0),
    ("BeekeepersHut", "res://assets/Tiny Top-Down Village/Beekeepers Hut.png", 3550, 1420, 192, 192, 140, 55, 45, 2.4),
    ("MillHouse", "res://assets/Tiny Top-Down Village/Mill House.png", 3250, 1700, 192, 192, 140, 55, 45, 2.4),
    ("CoastCabin", "res://assets/Tiny Top-Down Village/Small Wooden Cottage.png", 3550, 1740, 192, 192, 140, 55, 45, 2.4),
    ("MinersShed", "res://assets/Tiny Top-Down Village/Storage House.png", 3180, 2100, 192, 192, 140, 55, 45, 2.4),
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

def is_near_bridge(cx, cy, buffer_px=32):
    # Footbridge 1: x: 1536..1728, y: 1904..1968
    if (1500 - buffer_px) <= cx <= (1760 + buffer_px) and (1870 - buffer_px) <= cy <= (2010 + buffer_px): return True
    # Footbridge 2: x: 704..800, y: 1120..1296
    if (670 - buffer_px) <= cx <= (820 + buffer_px) and (1060 - buffer_px) <= cy <= (1350 + buffer_px): return True
    # Southern Bridge: x: 1984..2112, y: 2368..2816
    if (1960 - buffer_px) <= cx <= (2136 + buffer_px) and (2340 - buffer_px) <= cy <= (2830 + buffer_px): return True
    return False

def is_in_water_or_coast(px, py, buffer_px=8):
    for b in water_boxes + coast_boxes:
        bx, by, bw, bh = b
        if (bx - buffer_px) <= px <= (bx + bw + buffer_px) and (by - buffer_px) <= py <= (by + bh + buffer_px):
            return True
    return False

def is_in_building(px, py, buffer_px=14):
    for bld in BUILDINGS:
        name, tex_path, bx, by, bw, bh, fp_w, fp_h, off_y, sf = bld
        f_left = bx - fp_w / 2 - buffer_px
        f_right = bx + fp_w / 2 + buffer_px
        f_top = by + off_y - fp_h / 2 - buffer_px
        f_bottom = by + off_y + fp_h / 2 + buffer_px + 28 # door clearance
        if f_left <= px <= f_right and f_top <= py <= f_bottom:
            return True
    return False

def is_valid_land(px, py):
    tx = int(px // 16)
    ty = int(py // 16)
    src = ground_map.get((tx, ty), 0)
    return src != 0

# --- UNIFIED SPATIAL PLACER WITH STRICT CLEARANCE MATRIX ---
SEPARATION_MATRIX = {
    ('tree', 'tree'): 18,       # 26 + 26 + 18 = 70px center-to-center
    ('tree', 'bush'): 16,       # 26 + 14 + 16 = 56px (purely outside canopy)
    ('tree', 'solid'): 16,      # 26 + 15 + 16 = 57px (cleanly outside tree)
    ('tree', 'flower'): 12,     # 26 + 10 + 12 = 48px
    ('tree', 'crop'): 18,       # 26 + 12 + 18 = 56px
    ('tree', 'decor'): 14,      # 26 + 10 + 14 = 50px
    ('tree', 'ground'): 10,     # 26 + 8 + 10 = 44px

    ('bush', 'bush'): 16,       # 14 + 14 + 16 = 44px
    ('bush', 'solid'): 14,      # 14 + 15 + 14 = 43px
    ('bush', 'flower'): 12,     # 14 + 10 + 12 = 36px
    ('bush', 'crop'): 14,
    ('bush', 'decor'): 10,
    ('bush', 'ground'): 8,

    ('solid', 'solid'): 16,     # 15 + 15 + 16 = 46px
    ('solid', 'flower'): 10,    # 15 + 10 + 10 = 35px
    ('solid', 'crop'): 14,
    ('solid', 'decor'): 12,
    ('solid', 'ground'): 8,

    ('flower', 'flower'): 8,    # 10 + 10 + 8 = 28px
    ('flower', 'crop'): 10,
    ('flower', 'decor'): 8,
    ('flower', 'ground'): 6,

    ('crop', 'crop'): 4,        # 12 + 12 + 4 = 28px
    ('crop', 'decor'): 6,
    ('crop', 'ground'): 6,

    ('ground', 'ground'): 12,   # 8 + 8 + 12 = 28px
}

class SpatialPlacer:
    def __init__(self):
        self.placed = [] # [(x, y, radius, category)]

    def can_place(self, x, y, radius, category, buf_path, buf_water, buf_bld, buf_bridge=32):
        if not is_valid_land(x, y): return False
        if is_near_path(x, y, buffer_px=buf_path): return False
        if is_near_bridge(x, y, buffer_px=buf_bridge): return False
        if is_in_water_or_coast(x, y, buffer_px=buf_water): return False
        if is_in_building(x, y, buffer_px=buf_bld): return False

        for ex, ey, erad, ecat in self.placed:
            key = (category, ecat) if (category, ecat) in SEPARATION_MATRIX else (ecat, category)
            min_sep = SEPARATION_MATRIX.get(key, 10)
            if math.hypot(x - ex, y - ey) < (radius + erad + min_sep):
                return False
        return True

    def record(self, x, y, radius, category):
        self.placed.append((x, y, radius, category))

placer = SpatialPlacer()

trees = []        # (name, tex_path, x, y, scale, col_radius, col_offset_y)
bushes = []       # (name, tex_path, x, y, scale)
flowers = []      # (name, tex_path, x, y, scale)
water_lilies = [] # (name, tex_path, x, y, scale)
solids = []       # (name, tex_path, x, y, scale, fp_w, fp_h, off_y)
decors = []       # (name, tex_path, x, y, scale)

def add_tree(x, y, t_type=None):
    if not placer.can_place(x, y, 26, 'tree', buf_path=30, buf_water=16, buf_bld=26, buf_bridge=36):
        return False
    if t_type is None:
        r = random.random()
        if r < 0.35: t_type = 'tree_pine'
        elif r < 0.65: t_type = 'tree_oak'
        elif r < 0.80: t_type = 'tree_deciduous'
        elif r < 0.90: t_type = 'tree_cf_oak'
        else: t_type = 'cherry_tree'

    if t_type == 'tree_cf_oak':
        tex_path = "res://assets/Cute_Fantasy_Free/Outdoor decoration/Oak_Tree.png"
        scale = 1.25
        col_rad = 8.0
        col_off = 26.0
    elif t_type in ['tree_village_1', 'tree_village_2']:
        num = 1 if t_type == 'tree_village_1' else 2
        tex_path = f"res://assets/village_top_down/TILESET VILLAGE TOP DOWN/TREE {num} - DAY.png"
        scale = 1.8
        col_rad = 8.0
        col_off = 16.0
    else:
        tex_path = f"res://assets/landmarks/{t_type}.png"
        scale = 1.6 if t_type == 'cherry_tree' else 1.8
        col_rad = 8.0
        col_off = 18.0 if t_type in ['tree_deciduous', 'tree_pine'] else (22.0 if t_type == 'tree_oak' else 24.0)

    if is_near_path(x, y + col_off, buffer_px=18) or is_near_bridge(x, y + col_off, buffer_px=24):
        return False

    placer.record(x, y, 26, 'tree')
    trees.append((f"Tree_{len(trees)}", tex_path, int(x), int(y), scale, col_rad, col_off))
    return True

def add_bush(x, y, b_type=None):
    if not placer.can_place(x, y, 14, 'bush', buf_path=18, buf_water=10, buf_bld=14, buf_bridge=24):
        return False
    b_types = [
        'flora_bush_dense', 'flora_bush_blueberries', 'flora_bush_orangeberries',
        'flora_bush_pinkflowers', 'flora_fern_tall', 'flora_fern_leafy',
        'flora_hosta_broadleaf', 'flora_hosta_blooming'
    ]
    if b_type is None:
        b_type = random.choice(b_types)
    tex_path = f"res://assets/flora/{b_type}.png"
    placer.record(x, y, 14, 'bush')
    bushes.append((f"Bush_{len(bushes)}", tex_path, int(x), int(y), 1.7))
    return True

def add_flower(x, y, f_type=None):
    if not placer.can_place(x, y, 10, 'flower', buf_path=14, buf_water=8, buf_bld=10, buf_bridge=18):
        return False
    f_types = [
        'flora_lavender_purple', 'flora_lupine_blue', 'flora_lupine_pink', 'flora_lupine_purple',
        'flora_daffodil_yellow', 'flora_daffodil_orange', 'flora_daisy_cluster', 'flora_daisy_tall',
        'flora_foxglove_tall', 'flora_buttercup_mound', 'flora_clover_flowers', 'flora_clover_pink',
        'flora_strawberry_patch'
    ]
    if f_type is None:
        f_type = random.choice(f_types)
    tex_path = f"res://assets/flora/{f_type}.png"
    placer.record(x, y, 10, 'flower')
    flowers.append((f"Flower_{len(flowers)}", tex_path, int(x), int(y), 1.6))
    return True

def add_solid(name_prefix, tex_path, x, y, scale=1.8, fp_w=24, fp_h=16, off_y=0):
    if not placer.can_place(x, y, 15, 'solid', buf_path=22, buf_water=10, buf_bld=16, buf_bridge=30):
        return False
    if is_near_path(x, y + off_y, buffer_px=18) or is_near_bridge(x, y + off_y, buffer_px=24):
        return False
    placer.record(x, y, 15, 'solid')
    solids.append((f"{name_prefix}_{len(solids)}", tex_path, int(x), int(y), scale, fp_w, fp_h, off_y))
    return True

def add_decor(name_prefix, tex_path, x, y, scale=1.6, category='decor'):
    rad = 12 if category == 'crop' else 10
    buf_p = 12 if category == 'crop' else 8
    if not placer.can_place(x, y, rad, category, buf_path=buf_p, buf_water=8, buf_bld=8, buf_bridge=20):
        return False
    placer.record(x, y, rad, category)
    decors.append((f"{name_prefix}_{len(decors)}", tex_path, int(x), int(y), scale))
    return True

def add_ground_detail(x, y, tex_path):
    if not placer.can_place(x, y, 8, 'ground', buf_path=6, buf_water=6, buf_bld=6, buf_bridge=16):
        return False
    placer.record(x, y, 8, 'ground')
    decors.append((f"GroundDetail_{len(decors)}", tex_path, int(x), int(y), 1.6))
    return True

def try_place(target_count, x_range, y_range, fn, max_tries=400):
    placed = 0
    for _ in range(max_tries):
        if placed >= target_count:
            break
        rx = random.randint(*x_range)
        ry = random.randint(*y_range)
        if fn(rx, ry):
            placed += 1
    return placed

# =========================================================================
# 1. KURTOS PLAZA & CIVIC CENTER (ref_center_zoom.png)
# =========================================================================
# Tree Enclosure North border
for px in range(1760, 2400, 68):
    if not (1940 <= px <= 2180):
        add_tree(px, 710, 'tree_deciduous')
# West border
for py in range(760, 1420, 68):
    if not (1080 <= py <= 1200):
        add_tree(1740, py, 'tree_oak')
# East border
for py in range(760, 1420, 68):
    if not (1080 <= py <= 1200):
        add_tree(2400, py, 'tree_oak')
# South border
for px in range(1780, 2380, 68):
    if not (2000 <= px <= 2120):
        add_tree(px, 1390, 'tree_deciduous')

# Shrub borders outside plaza trees
for px in range(1770, 2390, 48):
    if not (1920 <= px <= 2200):
        add_bush(px, 660, 'flora_bush_dense')
        add_bush(px, 1440, 'flora_bush_dense')

# Plaza Corners Streetlamps (4 lamps)
for lx, ly in [(1830, 960), (2280, 960), (1830, 1300), (2280, 1300)]:
    add_solid(f"PlazaLamp_{lx}_{ly}", "res://assets/objects/decor/streetlamp.png", lx, ly, 1.8, 12, 10, 18)

# Plaza Flowerbeds
for fx in [1950, 1980, 2130, 2160]:
    for fy in [1060, 1190]:
        add_flower(fx, fy, 'flora_daisy_cluster')
        add_flower(fx, fy + 26, 'flora_buttercup_mound')

# Town building doorsteps potted tulips
potted_spots = [
    (1805, 1080), (1895, 1080), # Merchant Shop
    (1805, 1310), (1895, 1310), # Watchmaker
    (2225, 1080), (2315, 1080), # Doctor Clinic
    (2225, 1310), (2315, 1310), # Mayor Residence
    (2475, 1310), (2565, 1310), # Library
    (1055, 1010), (1145, 1010), # Bakery
    (1055, 1920), (1145, 1920), # Tavern
    (1355, 1010), (1445, 1010), # Florist
]
for px, py in potted_spots:
    p_tex = "res://assets/objects/decor/potted_tulip_red.png" if random.random() < 0.5 else "res://assets/objects/decor/potted_tulip_yellow.png"
    add_decor("PottedFlower", p_tex, px, py, 1.6)

# =========================================================================
# 2. NORTH MOUNTAIN PINE RIDGE & SCHOLAR ACADEMY
# =========================================================================
try_place(40, (700, 2600), (120, 500), lambda x, y: add_tree(x, y, 'tree_pine'))
try_place(25, (700, 2600), (140, 520), lambda x, y: add_bush(x, y, 'flora_fern_tall'))
try_place(15, (700, 2600), (140, 520), lambda x, y: add_solid("MountainBoulder", "res://assets/flora/flora_boulder_buttercups.png", x, y, 1.8, 24, 16, 4))

# Smuggler Cave (x=580, y=520)
for _ in range(8):
    rx = 580 + random.randint(-110, 110)
    ry = 520 + random.randint(-70, 70)
    add_solid("CaveRock", "res://assets/objects/decor/rocky_boulder.png", rx, ry, 1.8, 20, 14, 2)
    add_flower(rx + 16, ry + 16, 'flora_exotic_fungus')

# =========================================================================
# 3. ROYAL CITADEL FOREST (NORTHEAST)
# =========================================================================
try_place(45, (2800, 3750), (180, 780), lambda x, y: add_tree(x, y, 'cherry_tree' if random.random() < 0.35 else ('tree_pine' if random.random() < 0.65 else 'tree_cf_oak')))
try_place(25, (2800, 3750), (180, 780), lambda x, y: add_bush(x, y, 'flora_bush_pinkflowers'))
try_place(20, (2800, 3750), (180, 780), lambda x, y: add_flower(x, y, 'flora_lupine_purple'))

# =========================================================================
# 4. WEST VILLAGE RESIDENTIAL & CANAL
# =========================================================================
# Florist Greenhouse garden (x=1400, y=960)
for _ in range(24):
    fx = 1400 + random.randint(-90, 90)
    fy = 960 + random.randint(-90, 90)
    f_type = random.choice(['flora_lavender_purple', 'flora_lupine_blue', 'flora_daffodil_yellow', 'flora_potted_herbs'])
    add_flower(fx, fy, f_type)

# Bakery garden (x=1100, y=960)
add_tree(1020, 870, 'cherry_tree')
for _ in range(14):
    fx = 1100 + random.randint(-80, 80)
    fy = 960 + random.randint(-80, -25)
    add_flower(fx, fy, 'flora_strawberry_patch')

# Lumberjack Lodge timber stacks
for lx, ly in [(1340, 470), (1375, 470), (1450, 470), (1485, 470)]:
    add_solid("TimberLog", "res://assets/objects/decor/timber_log.png", lx, ly, 1.8, 28, 12, 0)

# Village residential trees & shrubs
try_place(28, (920, 1180), (750, 2050), lambda x, y: add_tree(x, y, random.choice(['tree_oak', 'tree_village_1', 'tree_village_2'])))
try_place(28, (1320, 1560), (750, 2050), lambda x, y: add_tree(x, y, random.choice(['tree_oak', 'tree_village_1', 'tree_village_2'])))
try_place(25, (920, 1560), (750, 2050), lambda x, y: add_bush(x, y, 'flora_bush_dense'))
try_place(25, (920, 1560), (750, 2050), lambda x, y: add_flower(x, y, 'flora_daisy_cluster'))

# West canal banks (x: 600..750, y: 860..1380)
try_place(10, (620, 740), (860, 1380), lambda x, y: add_tree(x, y, 'tree_oak'))
try_place(8, (620, 740), (860, 1380), lambda x, y: add_solid("CanalRock", "res://assets/objects/decor/smooth_stone.png", x, y, 2.0, 16, 12, 2))
try_place(8, (620, 740), (860, 1380), lambda x, y: add_bush(x, y, 'flora_fern_leafy'))

# Southwest coast & beach
try_place(18, (450, 750), (1550, 2350), lambda x, y: add_tree(x, y, 'tree_pine'))
try_place(12, (450, 750), (1550, 2350), lambda x, y: add_solid("BeachBoulder", "res://assets/village_top_down/foliage/grass_boulder.png", x, y, 2.0, 18, 12, 2))

# =========================================================================
# 5. EAST FARMLAND VALLEY & WINDMILL MEADOW
# =========================================================================
# Plot 1: Wheat Field (x: 2860..3010, y: 1180..1320)
for cx in range(2860, 3020, 32):
    for cy in range(1180, 1320, 28):
        add_decor("CropsWheat", "res://assets/landmarks/crops_wheat.png", cx, cy, 1.8, category='crop')

# Plot 2: Carrot Field (x: 3160..3310, y: 1180..1250)
for cx in range(3160, 3310, 32):
    for cy in range(1180, 1250, 28):
        add_decor("CropsCarrot", "res://assets/landmarks/crops_carrots.png", cx, cy, 1.8, category='crop')

# Plot 3: Greens Field (x: 3160..3310, y: 1260..1330)
for cx in range(3160, 3310, 32):
    for cy in range(1260, 1330, 28):
        add_decor("CropsGreens", "res://assets/landmarks/crops_greens.png", cx, cy, 1.8, category='crop')

# Farm signs & sacks
add_decor("SignWheat", "res://assets/objects/decor/sign_wheat.png", 2850, 1160, 1.8)
add_decor("SackWheat", "res://assets/objects/decor/sack_wheat.png", 2870, 1160, 1.8)
add_decor("SignCarrot", "res://assets/objects/decor/sign_carrot.png", 3150, 1160, 1.8)
add_decor("SackCarrot", "res://assets/objects/decor/sack_carrot.png", 3170, 1160, 1.8)

# Fences around plots
for fx in range(2860, 3020, 58):
    add_solid("FarmFence1", "res://assets/landmarks/fences_wood.png", fx, 1165, 1.8, 50, 16, 0)
for fx in range(3160, 3310, 58):
    add_solid("FarmFence2", "res://assets/landmarks/fences_wood.png", fx, 1165, 1.8, 50, 16, 0)

# Beekeeper Apiary Wildflowers
for _ in range(25):
    bx = 3550 + random.randint(-110, 110)
    by = 1420 + random.randint(-80, 80)
    add_flower(bx, by, random.choice(['flora_clover_flowers', 'flora_buttercup_mound', 'flora_lavender_purple']))

# Windmill surroundings
add_tree(3550, 1050, 'tree_oak')
for _ in range(14):
    wx = 3450 + random.randint(-80, 80)
    wy = 1120 + random.randint(-80, 80)
    add_flower(wx, wy, 'flora_buttercup_mound')

# Deep Stone Mine (x: 3440, y: 2100)
for _ in range(10):
    mx = 3440 + random.randint(-110, 110)
    my = 2100 + random.randint(-60, 60)
    add_solid("MineOre", random.choice(["res://assets/objects/decor/gold_ore.png", "res://assets/objects/decor/blue_ore.png", "res://assets/objects/decor/iron_ingot.png"]), mx, my, 1.8, 16, 12, 0)

# Farmland groves & hedgerows
try_place(25, (2800, 3600), (950, 1950), lambda x, y: add_tree(x, y, 'tree_cf_oak'))
try_place(20, (2800, 3600), (950, 1950), lambda x, y: add_bush(x, y, 'flora_bush_dense'))

# =========================================================================
# 6. SOUTHERN ARRIVAL BRIDGE & RIVER WATERFALL (SCREENSHOT REGION FIX)
# =========================================================================
# Welcoming gate streetlamps
add_solid("BridgeLamp_Left", "res://assets/objects/decor/streetlamp.png", 2000, 2370, 1.8, 12, 10, 18)
add_solid("BridgeLamp_Right", "res://assets/objects/decor/streetlamp.png", 2096, 2370, 1.8, 12, 10, 18)

# Framing trees around arrival gate
add_tree(1920, 2380, 'tree_pine')
add_tree(2180, 2380, 'tree_pine')

# Center Pond Islet Pine Tree (matching reference map!)
add_tree(1728, 2016, 'tree_pine')

# Riverbank woodland grove: Clean, spaced trees with generous clearance to path and river!
river_tree_coords = [
    (1850, 1930), (1890, 2040), (1830, 2140), (1890, 2220), (1840, 2310),
    (1510, 2240), (1500, 2350), (1660, 2350), (1740, 2430), (1800, 2450)
]
for rx, ry in river_tree_coords:
    add_tree(rx, ry, 'tree_pine' if random.random() < 0.6 else 'tree_oak')

# Clean ground shrubs and river rocks - strictly spaced and placed independently
shrub_types = ['flora_fern_leafy', 'flora_bush_dense', 'flora_hosta_broadleaf', 'flora_bush_blueberries']
try_place(6, (1700, 1950), (2000, 2400), lambda x, y: add_bush(x, y, random.choice(shrub_types)))
try_place(6, (1500, 1950), (2000, 2450), lambda x, y: add_solid("RiverRock", "res://assets/objects/decor/smooth_stone.png", x, y, 2.0, 16, 12, 2))
flower_types = ['flora_daisy_cluster', 'flora_clover_flowers', 'flora_lupine_blue', 'flora_buttercup_mound']
try_place(6, (1700, 1950), (2000, 2400), lambda x, y: add_flower(x, y, random.choice(flower_types)))

# =========================================================================
# 7. NATURAL GROVES & MEADOWS
# =========================================================================
# NW Meadow
try_place(14, (520, 980), (560, 840), lambda x, y: add_tree(x, y, 'tree_pine'))
try_place(12, (520, 980), (560, 840), lambda x, y: add_bush(x, y, 'flora_fern_tall'))

# Central East Meadow
try_place(16, (2460, 2780), (600, 1020), lambda x, y: add_tree(x, y, 'tree_village_1'))
try_place(14, (2460, 2780), (600, 1020), lambda x, y: add_bush(x, y, 'flora_bush_dense'))

# SE Valley
try_place(16, (2380, 3080), (1680, 2320), lambda x, y: add_tree(x, y, 'tree_oak'))
try_place(14, (2380, 3080), (1680, 2320), lambda x, y: add_bush(x, y, 'flora_bush_blueberries'))

# SW Pines
try_place(14, (660, 940), (1460, 1840), lambda x, y: add_tree(x, y, 'tree_pine'))
try_place(12, (660, 940), (1460, 1840), lambda x, y: add_bush(x, y, 'flora_bush_dense'))

# Forest clearing stumps, roots & mushrooms
for _ in range(16):
    lx = random.choice([random.randint(700, 2600), random.randint(2800, 3700), random.randint(1400, 1900)])
    ly = random.choice([random.randint(150, 480), random.randint(200, 750), random.randint(1850, 2400)])
    stump_tex = random.choice(["res://assets/flora/flora_stump_mossy.png", "res://assets/objects/decor/stump_roots.png"])
    add_solid("MossyStump", stump_tex, lx, ly, 1.6, 20, 14, 0)

for _ in range(14):
    lx = random.choice([random.randint(700, 2600), random.randint(2800, 3700), random.randint(1400, 1900)])
    ly = random.choice([random.randint(150, 480), random.randint(200, 750), random.randint(1850, 2400)])
    add_decor("RedMushroom", "res://assets/objects/decor/red_mushroom.png", lx, ly, 1.8)

# =========================================================================
# 8. SPARSE & NATURAL WATER LILIES (LOTUS LEAFS)
# =========================================================================
curated_water_lilies = [
    # Central River: only 3 spaced widely along the entire river
    (1690, 2030),
    (1580, 2210),
    (1640, 2410),
    # West Canal / Footbridge 2: only 2
    (650, 930),
    (690, 1370),
    # East Wetland Lake: 6 in 3 natural pairs near reeds
    (2680, 1480), (2715, 1495),
    (3050, 1550), (3085, 1565),
    (2850, 1720), (2885, 1735),
    # Northeast Castle Moat: only 2
    (2460, 620), (2495, 635),
    # Smuggler tidepool: only 1
    (490, 480),
]
for lx, ly in curated_water_lilies:
    water_lilies.append((f"WaterLily_{len(water_lilies)}", "res://assets/flora/flora_water_lilies.png", lx, ly, 1.5))

# =========================================================================
# 9. MICRO GROUND DETAILS ACROSS MEADOWS & PATH EDGES
# =========================================================================
detail_types = [
    'res://assets/village_top_down/foliage/grass_tuft_tall.png',
    'res://assets/village_top_down/foliage/grass_clover.png',
    'res://assets/village_top_down/foliage/grass_wildflower_gold.png',
    'res://assets/village_top_down/foliage/grass_wildflower_blue.png',
    'res://assets/village_top_down/details/pebbles_1.png',
    'res://assets/village_top_down/details/pebbles_2.png',
    'res://assets/village_top_down/details/stone_paver_1.png',
    'res://assets/village_top_down/details/stone_paver_2.png',
]
for _ in range(500):
    dx = random.randint(300, 3800)
    dy = random.randint(200, 2550)
    d_tex = random.choice(detail_types)
    add_ground_detail(dx, dy, d_tex)

print("=== REFINED NON-INTERSECTING WORLD ENVIRONMENT GENERATED ===")
print(f"  Trees (Solid trunk):     {len(trees)}")
print(f"  Bushes:                  {len(bushes)}")
print(f"  Flowers & Herbs:         {len(flowers)}")
print(f"  Water Lilies (Sparse):   {len(water_lilies)}")
print(f"  Solids (Rocks/Fences):   {len(solids)}")
print(f"  Decor & Crops:           {len(decors)}")
total = len(trees) + len(bushes) + len(flowers) + len(water_lilies) + len(solids) + len(decors)
print(f"  TOTAL WORLD ELEMENTS:    {total}")

# Save JSON
env_data = {
    'trees': trees,
    'bushes': bushes,
    'flowers': flowers,
    'water_lilies': water_lilies,
    'solids': solids,
    'decors': decors,
}
with open('assets/maps/world_environment_data.json', 'w') as f:
    json.dump(env_data, f, indent=2)

print("✅ Saved assets/maps/world_environment_data.json with 0 intersections!")
