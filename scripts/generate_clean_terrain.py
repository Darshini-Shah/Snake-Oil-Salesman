
import json
import numpy as np
from PIL import Image
from collections import deque
from scipy.ndimage import binary_dilation, label

ref_path = '/home/raj/.gemini/antigravity-ide/brain/56d2e669-693e-45e2-8b77-d5b2aaf63263/.user_uploaded/media_1791696026504.jpg'
ref = Image.open(ref_path).convert('RGB')
W_tiles, H_tiles = 256, 176

ref_grid = ref.resize((W_tiles, H_tiles), Image.Resampling.LANCZOS)
arr = np.array(ref_grid)

# 1. Detect Ocean
# Ocean pixels in the reference image
is_ocean_color = (arr[:, :, 2] > 105) & (arr[:, :, 2] > arr[:, :, 0] + 25) & (arr[:, :, 1] < 165)

# Outer ocean flood fill from all image borders
outer_ocean = np.zeros((H_tiles, W_tiles), dtype=bool)
q = deque()
for y in range(H_tiles):
    for x in [0, W_tiles-1]:
        if is_ocean_color[y, x] and not outer_ocean[y, x]:
            outer_ocean[y, x] = True
            q.append((y, x))
for x in range(W_tiles):
    for y in [0, H_tiles-1]:
        if is_ocean_color[y, x] and not outer_ocean[y, x]:
            outer_ocean[y, x] = True
            q.append((y, x))

while q:
    cy, cx = q.popleft()
    for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
        ny, nx = cy + dy, cx + dx
        if 0 <= ny < H_tiles and 0 <= nx < W_tiles:
            if not outer_ocean[ny, nx] and is_ocean_color[ny, nx]:
                outer_ocean[ny, nx] = True
                q.append((ny, nx))

# Ensure outer border margin of 3 tiles is solid ocean
outer_ocean[:3, :] = True
outer_ocean[-3:, :] = True
outer_ocean[:, :3] = True
outer_ocean[:, -3:] = True

# Filter tiny detached land specks in the ocean (< 15 tiles)
is_land = ~outer_ocean
labeled_land, num_land = label(is_land)
counts = np.bincount(labeled_land.flat)
counts[0] = 0
main_land_idx = np.argmax(counts)
for idx, c in enumerate(counts):
    if idx > 0 and idx != main_land_idx and c < 15:
        outer_ocean[labeled_land == idx] = True

# Southern Bridge: x: 124..131, y: 148..175
bridge_cells = set()
for y in range(148, H_tiles):
    for x in range(124, 132):
        bridge_cells.add((x, y))
        outer_ocean[y, x] = False # bridge is not ocean

is_land = (~outer_ocean)
# Beach is a 2-tile border where land meets outer ocean
beach_mask = is_land & binary_dilation(outer_ocean, iterations=2)
# Exclude bridge from beach
for x, y in bridge_cells:
    beach_mask[y, x] = False

# Grass is remaining land
grass_mask = is_land & (~beach_mask)
for x, y in bridge_cells:
    grass_mask[y, x] = False

ground_cells = []
paths_cells = []

for y in range(H_tiles):
    for x in range(W_tiles):
        if (x, y) in bridge_cells:
            # Under bridge is water
            ground_cells.append([x, y, 0, 0, 0])
            # On top is wooden bridge deck
            if x == 124:
                paths_cells.append([x, y, 8, 0, 1]) # left railing
            elif x == 131:
                paths_cells.append([x, y, 8, 5, 1]) # right railing
            else:
                paths_cells.append([x, y, 8, 2, 1]) # middle wooden deck
        elif outer_ocean[y, x]:
            ground_cells.append([x, y, 0, 0, 0])    # Ocean water
        elif beach_mask[y, x]:
            ground_cells.append([x, y, 2, 0, 0])    # Sandy beach
        else:
            ground_cells.append([x, y, 1, 0, 0])    # Lush grass

# Greedy 2D rectangle merger for ocean collision shapes
def merge_mask_to_rects(mask, cell_size=16):
    grid = mask.copy()
    H, W = grid.shape
    rects = []
    
    for y in range(H):
        for x in range(W):
            if not grid[y, x]:
                continue
            x2 = x
            while x2 < W and grid[y, x2]:
                x2 += 1
            y2 = y + 1
            can_expand = True
            while y2 < H and can_expand:
                for k in range(x, x2):
                    if not grid[y2, k]:
                        can_expand = False
                        break
                if can_expand:
                    y2 += 1
            grid[y:y2, x:x2] = False
            rects.append([x * cell_size, y * cell_size, (x2 - x) * cell_size, (y2 - y) * cell_size])
    return rects

ocean_colliders = merge_mask_to_rects(outer_ocean, 16)

# Add bridge side rails and bottom stop to ocean_colliders
# Bridge x: 124..131 -> 1984 .. 2112 px. y: 148..175 -> 2368 .. 2816 px.
# Left rail
ocean_colliders.append([123 * 16, 148 * 16, 16, (H_tiles - 148) * 16])
# Right rail
ocean_colliders.append([132 * 16, 148 * 16, 16, (H_tiles - 148) * 16])
# Bottom end stop
ocean_colliders.append([124 * 16, (H_tiles - 1) * 16, 8 * 16, 16])

out_data = {
    'ground': ground_cells,
    'water': [],
    'paths': paths_cells,
    'cliffs': [],
    'coast_colliders': ocean_colliders,
    'water_colliders': []
}

with open('assets/maps/clean_map_cells.json', 'w') as f:
    json.dump(out_data, f)

print(f'Done! clean_map_cells.json generated:')
print(f'  Ground cells: {len(ground_cells)}')
print(f'  Bridge cells: {len(paths_cells)}')
print(f'  Ocean colliders: {len(ocean_colliders)}')
