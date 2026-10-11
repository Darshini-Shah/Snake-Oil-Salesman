extends SceneTree

var frame_count := 0
var main: Node2D

func _init() -> void:
	print("▶ Testing Comprehensive Water & Bridge Collisions...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	main = main_scene.instantiate()
	root.add_child(main)
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	frame_count += 1
	if frame_count < 2:
		return

	print("▶ Physics space active. Running tests...")
	var player = main.get_node("Player") as CharacterBody2D
	assert(player != null, "Player exists")

	# --- TEST 1: FOOTBRIDGE 1 (Horizontal SW River Bridge: x: 96..108, y: 119..123) ---
	# Player starts on East road: tile x: 110, y: 121 (px: 1760, 1936)
	player.position = Vector2(110 * 16, 121 * 16)
	# Walk WEST 256px across the entire bridge to West road (tile x: 94)
	var col_fb1_west = player.move_and_collide(Vector2(-256, 0), true)
	assert(col_fb1_west == null, "Player walked WEST across Footbridge 1 with ZERO obstruction")
	print("  ✅ PASS: Player walked WEST across Footbridge 1 with ZERO obstruction")

	# Walk EAST 256px back across the entire bridge to East road
	player.position = Vector2(94 * 16, 121 * 16)
	var col_fb1_east = player.move_and_collide(Vector2(256, 0), true)
	assert(col_fb1_east == null, "Player walked EAST across Footbridge 1 with ZERO obstruction")
	print("  ✅ PASS: Player walked EAST across Footbridge 1 with ZERO obstruction")

	# Center player on Footbridge 1 deck and try to step NORTH into river
	player.position = Vector2(102 * 16, 121 * 16)
	var col_fb1_north = player.move_and_collide(Vector2(0, -64), true)
	assert(col_fb1_north != null, "Stepping north off Footbridge 1 into river is BLOCKED")
	print("  ✅ PASS: Stepping north off Footbridge 1 into river is BLOCKED by %s" % col_fb1_north.get_collider().name)

	# Center player on Footbridge 1 deck and try to step SOUTH into river
	var col_fb1_south = player.move_and_collide(Vector2(0, 64), true)
	assert(col_fb1_south != null, "Stepping south off Footbridge 1 into river is BLOCKED")
	print("  ✅ PASS: Stepping south off Footbridge 1 into river is BLOCKED by %s" % col_fb1_south.get_collider().name)

	# --- TEST 2: FOOTBRIDGE 2 (Vertical West Canal Bridge: x: 44..49, y: 70..80) ---
	# Deck center is at x: 46.5 (px: 744).
	# Player starts on North approach: tile x: 46.5, y: 68 (px: 744, 1088)
	player.position = Vector2(46 * 16 + 8, 68 * 16)
	# Walk SOUTH 224px across the entire bridge to South approach (tile y: 82)
	var col_fb2_south = player.move_and_collide(Vector2(0, 224), true)
	assert(col_fb2_south == null, "Player walked SOUTH across Footbridge 2 with ZERO obstruction")
	print("  ✅ PASS: Player walked SOUTH across Footbridge 2 with ZERO obstruction")

	# Walk NORTH 224px back across the entire bridge to North approach
	player.position = Vector2(46 * 16 + 8, 82 * 16)
	var col_fb2_north = player.move_and_collide(Vector2(0, -224), true)
	assert(col_fb2_north == null, "Player walked NORTH across Footbridge 2 with ZERO obstruction")
	print("  ✅ PASS: Player walked NORTH across Footbridge 2 with ZERO obstruction")

	# Center player on Footbridge 2 and try to step WEST into inlet
	player.position = Vector2(46 * 16 + 8, 75 * 16)
	var col_fb2_west = player.move_and_collide(Vector2(-64, 0), true)
	assert(col_fb2_west != null, "Stepping west off Footbridge 2 into inlet is BLOCKED")
	print("  ✅ PASS: Stepping west off Footbridge 2 into inlet is BLOCKED by %s" % col_fb2_west.get_collider().name)

	# Center player on Footbridge 2 and try to step EAST into canal
	var col_fb2_east = player.move_and_collide(Vector2(64, 0), true)
	assert(col_fb2_east != null, "Stepping east off Footbridge 2 into canal is BLOCKED")
	print("  ✅ PASS: Stepping east off Footbridge 2 into canal is BLOCKED by %s" % col_fb2_east.get_collider().name)

	# --- TEST 3: SOUTHERN ARRIVAL BRIDGE ---
	# Player starts on bridge pier: px: 2048, 2560
	player.position = Vector2(2048, 2560)
	var col_south_bridge = player.move_and_collide(Vector2(0, -200), true)
	assert(col_south_bridge == null, "Player walked north onto island from South Bridge with ZERO obstruction")
	print("  ✅ PASS: Player walked north from Southern Arrival Bridge with ZERO obstruction")

	# --- TEST 4: NATURAL WATER BODIES ARE IMPASSABLE ---
	# Attempt to walk into SW River from east bank
	player.position = Vector2(105 * 16, 138 * 16)
	var col_sw_river = player.move_and_collide(Vector2(48, 0), true)
	assert(col_sw_river != null, "SW River is solid and impassable")
	print("  ✅ PASS: SW River is solid and impassable")

	# Attempt to walk into SE Wetland Lake from west bank
	player.position = Vector2(160 * 16, 110 * 16)
	var col_se_lake = player.move_and_collide(Vector2(48, 0), true)
	assert(col_se_lake != null, "SE Wetland Lake is solid and impassable")
	print("  ✅ PASS: SE Wetland Lake is solid and impassable")

	print("\n-------------------------------------------------------")
	print("🏁 ALL NATURAL WATER & BRIDGE COLLISION TESTS PASSED!")
	print("-------------------------------------------------------")
	quit(0)
