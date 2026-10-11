extends SceneTree

var frame_count := 0
var main: Node2D

func _init() -> void:
	print("▶ Testing Island Animals & Environmental Particles...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "scenes/main.tscn loads successfully")
	main = main_scene.instantiate()
	root.add_child(main)
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	frame_count += 1
	if frame_count < 2:
		return

	print("▶ Physics space active. Running animals and particles tests...")

	# --- 1. ANIMALS CONTAINER & ROSTER ---
	var animals_node = main.get_node_or_null("Animals")
	assert(animals_node != null, "Animals node exists in main scene")
	var animal_count = animals_node.get_child_count()
	assert(animal_count >= 30, "Animals container has >= 30 animals (Actual: %d)" % animal_count)
	print("  ✅ PASS: Animals container active with %d animated critters & livestock" % animal_count)

	var required_animals = [
		# Cows
		"Cow_Daisy", "Cow_Buttercup", "Cow_Bessie",
		# Sheep
		"Sheep_Fluffy", "Sheep_Woolly", "Sheep_Snowball", "Sheep_Cloud",
		# Pigs
		"Pig_Barnaby", "Pig_Oinky",
		# Chickens
		"Chicken_Henrietta", "Chicken_Penny", "Chicken_Clucky", "Chicken_Flour", "Chicken_Pippin",
		# Cats
		"Cat_Brioche", "Cat_Whiskey", "Cat_Paws", "Cat_Oliver", "Cat_Duchess", "Cat_Barnacle",
		# Birds
		"Bird_Pigeon1", "Bird_Pigeon2", "Bird_Bluejay1", "Bird_Seagull1", "Bird_Pelican"
	]

	for an_name in required_animals:
		var an = animals_node.get_node_or_null(an_name)
		assert(an != null, "Animal '%s' exists" % an_name)
		assert(an is CharacterBody2D, "Animal '%s' is CharacterBody2D" % an_name)
		var spr = an.get_node_or_null("Sprite2D") as Sprite2D
		assert(spr != null and spr.texture != null, "Animal '%s' has valid sprite texture" % an_name)
		assert(spr.hframes >= 2 or spr.vframes >= 2, "Animal '%s' has multi-frame spritesheet" % an_name)
		assert(an.position.x > 0 and an.position.x < 4096, "Animal '%s' inside map X" % an_name)
		assert(an.position.y > 0 and an.position.y < 2816, "Animal '%s' inside map Y" % an_name)

	print("  ✅ PASS: All %d required landmark animals verified with valid multi-frame spritesheets" % required_animals.size())

	# Verify player spawn clearance (2048, 2560)
	var player_spawn = Vector2(2048, 2560)
	for an in animals_node.get_children():
		var dist = (an.position - player_spawn).length()
		assert(dist >= 40.0, "Animal '%s' is safely distanced from player spawn (dist: %.1fpx)" % [an.name, dist])
	print("  ✅ PASS: All animals safely distanced from player spawn point")

	# --- 2. ANIMAL INTERACTION / FLEE REACTION ---
	var chicken = animals_node.get_node("Chicken_Henrietta") as CharacterBody2D
	assert(chicken != null, "Chicken_Henrietta exists")
	var initial_target = chicken.target_wander_pos
	var player = main.get_node("Player") as CharacterBody2D

	# Place player directly adjacent to chicken
	player.global_position = chicken.global_position + Vector2(10, 0)
	chicken._on_detection_area_body_entered(player)
	assert(chicken.is_fleeing, "Chicken scatters/flees when player enters detection radius")
	assert(chicken.target_wander_pos != initial_target, "Chicken recalculates escape trajectory away from player")
	print("  ✅ PASS: Dynamic animal flee and proximity reaction verified")

	# --- 3. ENVIRONMENTAL PARTICLES ---
	var particles_node = main.get_node_or_null("Particles")
	assert(particles_node != null, "Particles node exists in main scene")
	assert(particles_node.get_child_count() >= 10, "Particles container has >= 10 particle emitters")
	print("  ✅ PASS: Particles container active with %d atmospheric emitters" % particles_node.get_child_count())

	var required_particles = [
		"Smoke_Bakery", "Smoke_Forge", "Sparks_Forge", "Smoke_Tavern", "Smoke_Farmhouse",
		"Smoke_Campfire", "Embers_Campfire", "Fountain_WaterSpray", "CherryBlossom_Petals",
		"Farmlands_PollenMotes", "Waterfall_Mist", "Watermill_Splash", "Mine_DustMotes"
	]

	for p_name in required_particles:
		var p = particles_node.get_node_or_null(p_name) as CPUParticles2D
		assert(p != null, "Particle emitter '%s' exists" % p_name)
		assert(p.emitting, "Particle emitter '%s' is actively emitting" % p_name)
		assert(p.amount > 0, "Particle emitter '%s' has amount > 0" % p_name)
		assert(p.lifetime > 0.0, "Particle emitter '%s' has lifetime > 0" % p_name)

	print("  ✅ PASS: All %d required particle systems verified and actively emitting" % required_particles.size())

	print("\n-------------------------------------------------------")
	print("🏁 ALL ISLAND ANIMALS & PARTICLES TESTS PASSED!")
	print("-------------------------------------------------------")
	quit(0)
