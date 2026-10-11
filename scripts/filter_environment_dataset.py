import json, math

with open('assets/maps/world_environment_data.json') as f:
    env = json.load(f)

with open('assets/maps/clean_map_cells.json') as f:
    map_data = json.load(f)

path_tiles = set((c[0], c[1]) for c in map_data['paths'])

def is_too_close_to_path_or_bridge(cx, cy, buffer_px=18):
    # Footbridge 1
    if (1536 - 20 <= cx <= 1728 + 20 and 1904 - 20 <= cy <= 1968 + 20):
        return True
    # Footbridge 2
    if (704 - 20 <= cx <= 800 + 20 and 1120 - 20 <= cy <= 1296 + 20):
        return True
    # Southern Bridge
    if (1984 - 20 <= cx <= 2112 + 20 and 2360 <= cy <= 2816):
        return True
    # Path tiles
    tx, ty = int(cx // 16), int(cy // 16)
    rad = int(math.ceil(buffer_px / 16))
    for dy in range(-rad, rad + 1):
        for dx in range(-rad, rad + 1):
            if (tx + dx, ty + dy) in path_tiles:
                dist = math.hypot(cx - ((tx + dx)*16 + 8), cy - ((ty + dy)*16 + 8))
                if dist < buffer_px:
                    return True
    return False

# Filter trees
clean_trees = []
for t in env['trees']:
    name, tex, x, y, scale, rad, off_y = t
    if not is_too_close_to_path_or_bridge(x, y + off_y, buffer_px=20):
        clean_trees.append(t)

# Filter solids
clean_solids = []
for s in env['solids']:
    name, tex, x, y, scale, fp_w, fp_h, off_y = s
    if not is_too_close_to_path_or_bridge(x, y + off_y, buffer_px=18):
        clean_solids.append(s)

print(f"Trees: {len(env['trees'])} -> Clean: {len(clean_trees)} (removed {len(env['trees']) - len(clean_trees)})")
print(f"Solids: {len(env['solids'])} -> Clean: {len(clean_solids)} (removed {len(env['solids']) - len(clean_solids)})")

env['trees'] = clean_trees
env['solids'] = clean_solids

with open('assets/maps/world_environment_data.json', 'w') as f:
    json.dump(env, f, indent=2)

print("Saved filtered assets/maps/world_environment_data.json with 100% clean clearances!")
