extends SceneTree

func _init() -> void:
	print("▶ Generating Clean Autotiled IslandMap PackedScene...")
	
	var tileset: TileSet = load("res://assets/maps/island_tileset.tres")
	if tileset == null:
		push_error("Failed to load island_tileset.tres")
		quit(1)
		return
	
	var file := FileAccess.open("res://assets/maps/clean_map_cells.json", FileAccess.READ)
	if file == null:
		push_error("Failed to open clean_map_cells.json")
		quit(1)
		return
	
	var json_str := file.get_as_text()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_error("Failed to parse clean_map_cells.json")
		quit(1)
		return
	var map_data: Dictionary = json.data
	
	var island_map := Node2D.new()
	island_map.name = "IslandMap"
	island_map.set_script(load("res://scripts/island_map.gd"))
	
	# 1. GroundLayer (Ocean, Beach, Grass, Farmland)
	var ground_layer := TileMapLayer.new()
	ground_layer.name = "GroundLayer"
	ground_layer.tile_set = tileset
	island_map.add_child(ground_layer)
	ground_layer.owner = island_map
	
	for c in map_data.get("ground", []):
		ground_layer.set_cell(Vector2i(int(c[0]), int(c[1])), int(c[2]), Vector2i(int(c[3]), int(c[4])))
	
	# 2. WaterLayer (Lakes and streams)
	var water_layer := TileMapLayer.new()
	water_layer.name = "WaterLayer"
	water_layer.tile_set = tileset
	island_map.add_child(water_layer)
	water_layer.owner = island_map
	
	for c in map_data.get("water", []):
		water_layer.set_cell(Vector2i(int(c[0]), int(c[1])), int(c[2]), Vector2i(int(c[3]), int(c[4])))
	
	# 3. PathsLayer (Stone Plaza, Roads, Bridges, Stairs)
	var paths_layer := TileMapLayer.new()
	paths_layer.name = "PathsLayer"
	paths_layer.tile_set = tileset
	island_map.add_child(paths_layer)
	paths_layer.owner = island_map
	
	for c in map_data.get("paths", []):
		paths_layer.set_cell(Vector2i(int(c[0]), int(c[1])), int(c[2]), Vector2i(int(c[3]), int(c[4])))
	
	# 4. CliffLayer (Elevated crags)
	var cliff_layer := TileMapLayer.new()
	cliff_layer.name = "CliffLayer"
	cliff_layer.tile_set = tileset
	island_map.add_child(cliff_layer)
	cliff_layer.owner = island_map
	
	for c in map_data.get("cliffs", []):
		cliff_layer.set_cell(Vector2i(int(c[0]), int(c[1])), int(c[2]), Vector2i(int(c[3]), int(c[4])))
	
	# 5. CoastColliders (Deep Ocean Perimeter, Zero Land Overlap)
	var coast_node := StaticBody2D.new()
	coast_node.name = "CoastColliders"
	island_map.add_child(coast_node)
	coast_node.owner = island_map
	
	var raw_outer: Array = map_data.get("coast_colliders", [])
	if raw_outer.is_empty():
		raw_outer = [
			[0, 0, 2560, 60], [0, 60, 60, 440], [0, 740, 60, 1180],
			[2500, 0, 60, 480], [2500, 680, 60, 1240], [0, 1650, 1216, 270],
			[1344, 1650, 1216, 270], [1216, 1888, 128, 32]
		]
	
	for i in range(raw_outer.size()):
		var c = raw_outer[i]
		var col_shape := CollisionShape2D.new()
		col_shape.name = "CoastBarrier_%d" % (i + 1)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(float(c[2]), float(c[3]))
		col_shape.shape = shape
		col_shape.position = Vector2(float(c[0]), float(c[1])) + shape.size / 2.0
		coast_node.add_child(col_shape)
		col_shape.owner = island_map
	
	# 6. InlandWaterColliders (Lakes & Streams, Bridges Open)
	var lake_node := StaticBody2D.new()
	lake_node.name = "InlandWaterColliders"
	island_map.add_child(lake_node)
	lake_node.owner = island_map
	
	var raw_water: Array = map_data.get("water_colliders", [])
	if raw_water.is_empty():
		raw_water = [
			[536, 736, 64, 40], [536, 820, 64, 40], [970, 1140, 120, 48],
			[970, 1240, 120, 48], [1660, 800, 48, 120], [1580, 1050, 48, 120],
			[1520, 1200, 48, 100], [1130, 1560, 48, 48], [1390, 1560, 48, 48]
		]
	
	for i in range(raw_water.size()):
		var c = raw_water[i]
		var col_shape := CollisionShape2D.new()
		col_shape.name = "WaterBarrier_%d" % (i + 1)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(float(c[2]), float(c[3]))
		col_shape.shape = shape
		col_shape.position = Vector2(float(c[0]), float(c[1])) + shape.size / 2.0
		lake_node.add_child(col_shape)
		col_shape.owner = island_map
	
	# 7. MapZones (Landmark Area2D Triggers)
	var zones_container := Node2D.new()
	zones_container.name = "MapZones"
	island_map.add_child(zones_container)
	zones_container.owner = island_map
	
	var map_zone_script := load("res://scripts/map_zone.gd")
	var landmark_zones := [
		{"name": "ArrivalPier", "pos": Vector2(2048, 2560), "size": Vector2(300, 300), "title": "Southern Arrival Pier", "sub": "Gateway to Kurtos Island"},
		{"name": "TownPlaza", "pos": Vector2(2048, 1400), "size": Vector2(600, 450), "title": "Kurtos Town Plaza", "sub": "The Heart of Commerce"},
		{"name": "RoyalCitadel", "pos": Vector2(3300, 680), "size": Vector2(700, 550), "title": "Royal Citadel & Fortress", "sub": "Seat of the Crown Sovereign"},
		{"name": "Farmlands", "pos": Vector2(3280, 1280), "size": Vector2(700, 500), "title": "Golden Windmill & Farmlands", "sub": "Agricultural Valley"},
		{"name": "Lighthouse", "pos": Vector2(320, 1050), "size": Vector2(450, 450), "title": "Gull Rock Lighthouse", "sub": "Western Coastal Beacon"},
		{"name": "SmugglersGrotto", "pos": Vector2(560, 520), "size": Vector2(400, 320), "title": "Smuggler's Grotto", "sub": "Northwest Mountain Caverns"},
		{"name": "BlossomAcademy", "pos": Vector2(2048, 300), "size": Vector2(600, 400), "title": "Cherry Blossom Sanctuary", "sub": "Northern Scholar Academy"},
		{"name": "DeepStoneMine", "pos": Vector2(3400, 1950), "size": Vector2(550, 400), "title": "Deep Stone Mine", "sub": "Southeast Mineral Terrace"}
	]
	
	for z in landmark_zones:
		var zone_area := Area2D.new()
		zone_area.name = z["name"]
		zone_area.script = map_zone_script
		zone_area.set("zone_name", z["title"])
		zone_area.set("zone_subtitle", z["sub"])
		zone_area.position = z["pos"]
		
		zones_container.add_child(zone_area)
		zone_area.owner = island_map
		
		var cshape := CollisionShape2D.new()
		cshape.name = "CollisionShape2D"
		var box := RectangleShape2D.new()
		box.size = z["size"]
		cshape.shape = box
		zone_area.add_child(cshape)
		cshape.owner = island_map
	
	var packed := PackedScene.new()
	var err := packed.pack(island_map)
	if err != OK:
		push_error("Failed to pack IslandMap: %d" % err)
		quit(1)
		return
	
	err = ResourceSaver.save(packed, "res://scenes/island_map.tscn")
	if err != OK:
		push_error("Failed to save scenes/island_map.tscn: %d" % err)
		quit(1)
		return
	
	print("✅ Successfully built and saved clean res://scenes/island_map.tscn!")
	quit(0)
