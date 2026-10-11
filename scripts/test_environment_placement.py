import json, random, math
from PIL import Image, ImageDraw

with open('assets/maps/clean_map_cells.json') as f:
    map_data = json.load(f)

# Set of path tiles (in 16px tile coords)
path_tiles = set((c[0], c[1]) for c in map_data['paths'])
# Set of ground tiles
ground_tiles = set((c[0], c[1]) for c in map_data['ground'])
# Water colliders: [x, y, w, h] in pixels
water_boxes = map_data['water_colliders']
coast_boxes = map_data['coast_colliders']

print(f"Ground tiles: {len(ground_tiles)}, Path tiles: {len(path_tiles)}, Water boxes: {len(water_boxes)}")
