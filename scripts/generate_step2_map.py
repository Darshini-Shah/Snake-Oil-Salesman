import json
import numpy as np
from PIL import Image
from collections import deque
from scipy.ndimage import binary_dilation, label

W, H = 256, 176

ref_path = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.tempmediaStorage/media_1791703129301.jpg'
ref = Image.open(ref_path).convert('RGB')
ref_grid = ref.resize((W, H), Image.Resampling.LANCZOS)
arr = np.array(ref_grid)

# --- 1. PURE OUTER OCEAN DETECTION ---
is_ocean_color = (arr[:, :, 2] > 105) & (arr[:, :, 2] > arr[:, :, 0] + 25) & (arr[:, :, 1] < 165)
outer_ocean = np.zeros((H, W), dtype=bool)
q = deque()
for y in range(H):
    for x in [0, W - 1]:
        if is_ocean_color[y, x] and not outer_ocean[y, x]:
            outer_ocean[y, x] = True
            q.append((y, x))
for x in range(W):
    for y in [0, H - 1]:
        if is_ocean_color[y, x] and not outer_ocean[y, x]:
            outer_ocean[y, x] = True
            q.append((y, x))

while q:
    cy, cx = q.popleft()
    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        ny, nx = cy + dy, cx + dx
        if 0 <= ny < H and 0 <= nx < W:
            if not outer_ocean[ny, nx] and is_ocean_color[ny, nx]:
                outer_ocean[ny, nx] = True
                q.append((ny, nx))

# Solid 3-tile ocean border
outer_ocean[:3, :] = True
outer_ocean[-3:, :] = True
outer_ocean[:, :3] = True
outer_ocean[:, -3:] = True

# Filter tiny detached land specks (< 15 tiles)
is_land = ~outer_ocean
labeled_land, num_land = label(is_land)
counts = np.bincount(labeled_land.flat)
counts[0] = 0
main_land_idx = np.argmax(counts)
for idx, c in enumerate(counts):
    if idx > 0 and idx != main_land_idx and c < 15:
        outer_ocean[labeled_land == idx] = True

# South Arrival Bridge is not ocean
for y in range(148, H):
    for x in range(124, 132):
        outer_ocean[y, x] = False

is_land = ~outer_ocean
near_ocean = is_land & binary_dilation(outer_ocean, iterations=2)

roads = np.zeros((H, W), dtype=bool)
plaza = np.zeros((H, W), dtype=bool)
water = np.zeros((H, W), dtype=bool)
bridge_cells = set() # Walkable bridge/pier cells

def add_rect(mask, x0, y0, x1, y1):
    x_min, x_max = max(0, min(x0, x1)), min(W - 1, max(x0, x1))
    y_min, y_max = max(0, min(y0, y1)), min(H - 1, max(y0, y1))
    mask[y_min:y_max+1, x_min:x_max+1] = True

def add_line(mask, x0, y0, x1, y1, width=3):
    length = int(np.hypot(x1 - x0, y1 - y0) * 2) + 1
    hw = width // 2
    for t in np.linspace(0, 1, length):
        cx = int(round(x0 + t * (x1 - x0)))
        cy = int(round(y0 + t * (y1 - y0)))
        for dy in range(-hw, hw + 1):
            for dx in range(-hw, hw + 1):
                nx, ny = cx + dx, cy + dy
                if 0 <= nx < W and 0 <= ny < H:
                    mask[ny, nx] = True

def add_ellipse(mask, cx, cy, rx, ry):
    for y in range(max(0, cy - ry), min(H, cy + ry + 1)):
        for x in range(max(0, cx - rx), min(W, cx + rx + 1)):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                mask[y, x] = True

# --- 2. INTERNAL WATER BODIES ---
# A. Southwest River & Waterfall
add_line(water, 108, 149, 108, 138, width=6)
add_line(water, 108, 138, 103, 126, width=5)
add_line(water, 103, 126, 100, 118, width=5)

# B. Southwest Pond (with green tree islet)
add_ellipse(water, 103, 108, 8, 9)
add_ellipse(water, 98, 110, 6, 7)
add_ellipse(water, 107, 106, 6, 7)
water[106:110, 101:105] = False # Central pine tree islet

# C. SW Pond upper inlet stream (behind houses)
add_line(water, 96, 104, 90, 98, width=4)
add_line(water, 90, 98, 86, 92, width=3)
add_ellipse(water, 86, 92, 3, 3)

# D. West Harbor Canal (near lighthouse & docks)
add_ellipse(water, 48, 55, 6, 5)
add_line(water, 48, 55, 36, 50, width=5) # ocean outlet
add_line(water, 50, 55, 58, 60, width=4)
add_ellipse(water, 58, 60, 4, 4)

# E. Southeast River & Waterfall
add_line(water, 145, 149, 145, 138, width=6)
add_line(water, 145, 138, 148, 130, width=5)
add_line(water, 148, 130, 158, 124, width=5)
add_line(water, 158, 124, 168, 118, width=6)

# F. Southeast Wetland Lake (multi-lobed marsh)
add_ellipse(water, 178, 118, 12, 6)
add_ellipse(water, 186, 116, 8, 5)
add_line(water, 170, 116, 168, 104, width=5)
add_ellipse(water, 168, 100, 5, 5)

# G. Northeast Forest Lily Pad Pond
add_ellipse(water, 164, 44, 6, 9)
add_ellipse(water, 150, 34, 4, 3)

# H. Northwest Mountain Stream
add_line(water, 72, 26, 64, 36, width=3)

# I. Plaza Fountain Pool
add_ellipse(water, 110, 78, 3, 3)

# --- 3. BRIDGES & PIERS ---
# Footbridge 1 over SW River (x: 96..103, y: 118..121)
footbridge_1 = []
for by in range(118, 122):
    for bx in range(96, 104):
        footbridge_1.append((bx, by))
        bridge_cells.add((bx, by))
        water[by, bx] = True # water flows beneath

# Footbridge 2 over West Canal (x: 48..53, y: 53..56)
footbridge_2 = []
for by in range(53, 57):
    for bx in range(48, 54):
        footbridge_2.append((bx, by))
        bridge_cells.add((bx, by))
        water[by, bx] = True # water flows beneath

# Western Ocean Pier (x: 32..43, y: 48..51)
west_pier = []
for py in range(48, 52):
    for px in range(32, 44):
        west_pier.append((px, py))
        bridge_cells.add((px, py))

# Eastern Ocean Pier (x: 236..247, y: 84..87)
east_pier = []
for py in range(84, 88):
    for px in range(236, 248):
        east_pier.append((px, py))
        bridge_cells.add((px, py))

# --- 4. ROAD NETWORKS & PLAZA ---
# A. Grand South Boulevard (8 tiles wide, aligned with south bridge x: 124..131)
add_rect(roads, 124, 118, 131, 148)

# B. Central Crossroads Hub
add_rect(roads, 123, 117, 132, 122)

# C. Central Town Plaza & Enclosing Streets
add_rect(roads, 124, 56, 129, 118) # East Boulevard
add_rect(roads, 88, 92, 125, 96)   # South Avenue
add_rect(roads, 88, 56, 93, 96)    # West Avenue
add_rect(roads, 88, 56, 125, 60)   # North Avenue
add_rect(plaza, 94, 61, 123, 91)   # Plaza Stone Pavers

# D. Northern Summit Road (Cherry Blossom Academy)
add_rect(roads, 125, 18, 130, 56)
add_rect(roads, 122, 18, 132, 24)  # Academy Forecourt
add_rect(roads, 58, 40, 125, 44)   # North cross-street

# E. Western Village Streets
add_rect(roads, 58, 40, 63, 136) # North-South Avenue
add_rect(roads, 28, 50, 32, 130) # Far-West Residential Street
# Cross-streets connecting from far west (x: 28) all the way across
add_rect(roads, 28, 56, 88, 60)  # North cross-street
add_rect(roads, 28, 92, 88, 96)  # Mid cross-street
add_rect(roads, 28, 126, 63, 130) # South cross-street
add_line(roads, 28, 128, 18, 138, width=4) # SW loop
add_line(roads, 28, 62, 12, 62, width=4)   # Lighthouse road
add_line(roads, 58, 40, 36, 30, width=4)   # NW Cave road
add_line(roads, 124, 119, 103, 119, width=4) # Crossroads to footbridge
add_line(roads, 96, 119, 63, 119, width=4)  # Footbridge to west avenue
add_line(roads, 58, 56, 53, 55, width=4)   # To canal footbridge
add_line(roads, 48, 55, 36, 48, width=4)   # To ocean pier

# F. Eastern Village, Castle Highway & Farmlands
# East-West Avenue from South Plaza (y: 92..96) going east
add_rect(roads, 129, 92, 172, 96)
# Southeast village street from crossroads (y: 118..122) going east to residential row
add_rect(roads, 131, 118, 155, 122)

# Castle Highway curving northeast from (165, 94) to Castle Forecourt
add_line(roads, 165, 94, 176, 80, width=5)
add_line(roads, 176, 80, 188, 64, width=5)
add_line(roads, 188, 64, 200, 52, width=5)
add_rect(roads, 194, 46, 218, 56) # Castle Forecourt

# Castle to Farm connection
add_rect(roads, 198, 56, 202, 66)

# Farmlands Roads & Grid
add_rect(roads, 172, 66, 226, 70)  # North farm road
add_rect(roads, 165, 85, 226, 88)  # Mid east-west farm road (connected to town avenue)
add_rect(roads, 172, 104, 226, 108) # South farm road
add_rect(roads, 170, 66, 174, 108) # West farm road
add_rect(roads, 197, 66, 201, 108) # Mid north-south farm road
add_rect(roads, 223, 66, 227, 108) # East farm road
add_line(roads, 227, 86, 246, 86, width=4) # East Wharf road

# Southeast Mine Trail
add_line(roads, 198, 108, 206, 116, width=4)
add_line(roads, 206, 116, 216, 124, width=4)
add_rect(roads, 214, 122, 224, 128) # Mine cave forecourt

# Clean up masks
water[outer_ocean] = False
roads[outer_ocean] = False
plaza[outer_ocean] = False

# Where roads and water intersect (except bridges), water cuts roads
for y in range(H):
    for x in range(W):
        if water[y, x] and (x, y) not in bridge_cells:
            roads[y, x] = False
            plaza[y, x] = False

near_ocean = near_ocean & (~water)

# --- 5. COMPOSE MAP TILES ---
ground_cells = []
for y in range(H):
    for x in range(W):
        if outer_ocean[y, x] or water[y, x]:
            ground_cells.append([x, y, 0, 0, 0]) # Water
        elif near_ocean[y, x]:
            ground_cells.append([x, y, 2, 0, 0]) # Sand
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

# Southern Bridge (from y=148 down to 175, x: 124..131)
for y in range(148, H):
    for x in range(124, 132):
        if x == 124:
            paths_cells.append([x, y, 8, 0, 1]) # left rail
        elif x == 131:
            paths_cells.append([x, y, 8, 5, 1]) # right rail
        else:
            paths_cells.append([x, y, 8, 2, 1]) # deck

# Footbridge 1 (horizontal over SW river: x: 96..103, y: 118..121)
for (bx, by) in footbridge_1:
    if by == 118:
        paths_cells.append([bx, by, 8, 1, 0]) # top rail
    elif by == 121:
        paths_cells.append([bx, by, 8, 1, 2]) # bottom rail
    else:
        paths_cells.append([bx, by, 8, 2, 1]) # deck

# Footbridge 2 (horizontal over West Canal: x: 48..53, y: 53..56)
for (bx, by) in footbridge_2:
    if by == 53:
        paths_cells.append([bx, by, 8, 1, 0])
    elif by == 56:
        paths_cells.append([bx, by, 8, 1, 2])
    else:
        paths_cells.append([bx, by, 8, 2, 1])

# Western Ocean Pier (x: 32..43, y: 48..51)
for (px, py) in west_pier:
    paths_cells.append([px, py, 8, 2, 1])

# Eastern Ocean Pier (x: 236..247, y: 84..87)
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

# A. Outer Ocean Colliders (CoastColliders)
ocean_colliders = merge_mask_to_rects(outer_ocean, 16)
# Southern bridge side rails and bottom end stop
ocean_colliders.append([123 * 16, 148 * 16, 16, (H - 148) * 16])
ocean_colliders.append([132 * 16, 148 * 16, 16, (H - 148) * 16])
ocean_colliders.append([124 * 16, (H - 1) * 16, 8 * 16, 16])

# B. Internal Water Colliders (InlandWaterColliders)
# Exclude bridge walkways (bridge_cells) so the player can cross freely!
collidable_internal_water = water.copy()
for (bx, by) in bridge_cells:
    collidable_internal_water[by, bx] = False

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

print('Generated Step 2 Map Data Successfully:')
print(f'  Ground cells: {len(ground_cells)}')
print(f'  Paths & Bridge cells: {len(paths_cells)}')
print(f'  Ocean colliders: {len(ocean_colliders)}')
print(f'  Inland Water colliders: {len(water_colliders)}')
