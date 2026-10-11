extends SceneTree

# Builder script to generate:
# 1. scenes/world_animals.tscn (Animated livestock, village pets, and wild birds)
# 2. scenes/world_particles.tscn (Chimney smoke, cherry blossom drift, waterfall mist, fountain spray, pollen)

const ANIMALS_CONFIG = [
	# [NodeName, AnimalType, TexPath, Hframes, Vframes, PosX, PosY, Behavior, WanderRadius, MoveSpeed, React]
	
	# --- 1. EAST FARMLANDS (LIVESTOCK & PASTURES) ---
	# Cattle Pasture
	["Cow_Daisy", "cow", "res://assets/animals/cow.png", 2, 2, 3260, 1320, "graze", 20.0, 15.0, true],
	["Cow_Buttercup", "cow", "res://assets/animals/cow.png", 2, 2, 3310, 1360, "graze", 22.0, 14.0, true],
	["Cow_Bessie", "cow", "res://assets/animals/cow.png", 2, 2, 3220, 1380, "graze", 18.0, 16.0, true],

	# Sheep Meadow (Rolling hills north of farmland)
	["Sheep_Fluffy", "sheep", "res://assets/animals/sheep.png", 2, 2, 2980, 1080, "graze", 24.0, 18.0, true],
	["Sheep_Woolly", "sheep", "res://assets/animals/sheep.png", 2, 2, 3040, 1060, "graze", 20.0, 18.0, true],
	["Sheep_Snowball", "sheep", "res://assets/animals/sheep.png", 2, 2, 3120, 1100, "graze", 22.0, 17.0, true],
	["Sheep_Cloud", "sheep", "res://assets/animals/sheep.png", 2, 2, 3080, 1140, "graze", 20.0, 18.0, true],

	# Farmhouse Pen & Yard
	["Pig_Barnaby", "pig", "res://assets/animals/pig.png", 2, 2, 3040, 1340, "wander", 16.0, 20.0, true],
	["Pig_Oinky", "pig", "res://assets/animals/pig.png", 2, 2, 3090, 1370, "wander", 16.0, 18.0, true],
	["Chicken_Henrietta", "chicken", "res://assets/animals/chicken.png", 2, 2, 3020, 1260, "peck", 18.0, 28.0, true],
	["Chicken_Penny", "chicken", "res://assets/animals/chicken.png", 2, 2, 3060, 1280, "peck", 16.0, 26.0, true],
	["Chicken_Clucky", "chicken", "res://assets/animals/chicken.png", 2, 2, 3110, 1260, "peck", 18.0, 28.0, true],

	# Apiary Meadow
	["Chicken_Goldie", "chicken", "res://assets/animals/chicken.png", 2, 2, 3520, 1460, "peck", 16.0, 25.0, true],
	["Chicken_Rusty", "chicken", "res://assets/animals/chicken.png", 2, 2, 3570, 1480, "peck", 16.0, 25.0, true],

	# --- 2. WEST VILLAGE (PETS, CHICKENS & BIRDS) ---
	# Bakery veranda & yard
	["Cat_Brioche", "cat", "res://assets/animals/cat_sleep.png", 3, 1, 1010, 1000, "sleep", 0.0, 0.0, false],
	["Chicken_Flour", "chicken", "res://assets/animals/chicken.png", 2, 2, 1050, 930, "peck", 16.0, 24.0, true],

	# Tavern porch & alley
	["Cat_Whiskey", "cat", "res://assets/animals/cat_sit.png", 3, 1, 1070, 1920, "idle", 0.0, 0.0, true],

	# Chapel garden
	["Cat_Paws", "cat", "res://assets/animals/cat_sit.png", 3, 1, 1650, 860, "idle", 0.0, 0.0, true],

	# Artisan village green
	["Chicken_Pippin", "chicken", "res://assets/animals/chicken.png", 2, 2, 1360, 1630, "peck", 16.0, 24.0, true],
	["Chicken_Dot", "chicken", "res://assets/animals/chicken.png", 2, 2, 1380, 1090, "peck", 16.0, 24.0, true],
	["Cat_Mittens", "cat", "res://assets/animals/cat_walk.png", 3, 1, 1370, 1920, "wander", 18.0, 18.0, true],

	# --- 3. CIVIC PLAZA ---
	# Central Fountain
	["Bird_Pigeon1", "bird", "res://assets/animals/bird_hop.png", 4, 1, 2036, 1115, "peck", 12.0, 30.0, true],
	["Bird_Pigeon2", "bird", "res://assets/animals/bird_peck.png", 4, 1, 2076, 1145, "peck", 12.0, 30.0, true],

	# Town Hall Garden
	["Cat_Oliver", "cat", "res://assets/animals/cat_sleep.png", 3, 1, 2010, 910, "sleep", 0.0, 0.0, false],
	["Bird_Sparrow1", "bird", "res://assets/animals/bird_hop.png", 4, 1, 2120, 890, "peck", 14.0, 30.0, true],

	# --- 4. ROYAL CITADEL (GARDENS & TERRACE) ---
	["Bird_Bluejay1", "bird", "res://assets/animals/bird_hop.png", 4, 1, 3150, 520, "peck", 16.0, 30.0, true],
	["Bird_Bluejay2", "bird", "res://assets/animals/bird_peck.png", 4, 1, 3450, 520, "peck", 16.0, 30.0, true],
	["Cat_Duchess", "cat", "res://assets/animals/cat_sit.png", 3, 1, 3360, 560, "idle", 0.0, 0.0, true],

	# --- 5. NORTHERN ACADEMY & MOUNTAINS ---
	["Bird_Owl1", "bird", "res://assets/animals/bird_peck.png", 4, 1, 2130, 340, "peck", 12.0, 28.0, true],
	["Cat_Archimedes", "cat", "res://assets/animals/cat_sit.png", 3, 1, 2020, 340, "idle", 0.0, 0.0, true],
	["Bird_Woodpecker", "bird", "res://assets/animals/bird_hop.png", 4, 1, 1120, 480, "peck", 14.0, 30.0, true],

	# --- 6. LIGHTHOUSE & COASTAL PIER ---
	["Bird_Seagull1", "bird", "res://assets/animals/bird_hop.png", 4, 1, 210, 1200, "peck", 16.0, 30.0, true],
	["Bird_Seagull2", "bird", "res://assets/animals/bird_peck.png", 4, 1, 260, 1240, "peck", 16.0, 30.0, true],
	["Cat_Barnacle", "cat", "res://assets/animals/cat_sit.png", 3, 1, 680, 1030, "idle", 0.0, 0.0, true],
	["Bird_Pelican", "bird", "res://assets/animals/bird_peck.png", 4, 1, 620, 1020, "peck", 14.0, 28.0, true],
]

func _init() -> void:
	print("▶ Building World Animals & Particles Scenes...")
	build_animals_scene()
	build_particles_scene()
	print("✅ Successfully generated animals & particles scenes!")
	quit(0)

func build_animals_scene() -> void:
	var base_scene: PackedScene = load("res://assets/animals/animal_base.tscn")
	var root := Node2D.new()
	root.name = "Animals"
	root.y_sort_enabled = true

	for cfg in ANIMALS_CONFIG:
		var node_name: String = cfg[0]
		var anim_type: String = cfg[1]
		var tex_path: String = cfg[2]
		var hf: int = int(cfg[3])
		var vf: int = int(cfg[4])
		var px: float = float(cfg[5])
		var py: float = float(cfg[6])
		var beh: String = cfg[7]
		var wrad: float = float(cfg[8])
		var mspeed: float = float(cfg[9])
		var react: bool = bool(cfg[10])

		var inst = base_scene.instantiate()
		inst.name = node_name
		inst.animal_type = anim_type
		inst.behavior = beh
		inst.wander_radius = wrad
		inst.move_speed = mspeed
		inst.react_to_player = react
		inst.position = Vector2(px, py)

		var spr: Sprite2D = inst.get_node("Sprite2D")
		var tex: Texture2D = load(tex_path)
		if spr and tex:
			spr.texture = tex
			spr.hframes = hf
			spr.vframes = vf

		root.add_child(inst)
		inst.owner = root

	print("  Instantiated %d animals into Animals container." % root.get_child_count())

	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/world_animals.tscn")
	root.queue_free()

func build_particles_scene() -> void:
	var root := Node2D.new()
	root.name = "Particles"

	# Helper to create CPUParticles2D
	var create_smoke = func(p_name: String, pos: Vector2, color: Color, p_scale: float, amount: int = 14) -> CPUParticles2D:
		var p := CPUParticles2D.new()
		p.name = p_name
		p.position = pos
		p.amount = amount
		p.lifetime = 2.4
		p.preprocess = 1.5
		p.speed_scale = 0.9
		p.direction = Vector2(0.2, -1.0)
		p.spread = 18.0
		p.gravity = Vector2(4.0, -12.0)
		p.initial_velocity_min = 12.0
		p.initial_velocity_max = 24.0
		p.scale_amount_min = p_scale * 1.5
		p.scale_amount_max = p_scale * 3.5
		p.color = color
		var grad := Gradient.new()
		grad.set_color(0, Color(color.r, color.g, color.b, 0.75))
		grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
		p.color_ramp = grad
		return p

	# 1. Chimney Smokes
	# Bakery Chimney
	var smoke_bakery = create_smoke.call("Smoke_Bakery", Vector2(1090, 890), Color(0.92, 0.92, 0.95), 1.2)
	root.add_child(smoke_bakery)
	smoke_bakery.owner = root

	# Blacksmith Forge Smoke & Fiery Sparks
	var smoke_forge = create_smoke.call("Smoke_Forge", Vector2(1115, 1310), Color(0.35, 0.35, 0.4), 1.4, 18)
	root.add_child(smoke_forge)
	smoke_forge.owner = root

	var sparks_forge := CPUParticles2D.new()
	sparks_forge.name = "Sparks_Forge"
	sparks_forge.position = Vector2(1115, 1320)
	sparks_forge.amount = 8
	sparks_forge.lifetime = 0.9
	sparks_forge.preprocess = 0.5
	sparks_forge.direction = Vector2(0, -1)
	sparks_forge.spread = 45.0
	sparks_forge.gravity = Vector2(0, 18.0)
	sparks_forge.initial_velocity_min = 25.0
	sparks_forge.initial_velocity_max = 50.0
	sparks_forge.scale_amount_min = 1.0
	sparks_forge.scale_amount_max = 2.5
	sparks_forge.color = Color(1.0, 0.65, 0.15, 0.9)
	root.add_child(sparks_forge)
	sparks_forge.owner = root

	# Tavern Chimney
	var smoke_tavern = create_smoke.call("Smoke_Tavern", Vector2(1100, 1870), Color(0.88, 0.88, 0.92), 1.3)
	root.add_child(smoke_tavern)
	smoke_tavern.owner = root

	# Farmhouse Chimney
	var smoke_farm = create_smoke.call("Smoke_Farmhouse", Vector2(3080, 1130), Color(0.9, 0.9, 0.93), 1.2)
	root.add_child(smoke_farm)
	smoke_farm.owner = root

	# Eastern Shore Cabin Chimney
	var smoke_shore = create_smoke.call("Smoke_ShoreCabin", Vector2(3550, 1750), Color(0.85, 0.88, 0.9), 1.1)
	root.add_child(smoke_shore)
	smoke_shore.owner = root

	# Hunter Campfire (Smoke & Embers)
	var smoke_camp = create_smoke.call("Smoke_Campfire", Vector2(1090, 520), Color(0.8, 0.8, 0.82), 1.0, 10)
	root.add_child(smoke_camp)
	smoke_camp.owner = root

	var embers_camp := CPUParticles2D.new()
	embers_camp.name = "Embers_Campfire"
	embers_camp.position = Vector2(1090, 520)
	embers_camp.amount = 6
	embers_camp.lifetime = 1.2
	embers_camp.preprocess = 0.6
	embers_camp.direction = Vector2(0, -1)
	embers_camp.spread = 30.0
	embers_camp.gravity = Vector2(0, -6.0)
	embers_camp.initial_velocity_min = 10.0
	embers_camp.initial_velocity_max = 25.0
	embers_camp.scale_amount_min = 1.0
	embers_camp.scale_amount_max = 2.0
	embers_camp.color = Color(1.0, 0.5, 0.1, 0.9)
	root.add_child(embers_camp)
	embers_camp.owner = root

	# 2. Central Plaza Fountain Spray
	var fountain_spray := CPUParticles2D.new()
	fountain_spray.name = "Fountain_WaterSpray"
	fountain_spray.position = Vector2(2056, 1120)
	fountain_spray.amount = 26
	fountain_spray.lifetime = 1.3
	fountain_spray.preprocess = 1.0
	fountain_spray.direction = Vector2(0, -1)
	fountain_spray.spread = 35.0
	fountain_spray.gravity = Vector2(0, 55.0)
	fountain_spray.initial_velocity_min = 35.0
	fountain_spray.initial_velocity_max = 50.0
	fountain_spray.scale_amount_min = 1.5
	fountain_spray.scale_amount_max = 3.0
	fountain_spray.color = Color(0.7, 0.9, 1.0, 0.85)
	var f_grad := Gradient.new()
	f_grad.set_color(0, Color(0.85, 0.95, 1.0, 0.9))
	f_grad.set_color(1, Color(0.5, 0.8, 1.0, 0.1))
	fountain_spray.color_ramp = f_grad
	root.add_child(fountain_spray)
	fountain_spray.owner = root

	# 3. Royal Citadel Cherry Blossom Petals Drift
	var cherry_petals := CPUParticles2D.new()
	cherry_petals.name = "CherryBlossom_Petals"
	cherry_petals.position = Vector2(3300, 480)
	cherry_petals.amount = 35
	cherry_petals.lifetime = 5.0
	cherry_petals.preprocess = 3.0
	cherry_petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	cherry_petals.emission_rect_extents = Vector2(350, 200)
	cherry_petals.direction = Vector2(0.8, 0.6)
	cherry_petals.spread = 25.0
	cherry_petals.gravity = Vector2(5.0, 8.0)
	cherry_petals.initial_velocity_min = 15.0
	cherry_petals.initial_velocity_max = 30.0
	cherry_petals.angular_velocity_min = -40.0
	cherry_petals.angular_velocity_max = 40.0
	cherry_petals.scale_amount_min = 2.0
	cherry_petals.scale_amount_max = 4.0
	cherry_petals.color = Color(1.0, 0.72, 0.82, 0.8)
	var petal_grad := Gradient.new()
	petal_grad.set_color(0, Color(1.0, 0.75, 0.85, 0.85))
	petal_grad.set_color(1, Color(0.95, 0.65, 0.75, 0.0))
	cherry_petals.color_ramp = petal_grad
	root.add_child(cherry_petals)
	cherry_petals.owner = root

	# 4. East Farmlands Golden Pollen & Fireflies
	var pollen := CPUParticles2D.new()
	pollen.name = "Farmlands_PollenMotes"
	pollen.position = Vector2(3350, 1400)
	pollen.amount = 30
	pollen.lifetime = 4.0
	pollen.preprocess = 2.5
	pollen.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pollen.emission_rect_extents = Vector2(250, 180)
	pollen.direction = Vector2(0, -1)
	pollen.spread = 180.0
	pollen.gravity = Vector2(0, -2.0)
	pollen.initial_velocity_min = 4.0
	pollen.initial_velocity_max = 12.0
	pollen.scale_amount_min = 1.2
	pollen.scale_amount_max = 2.5
	pollen.color = Color(1.0, 0.9, 0.45, 0.75)
	var pol_grad := Gradient.new()
	pol_grad.set_color(0, Color(1.0, 0.92, 0.45, 0.0))
	pol_grad.set_color(1, Color(1.0, 0.85, 0.35, 0.8))
	pollen.color_ramp = pol_grad
	root.add_child(pollen)
	pollen.owner = root

	# 5. Southern Waterfall Plunge Mist
	var waterfall_mist := CPUParticles2D.new()
	waterfall_mist.name = "Waterfall_Mist"
	waterfall_mist.position = Vector2(1740, 2300)
	waterfall_mist.amount = 28
	waterfall_mist.lifetime = 2.2
	waterfall_mist.preprocess = 1.5
	waterfall_mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	waterfall_mist.emission_rect_extents = Vector2(60, 20)
	waterfall_mist.direction = Vector2(0, -1)
	waterfall_mist.spread = 40.0
	waterfall_mist.gravity = Vector2(0, -10.0)
	waterfall_mist.initial_velocity_min = 16.0
	waterfall_mist.initial_velocity_max = 32.0
	waterfall_mist.scale_amount_min = 3.0
	waterfall_mist.scale_amount_max = 6.0
	waterfall_mist.color = Color(0.9, 0.96, 1.0, 0.6)
	var mist_grad := Gradient.new()
	mist_grad.set_color(0, Color(0.95, 0.98, 1.0, 0.65))
	mist_grad.set_color(1, Color(0.8, 0.9, 1.0, 0.0))
	waterfall_mist.color_ramp = mist_grad
	root.add_child(waterfall_mist)
	waterfall_mist.owner = root

	# 6. Lakeside Watermill Splash
	var mill_splash := CPUParticles2D.new()
	mill_splash.name = "Watermill_Splash"
	mill_splash.position = Vector2(3265, 1720)
	mill_splash.amount = 14
	mill_splash.lifetime = 0.9
	mill_splash.preprocess = 0.5
	mill_splash.direction = Vector2(0.5, -1)
	mill_splash.spread = 30.0
	mill_splash.gravity = Vector2(0, 45.0)
	mill_splash.initial_velocity_min = 18.0
	mill_splash.initial_velocity_max = 36.0
	mill_splash.scale_amount_min = 1.5
	mill_splash.scale_amount_max = 3.0
	mill_splash.color = Color(0.85, 0.95, 1.0, 0.8)
	root.add_child(mill_splash)
	mill_splash.owner = root

	# 7. Deep Mine Stone Dust
	var mine_dust := CPUParticles2D.new()
	mine_dust.name = "Mine_DustMotes"
	mine_dust.position = Vector2(3440, 2190)
	mine_dust.amount = 15
	mine_dust.lifetime = 3.0
	mine_dust.preprocess = 1.5
	mine_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mine_dust.emission_rect_extents = Vector2(60, 30)
	mine_dust.direction = Vector2(0, -1)
	mine_dust.spread = 180.0
	mine_dust.gravity = Vector2(0, -2.0)
	mine_dust.initial_velocity_min = 4.0
	mine_dust.initial_velocity_max = 10.0
	mine_dust.scale_amount_min = 1.0
	mine_dust.scale_amount_max = 2.2
	mine_dust.color = Color(0.8, 0.75, 0.68, 0.6)
	root.add_child(mine_dust)
	mine_dust.owner = root

	print("  Configured %d atmospheric particle emitters into Particles container." % root.get_child_count())

	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/world_particles.tscn")
	root.queue_free()
