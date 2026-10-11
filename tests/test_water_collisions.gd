extends SceneTree

var frame_count := 0
var main: Node2D

func _init() -> void:
	print("▶ Initializing Inland Water and Bridge Collision Test...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	main = main_scene.instantiate()
	root.add_child(main)
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	frame_count += 1
	# Wait 2 frames for PhysicsServer2D to bind bodies to the World2D physics space
	if frame_count < 2:
		return

	print("▶ Running Physics Tests in active Physics Space...")
	var ground = main.get_node("Ground")
	var island_map = ground.get_node("IslandMap")
	var inland_water = island_map.get_node_or_null("InlandWaterColliders")
	assert(inland_water != null, "InlandWaterColliders exists")
	print("  ✅ PASS: InlandWaterColliders node exists with %d shapes" % inland_water.get_child_count())

	var player = main.get_node("Player") as CharacterBody2D
	assert(player != null, "Player exists")

	# Test 1: Player at Footbridge 1 walkway (tile x: 98, tile y: 119 => 1568, 1904)
	player.position = Vector2(98 * 16, 119 * 16 + 8)
	var walk_collision = player.move_and_collide(Vector2(48, 0), true) # test collision eastward across bridge
	assert(walk_collision == null, "Player walks onto and across footbridge without collision")
	print("  ✅ PASS: Player walks freely onto Footbridge 1 with ZERO collision blocking")

	# Test 2: Player tries to walk into SW river from bank (tile x: 104, tile y: 138 => 1664, 2208)
	player.position = Vector2(104 * 16, 138 * 16)
	var water_collision = player.move_and_collide(Vector2(64, 0), true) # test collision east into river
	assert(water_collision != null, "Player blocked by water collision when moving into SW river")
	print("  ✅ PASS: Player is BLOCKED when attempting to enter SW river: collided with %s" % water_collision.get_collider().name)

	# Test 3: Player tries to walk into SE Wetland Lake (tile x: 172, tile y: 114 => 2752, 1824)
	player.position = Vector2(172 * 16, 114 * 16)
	var lake_collision = player.move_and_collide(Vector2(64, 0), true) # test collision east into lake
	assert(lake_collision != null, "Player blocked by wetland lake collision")
	print("  ✅ PASS: Player is BLOCKED when attempting to enter SE Wetland Lake: collided with %s" % lake_collision.get_collider().name)

	# Test 4: Player on Footbridge 1 trying to step off north into river
	player.position = Vector2(99 * 16, 119 * 16)
	var off_bridge_col = player.move_and_collide(Vector2(0, -48), true) # test collision north into river
	assert(off_bridge_col != null, "Player blocked from stepping off bridge into river")
	print("  ✅ PASS: Player is BLOCKED when attempting to step off Footbridge 1 into river: collided with %s" % off_bridge_col.get_collider().name)

	print("\n-------------------------------------------------------")
	print("🏁 ALL INLAND WATER & BRIDGE COLLISION TESTS PASSED!")
	print("-------------------------------------------------------")
	quit(0)
