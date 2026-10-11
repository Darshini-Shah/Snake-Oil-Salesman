extends SceneTree

var frame_count := 0
var main: Node2D

func _init() -> void:
	print("▶ Testing Island Buildings Layout & Collisions...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "scenes/main.tscn loads successfully")
	main = main_scene.instantiate()
	root.add_child(main)
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	frame_count += 1
	if frame_count < 2:
		return

	print("▶ Physics space active. Running building tests...")
	var player = main.get_node("Player") as CharacterBody2D
	assert(player != null, "Player exists")

	# 1. Test Buildings container
	var buildings_node = main.get_node_or_null("Buildings")
	assert(buildings_node != null, "Buildings container exists in main scene")
	var count = buildings_node.get_child_count()
	assert(count >= 35, "Buildings container has >= 35 buildings (Actual: %d)" % count)
	print("  ✅ PASS: Buildings container active with %d diverse buildings" % count)

	# 2. Test Key Landmarks
	var required_landmarks = [
		"RoyalCastle",
		"ScholarAcademy",
		"SmugglerCave",
		"Lighthouse",
		"PlazaFountain",
		"Windmill",
		"MineEntrance",
		"TownHall",
		"MerchantShop",
		"ChurchBuilding",
		"BakeryBuilding",
		"BlacksmithHouse",
		"Tavern"
	]
	for bld_name in required_landmarks:
		var bld = buildings_node.get_node_or_null(bld_name)
		assert(bld != null, "Building '%s' exists" % bld_name)
		assert(bld is StaticBody2D, "Building '%s' is a StaticBody2D" % bld_name)
		var sprite = bld.get_node_or_null("Sprite2D") as Sprite2D
		assert(sprite != null and sprite.texture != null, "Building '%s' has a valid texture" % bld_name)
		print("  ✅ PASS: Landmark '%s' verified with valid sprite & collider" % bld_name)

	# 3. Test Building Collision Detection
	# Place player in front of Bakery doorstep and walk UP toward building
	var bakery = buildings_node.get_node("BakeryBuilding") as Node2D
	player.position = bakery.position + Vector2(0, 85)
	var col_up = player.move_and_collide(Vector2(0, -60), true)
	assert(col_up != null, "Walking into Bakery is blocked by collision")
	print("  ✅ PASS: Walking into Bakery is BLOCKED by %s" % col_up.get_collider().name)

	# 4. Test Unobstructed Movement Along Road beside Building
	# Road is at x: 1232 (West Village Avenue, adjacent to Bakery at x=1120)
	# Player walks freely NORTH along the avenue past the bakery
	player.position = Vector2(1232, bakery.position.y + 85)
	var col_road = player.move_and_collide(Vector2(0, -170), true)
	assert(col_road == null, "Player walks NORTH along road beside Bakery with ZERO obstruction")
	print("  ✅ PASS: Player walks freely along avenue beside Bakery with ZERO obstruction")

	print("\n-------------------------------------------------------")
	print("🏁 ALL ISLAND BUILDINGS TESTS PASSED!")
	print("-------------------------------------------------------")
	quit(0)
