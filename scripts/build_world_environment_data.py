import json, random, math, os
from PIL import Image

# Load map data
with open('assets/maps/clean_map_cells.json') as f:
    map_data = json.load(f)

path_tiles = set((c[0], c[1]) for c in map_data['paths'])
ground_map = {(c[0], c[1]): c[2] for c in map_data['ground']} # (x, y) -> src_id
water_boxes = map_data['water_colliders']
coast_boxes = map_data['coast_colliders']

# Load buildings from build_world_buildings.gd
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

# Helper to check if a point (px, py) is on or very close to a path tile
def is_near_path(px, py, buffer_px=18):
    tx = int(px // 16)
    ty = int(py // 16)
    rad = int(math.ceil(buffer_px / 16))
    for dy in range(-rad, rad + 1):
        for dx in range(-rad, rad + 1):
            if (tx + dx, ty + dy) in path_tiles:
                # check euclidean distance to tile center
                tile_cx = (tx + dx) * 16 + 8
                tile_cy = (ty + dy) * 16 + 8
                dist = math.hypot(px - tile_cx, py - tile_cy)
                if dist < buffer_px:
                    return True
    return False

# Check if point is inside water or coast collider
def is_in_water_or_coast(px, py, buffer_px=6):
    for b in water_boxes + coast_boxes:
        bx, by, bw, bh = b
        if (bx - buffer_px) <= px <= (bx + bw + buffer_px) and (by - buffer_px) <= py <= (by + bh + buffer_px):
            return True
    return False

# Check if point is inside a building footprint or near its front door
def is_in_building(px, py, buffer_px=10):
    for bld in BUILDINGS:
        name, bx, by, bw, bh, fp_w, fp_h, off_y = bld
        # footprint
        f_left = bx - fp_w / 2 - buffer_px
        f_right = bx + fp_w / 2 + buffer_px
        f_top = by + off_y - fp_h / 2 - buffer_px
        f_bottom = by + off_y + fp_h / 2 + buffer_px + 20 # extra buffer in front of door
        if f_left <= px <= f_right and f_top <= py <= f_bottom:
            return True
    return False

# Check if ground tile exists and is land (not deep ocean water src 0)
def is_valid_land(px, py):
    tx = int(px // 16)
    ty = int(py // 16)
    src = ground_map.get((tx, ty), 0)
    return src != 0 # src 1=grass, 5=sand, 4=cliff

print("Spatial helper functions configured!")
