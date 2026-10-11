extends SceneTree

func _init() -> void:
	print("▶ Testing Fresh Island World Layout (Terrain & Player)...")
	
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "scenes/main.tscn loads successfully")
	print("  ✅ PASS: scenes/main.tscn loads successfully")
	
	var main = main_scene.instantiate()
	root.add_child(main)
	
	# 1. Test IslandMap and TileMapLayers
	var ground = main.get_node_or_null("Ground")
	assert(ground != null, "Ground node exists")
	
	var island_map = ground.get_node_or_null("IslandMap")
	assert(island_map != null, "IslandMap node exists under Ground")
	print("  ✅ PASS: IslandMap node exists under Ground")
	
	var ground_layer: TileMapLayer = island_map.get_node_or_null("GroundLayer")
	assert(ground_layer != null, "GroundLayer TileMapLayer exists")
	assert(ground_layer.tile_set != null, "GroundLayer has tile_set assigned")
	print("  ✅ PASS: GroundLayer TileMapLayer exists with valid TileSet")
	
	var paths_layer: TileMapLayer = island_map.get_node_or_null("PathsLayer")
	assert(paths_layer != null, "PathsLayer TileMapLayer exists")
	assert(paths_layer.tile_set != null, "PathsLayer has tile_set assigned")
	print("  ✅ PASS: PathsLayer TileMapLayer exists for southern bridge")
	
	# Ocean water tile at (5, 5)
	var ocean_cell_source: int = ground_layer.get_cell_source_id(Vector2i(5, 5))
	assert(ocean_cell_source == 0, "Ocean perimeter has water tiles (source 0)")
	print("  ✅ PASS: Ocean perimeter has deep water tiling (source 0)")
	
	# Southern bridge wooden bridge tile at (128, 160)
	var bridge_cell_source: int = paths_layer.get_cell_source_id(Vector2i(128, 160))
	assert(bridge_cell_source == 8, "Southern Bridge has wooden bridge tiles (source 8)")
	print("  ✅ PASS: Southern Bridge has authentic wooden bridge tiling (source 8)")
	
	# 2. Test Coast and Ocean Colliders
	var coast = island_map.get_node_or_null("CoastColliders")
	assert(coast != null, "CoastColliders exists in IslandMap")
	assert(coast.get_child_count() >= 50, "CoastColliders has comprehensive ocean boundary shapes")
	print("  ✅ PASS: CoastColliders active with %d ocean boundary shapes" % coast.get_child_count())
	
	# 3. Test Smooth Camera
	var camera: Camera2D = main.get_node_or_null("SmoothCamera") as Camera2D
	assert(camera != null, "SmoothCamera node exists in main scene")
	assert(camera.position_smoothing_enabled, "SmoothCamera has position smoothing enabled")
	assert(camera.limit_right == 4096, "SmoothCamera limit_right matches map width (4096px)")
	assert(camera.limit_bottom == 2816, "SmoothCamera limit_bottom matches map height (2816px)")
	print("  ✅ PASS: SmoothCamera active with position smoothing and 4096x2816 map clamping")
	
	# 4. Test Player Spawn & Exploration
	var player = main.get_node_or_null("Player")
	assert(player != null, "Player exists")
	assert(player.position == Vector2(2048, 2560), "Player spawns at Southern Bridge (2048, 2560)")
	print("  ✅ PASS: Player spawns at Southern Bridge (2048, 2560) facing island")
	
	# 5. Test Characters Container
	var characters = main.get_node_or_null("Characters")
	assert(characters != null, "Characters node exists in main scene")
	assert(characters.get_child_count() >= 50, "Characters container has >= 50 populated island characters")
	print("  ✅ PASS: Characters container active with %d island inhabitants" % characters.get_child_count())

	# 6. Test UI & Joystick
	var ui = main.get_node_or_null("UI")
	assert(ui != null, "UI CanvasLayer exists")
	assert(ui.has_node("HUD"), "HUD exists")
	assert(ui.has_node("VirtualJoystick"), "VirtualJoystick exists")
	print("  ✅ PASS: HUD and VirtualJoystick active for desktop and mobile play")
	
	print("\n-------------------------------------------------------")
	print("🏁 ALL FRESH TERRAIN & PLAYER TESTS PASSED!")
	print("-------------------------------------------------------")
	quit(0)
