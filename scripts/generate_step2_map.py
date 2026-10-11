import json
import numpy as np
from PIL import Image, ImageDraw
from collections import deque
from scipy.ndimage import binary_closing, label, binary_dilation

W, H = 256, 176

ref_path = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/media_1791703129301.jpg'
ref = Image.open(ref_path).convert('RGB')
arr = np.array(ref)
H_ref, W_ref, _ = arr.shape

# --- 1. OUTER OCEAN DETECTION VIA BORDER FLOOD-FILL ---
is_water_color = (arr[:, :, 2] > 105) & (arr[:, :, 2] > arr[:, :, 0] + 25) & (arr[:, :, 1] < 165)
outer_ocean_1024 = np.zeros((H_ref, W_ref), dtype=bool)
q = deque()
for y in range(H_ref):
    for x in [0, W_ref - 1]:
        if is_water_color[y, x] and not outer_ocean_1024[y, x]:
            outer_ocean_1024[y, x] = True
            q.append((y, x))
for x in range(W_ref):
    for y in [0, H_ref - 1]:
        if is_water_color[y, x] and not outer_ocean_1024[y, x]:
            outer_ocean_1024[y, x] = True
            q.append((y, x))

while q:
    cy, cx = q.popleft()
    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        ny, nx = cy + dy, cx + dx
        if 0 <= ny < H_ref and 0 <= nx < W_ref:
            if not outer_ocean_1024[ny, nx] and is_water_color[ny, nx]:
                outer_ocean_1024[ny, nx] = True
                q.append((ny, nx))

im_ocean_256 = Image.fromarray((outer_ocean_1024 * 255).astype(np.uint8)).resize((W, H), Image.Resampling.NEAREST)
outer_ocean = np.array(im_ocean_256) > 128

# Solid 3-tile ocean border
outer_ocean[:3, :] = True
outer_ocean[-3:, :] = True
outer_ocean[:, :3] = True
outer_ocean[:, -3:] = True

is_land = ~outer_ocean
labeled_land, num_land = label(is_land)
counts = np.bincount(labeled_land.flat)
counts[0] = 0
main_land_idx = np.argmax(counts)
for idx, c in enumerate(counts):
    if idx > 0 and idx != main_land_idx and c < 15:
        outer_ocean[labeled_land == idx] = True

is_land = ~outer_ocean
near_ocean = is_land & binary_dilation(outer_ocean, iterations=2)

# --- 2. ORGANIC NATURAL WATER BODIES ---
# Drawn with smooth, natural curves calibrated to reference artwork
water_img = Image.new('L', (W, H), 0)
d_wat = ImageDraw.Draw(water_img)

# A. SW Pond & Islet
d_wat.ellipse([91, 97, 115, 117], fill=255)
d_wat.ellipse([88, 102, 106, 115], fill=255)
# Natural pine tree islet in pond center
d_wat.ellipse([102, 104, 106, 108], fill=0)

# B. SW River (flows south under Footbridge 1 to cliff waterfall)
sw_river_pts = [
    (102, 115), (102, 121), (99, 126), (94, 131), (98, 135), (107, 138), (109, 143), (108, 150)
]
for i in range(len(sw_river_pts) - 1):
    d_wat.line([sw_river_pts[i], sw_river_pts[i+1]], fill=255, width=6)
for pt in sw_river_pts:
    d_wat.ellipse([pt[0]-3, pt[1]-3, pt[0]+3, pt[1]+3], fill=255)

# C. SE Wetlands & River
# Upper wetland pond
d_wat.ellipse([165, 90, 184, 103], fill=255)
# Lower wetland lake
d_wat.ellipse([160, 104, 196, 117], fill=255)
d_wat.ellipse([156, 107, 175, 115], fill=255)
d_wat.line([(174, 97), (176, 107)], fill=255, width=6)

# SE River through the rocky gorge
se_river_pts = [
    (168, 113), (165, 118), (162, 124), (158, 131), (154, 137), (149, 144), (146, 150)
]
for i in range(len(se_river_pts) - 1):
    d_wat.line([se_river_pts[i], se_river_pts[i+1]], fill=255, width=5)
for pt in se_river_pts:
    d_wat.ellipse([pt[0]-2, pt[1]-2, pt[0]+2, pt[1]+2], fill=255)

# D. West Inlet & Village Canal
# Ocean inlet bay opening to the west
d_wat.ellipse([34, 69, 45, 78], fill=255)
# Water directly under Footbridge 2 (connects inlet to canal)
d_wat.rectangle([44, 73, 49, 78], fill=255)
# Village canal curving east behind the houses
west_canal_pts = [
    (49, 75), (55, 75), (59, 78), (62, 82), (58, 86), (51, 86)
]
for i in range(len(west_canal_pts) - 1):
    d_wat.line([west_canal_pts[i], west_canal_pts[i+1]], fill=255, width=4)
for pt in west_canal_pts:
    d_wat.ellipse([pt[0]-2, pt[1]-2, pt[0]+2, pt[1]+2], fill=255)

# E. North Forest Pond
d_wat.ellipse([149, 36, 161, 49], fill=255)

# F. Orchard Pond
d_wat.ellipse([54, 98, 62, 106], fill=255)

# G. Kurtos Plaza Central Fountain (Fountain sits cleanly on stone plaza, no raw water cutouts)
# d_wat ellipse removed so the fountain rests naturally on paved cobblestones

# H. Cliff Waterfalls
water = np.array(water_img) > 128
for y in range(148, 154):
    water[y, 106:110] = True # SW waterfall mouth
    water[y, 144:148] = True # SE waterfall mouth

# Ensure outer ocean is kept separate from inland water
water[outer_ocean] = False

# --- 3. ROADS & PLAZA ---
roads_img = Image.new('L', (W, H), 0)
d_roads = ImageDraw.Draw(roads_img)
plaza = np.zeros((H, W), dtype=bool)

# Kurtos Town Plaza:
# Elegant paved stone courtyard in town center (x: 118..135, y: 62..78 = 18x17 tiles = 288x272px)
plaza[62:79, 118:136] = True

# Grand South Boulevard (from arrival bridge up into south plaza entrance)
# 3 tiles wide (48px)
d_roads.line([(126, 148), (126, 78)], fill=255, width=3)

# Northern Summit Road (from north plaza entrance up to Scholar Academy)
# 3 tiles wide (48px)
d_roads.line([(126, 62), (126, 26)], fill=255, width=3)
# Academy Forecourt:
d_roads.rectangle([120, 22, 132, 26], fill=255)

# Plaza Perimeter Roads (cozy 2-tile paths hugging the courtyard):
d_roads.line([(116, 61), (116, 79)], fill=255, width=2) # West plaza road (General Store & Watchmaker doorstep)
d_roads.line([(137, 61), (137, 79)], fill=255, width=2) # East plaza road (Clinic & Mayor doorstep)
d_roads.line([(116, 61), (137, 61)], fill=255, width=2) # North plaza road
d_roads.line([(116, 79), (137, 79)], fill=255, width=2) # South plaza road

# South Crossroads (branches east and west from Boulevard at y=134)
# 2 tiles wide (32px)
d_roads.line([(126, 134), (108, 121)], fill=255, width=2) # connects to Footbridge 1 East end
d_roads.line([(126, 134), (145, 134)], fill=255, width=2) # connects towards SE mine trail

# Western Village Roads (2 tiles wide = 32px):
# From Footbridge 1 West end (x=96, y=121) into village
d_roads.line([(96, 121), (77, 121)], fill=255, width=2)
# Main village avenue (x=77, from y=125 up to y=62)
d_roads.line([(77, 62), (77, 125)], fill=255, width=2)
# Village to Plaza connections (north and mid)
d_roads.line([(77, 62), (116, 62)], fill=255, width=2)
d_roads.line([(77, 75), (116, 75)], fill=255, width=2)
# Connects to Footbridge 2 south approach
d_roads.line([(77, 75), (47, 75)], fill=255, width=2)
d_roads.line([(47, 75), (47, 80)], fill=255, width=2)
# South street to coastal cottages and beach
d_roads.line([(77, 125), (77, 138)], fill=255, width=2)
d_roads.line([(77, 138), (34, 138)], fill=255, width=2)

# Roads North of Canal & Lighthouse (2 tiles wide):
d_roads.line([(47, 71), (24, 71)], fill=255, width=2) # Footbridge 2 north approach west to lighthouse
d_roads.line([(47, 71), (77, 71)], fill=255, width=2) # north village road
d_roads.line([(77, 71), (116, 71)], fill=255, width=2) # to plaza

# Eastern Highway, Farmlands & Mine Trail (2 tiles wide):
d_roads.line([(137, 75), (185, 75)], fill=255, width=2) # Plaza east to farmlands
d_roads.line([(185, 75), (215, 75)], fill=255, width=2) # north farm road
d_roads.line([(215, 75), (215, 115)], fill=255, width=2) # farm avenue
d_roads.line([(215, 115), (215, 132)], fill=255, width=2) # trail down to mine
d_roads.rectangle([212, 129, 218, 133], fill=255)        # mine entrance depot platform
d_roads.line([(215, 86), (236, 86)], fill=255, width=2) # east pier path
d_roads.line([(185, 75), (205, 34)], fill=255, width=2) # road up to Royal Citadel
d_roads.line([(205, 34), (205, 26)], fill=255, width=3) # castle gateway

roads = np.array(roads_img) > 128

# --- 4. BRIDGES & PIERS ---
bridge_cells = set()

# Footbridge 1 (horizontal over SW river: x: 96..108, y: 119..123)
# Width: 13 tiles (208px), Height: 5 tiles (80px)
footbridge_1 = []
for by in range(119, 124):
    for bx in range(96, 109):
        footbridge_1.append((bx, by))
        bridge_cells.add((bx, by))

# Footbridge 2 (vertical over West canal: x: 44..49, y: 70..80)
# Width: 6 tiles (96px), Height: 11 tiles (176px)
footbridge_2 = []
for by in range(70, 81):
    for bx in range(44, 50):
        footbridge_2.append((bx, by))
        bridge_cells.add((bx, by))

# Western Ocean Pier (x: 28..39, y: 65..68)
west_pier = []
for py in range(65, 69):
    for px in range(28, 40):
        west_pier.append((px, py))
        bridge_cells.add((px, py))

# Eastern Ocean Pier (x: 236..247, y: 84..87)
east_pier = []
for py in range(84, 88):
    for px in range(236, 248):
        east_pier.append((px, py))
        bridge_cells.add((px, py))

# Water flows under bridges
for (bx, by) in footbridge_1:
    if 99 <= bx <= 105:
        water[by, bx] = True

for (bx, by) in footbridge_2:
    if 73 <= by <= 77:
        water[by, bx] = True

# Roads and plaza don't overlap water (except on bridge decks)
for y in range(H):
    for x in range(W):
        if water[y, x] and (x, y) not in bridge_cells:
            roads[y, x] = False
            plaza[y, x] = False

# --- 5. TILEMAP CELL GENERATION ---
ground_cells = []
for y in range(H):
    for x in range(W):
        if outer_ocean[y, x]:
            ground_cells.append([x, y, 0, 0, 0]) # Deep Ocean Water
        elif water[y, x]:
            ground_cells.append([x, y, 0, 0, 0]) # Inland Water
        elif near_ocean[y, x]:
            ground_cells.append([x, y, 5, 0, 0]) # Sand
        else:
            ground_cells.append([x, y, 1, 0, 0]) # Grass

paths_cells = []
for y in range(H):
    for x in range(W):
        if (x, y) in bridge_cells:
            continue
        if plaza[y, x]:
            paths_cells.append([x, y, 3, 0, 0]) # Stone Paver
        elif roads[y, x]:
            paths_cells.append([x, y, 2, 0, 0]) # Sand / Dirt Road

# Southern Arrival Bridge (from y=148 down to 175, x: 124..131)
for y in range(148, H):
    for x in range(124, 132):
        if x == 124:
            paths_cells.append([x, y, 8, 0, 1]) # left rail
        elif x == 131:
            paths_cells.append([x, y, 8, 5, 1]) # right rail
        else:
            paths_cells.append([x, y, 8, 2, 1]) # deck

# Footbridge 1 (horizontal over SW river: x: 96..108, y: 119..123)
for (bx, by) in footbridge_1:
    if by == 119:
        paths_cells.append([bx, by, 8, 1, 0]) # top rail
    elif by == 123:
        paths_cells.append([bx, by, 8, 1, 2]) # bottom rail
    else:
        paths_cells.append([bx, by, 8, 2, 1]) # deck

# Footbridge 2 (vertical over West canal: x: 44..49, y: 70..80)
for (bx, by) in footbridge_2:
    if bx == 44:
        paths_cells.append([bx, by, 8, 0, 1]) # left rail
    elif bx == 49:
        paths_cells.append([bx, by, 8, 5, 1]) # right rail
    else:
        paths_cells.append([bx, by, 8, 2, 1]) # deck

# Western Ocean Pier
for (px, py) in west_pier:
    paths_cells.append([px, py, 8, 2, 1])

# Eastern Ocean Pier
for (px, py) in east_pier:
    paths_cells.append([px, py, 8, 2, 1])

# --- 6. COLLISION MESH GENERATION ---
def merge_mask_to_rects(mask, cell_size=16):
    grid = mask.copy()
    H_g, W_g = grid.shape
    rects = []
    for y in range(H_g):
        for x in range(W_g):
            if not grid[y, x]:
                continue
            x2 = x
            while x2 < W_g and grid[y, x2]:
                x2 += 1
            y2 = y + 1
            can_expand = True
            while y2 < H_g and can_expand:
                for k in range(x, x2):
                    if not grid[y2, k]:
                        can_expand = False
                        break
                if can_expand:
                    y2 += 1
            grid[y:y2, x:x2] = False
            rects.append([x * cell_size, y * cell_size, (x2 - x) * cell_size, (y2 - y) * cell_size])
    return rects

# A. Clear Bridge Corridors in outer_ocean to eliminate ANY stray coast colliders
# Southern Arrival Bridge walkway
for y in range(148, H):
    for x in range(124, 132):
        outer_ocean[y, x] = False

# Footbridge 2 corridor
outer_ocean[69:82, 44:50] = False
# West Pier corridor
outer_ocean[64:70, 27:41] = False
# East Pier corridor
outer_ocean[83:88, 235:248] = False

ocean_colliders = merge_mask_to_rects(outer_ocean, 16)
# Southern bridge side rails and bottom end stop
ocean_colliders.append([123 * 16, 148 * 16, 16, (H - 148) * 16])
ocean_colliders.append([132 * 16, 148 * 16, 16, (H - 148) * 16])
ocean_colliders.append([124 * 16, (H - 1) * 16, 8 * 16, 16])

# B. Internal Water Colliders (InlandWaterColliders)
# Exclude bridge walkways completely so players have wide, unblocked passage!
collidable_internal_water = water.copy()

# Zero out Footbridge 1 corridor (x: 95..109, y: 119..123)
collidable_internal_water[119:124, 95:110] = False

# Zero out Footbridge 2 corridor (x: 44..49, y: 69..81)
collidable_internal_water[69:82, 44:50] = False

# Zero out piers
for (px, py) in west_pier:
    collidable_internal_water[py, px] = False
for (px, py) in east_pier:
    collidable_internal_water[py, px] = False

water_colliders = merge_mask_to_rects(collidable_internal_water, 16)

out_data = {
    'ground': ground_cells,
    'water': [],
    'paths': paths_cells,
    'cliffs': [],
    'coast_colliders': ocean_colliders,
    'water_colliders': water_colliders
}

with open('assets/maps/clean_map_cells.json', 'w') as f:
    json.dump(out_data, f)

print('Generated Step 2 Map Data with Natural Organic Water & Working Bridges:')
print(f'  Ground cells: {len(ground_cells)}')
print(f'  Paths & Bridge cells: {len(paths_cells)}')
print(f'  Ocean colliders: {len(ocean_colliders)}')
print(f'  Inland Water colliders: {len(water_colliders)}')
