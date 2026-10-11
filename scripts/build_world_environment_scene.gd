extends SceneTree

func _init() -> void:
	print("▶ Building World Environment Scene...")
	var file := FileAccess.open("res://assets/maps/world_environment_data.json", FileAccess.READ)
	if file == null:
		print("❌ Failed to open world_environment_data.json")
		quit(1)
		return

	var json_str := file.get_as_text()
	file.close()

	var data: Dictionary = JSON.parse_string(json_str)
	if data == null:
		print("❌ Failed to parse world_environment_data.json")
		quit(1)
		return

	var root := Node2D.new()
	root.name = "Environment"
	root.y_sort_enabled = true

	var tex_cache := {}
	var get_texture = func(path: String) -> Texture2D:
		if not tex_cache.has(path):
			tex_cache[path] = load(path)
		return tex_cache[path]

	# 1. Water Lilies (non-colliding, rendered under ground layer or flat on water)
	var water_lilies: Array = data.get("water_lilies", [])
	for wl in water_lilies:
		# [name, tex_path, x, y, scale]
		var s := Sprite2D.new()
		s.name = wl[0]
		s.texture = get_texture.call(wl[1])
		s.position = Vector2(wl[2], wl[3])
		s.scale = Vector2(wl[4], wl[4])
		s.z_as_relative = false
		s.z_index = 0
		root.add_child(s)
		s.owner = root

	# 2. Ground Decors & Micro Details
	var decors: Array = data.get("decors", [])
	for d in decors:
		# [name, tex_path, x, y, scale]
		var s := Sprite2D.new()
		s.name = d[0]
		s.texture = get_texture.call(d[1])
		s.position = Vector2(d[2], d[3])
		s.scale = Vector2(d[4], d[4])
		root.add_child(s)
		s.owner = root

	# 3. Flowers & Herbs
	var flowers: Array = data.get("flowers", [])
	for f in flowers:
		# [name, tex_path, x, y, scale]
		var s := Sprite2D.new()
		s.name = f[0]
		s.texture = get_texture.call(f[1])
		s.position = Vector2(f[2], f[3])
		s.scale = Vector2(f[4], f[4])
		root.add_child(s)
		s.owner = root

	# 4. Bushes
	var bushes: Array = data.get("bushes", [])
	for b in bushes:
		# [name, tex_path, x, y, scale]
		var s := Sprite2D.new()
		s.name = b[0]
		s.texture = get_texture.call(b[1])
		s.position = Vector2(b[2], b[3])
		s.scale = Vector2(b[4], b[4])
		root.add_child(s)
		s.owner = root

	# 5. Solids (Rocks, Boulders, Fences, Streetlamps, Logs, Stumps)
	var solids: Array = data.get("solids", [])
	for sol in solids:
		# [name, tex_path, x, y, scale, fp_w, fp_h, off_y]
		var body := StaticBody2D.new()
		body.name = sol[0]
		body.position = Vector2(sol[2], sol[3])

		var s := Sprite2D.new()
		s.name = "Sprite"
		s.texture = get_texture.call(sol[1])
		s.scale = Vector2(sol[4], sol[4])
		body.add_child(s)

		var col := CollisionShape2D.new()
		col.name = "Collision"
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(sol[5], sol[6])
		col.shape = rect_shape
		col.position = Vector2(0, sol[7])
		body.add_child(col)

		root.add_child(body)
		body.owner = root
		s.owner = root
		col.owner = root

	# 6. Trees (Pine, Oak, Deciduous, Cherry)
	var trees: Array = data.get("trees", [])
	for t in trees:
		# [name, tex_path, x, y, scale, col_radius, col_offset_y]
		var body := StaticBody2D.new()
		body.name = t[0]
		body.position = Vector2(t[2], t[3])

		var s := Sprite2D.new()
		s.name = "Sprite"
		s.texture = get_texture.call(t[1])
		s.scale = Vector2(t[4], t[4])
		body.add_child(s)

		var col := CollisionShape2D.new()
		col.name = "Collision"
		var circle_shape := CircleShape2D.new()
		circle_shape.radius = t[5]
		col.shape = circle_shape
		col.position = Vector2(0, t[6])
		body.add_child(col)

		root.add_child(body)
		body.owner = root
		s.owner = root
		col.owner = root

	print("  Instantiated %d environment elements into root." % root.get_child_count())

	var scene := PackedScene.new()
	var pack_err := scene.pack(root)
	if pack_err != OK:
		print("❌ Failed to pack scene: ", pack_err)
		quit(1)
		return

	var save_err := ResourceSaver.save(scene, "res://scenes/world_environment.tscn")
	if save_err != OK:
		print("❌ Failed to save res://scenes/world_environment.tscn: ", save_err)
		quit(1)
		return

	print("✅ Successfully built and saved res://scenes/world_environment.tscn!")
	root.queue_free()
	quit(0)
