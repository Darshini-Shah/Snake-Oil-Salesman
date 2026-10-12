extends SceneTree

const Profiles = preload("res://scripts/character_profiles.gd")

const CHARACTERS_CONFIG = [
	# [NodeName, TexturePath, PosX, PosY, Facing, IsGuard, Gold, Trust, Suspicion]
	# Identity and original profile paths come only from the character catalog.

	# --- 1. KURTOS CENTRAL PLAZA (CIVIC CENTER) ---
	["NPC_MayorVance", "res://assets/characters/people/mayor_vance.png", 2056, 920, "down", false, 5000, 40, 30],
	["NPC_Barnaby", "res://assets/characters/rpg_pack/npc_barnaby.png", 1850, 1140, "down", false, 1200, 45, 15],
	["NPC_DoctorHawthorne", "res://assets/characters/people/doctor_hawthorne.png", 2270, 1140, "down", false, 2200, 60, 20],
	["NPC_WatchmakerTock", "res://assets/characters/people/watchmaker_tock.png", 1850, 1370, "down", false, 1800, 50, 25],
	["NPC_LibrarianElena", "res://assets/characters/people/librarian_elena.png", 2520, 1370, "down", false, 1100, 55, 15],
	["NPC_Cedric", "res://assets/characters/rpg_pack/npc_cedric.png", 2270, 1370, "down", false, 8500, 30, 25],
	["NPC_JesterPip", "res://assets/characters/people/jester_pip.png", 1990, 1128, "right", false, 350, 70, 10],
	["NPC_BardLyra", "res://assets/characters/people/bard_lyra.png", 2120, 1128, "left", false, 450, 65, 15],
	["NPC_CitizenClara", "res://assets/characters/people/citizen_clara.png", 1940, 1220, "up", false, 600, 60, 15],
	["NPC_CitizenHugo", "res://assets/characters/people/citizen_hugo.png", 2170, 1220, "left", false, 750, 50, 20],
	["Guard_TownNorth", "res://assets/characters/people/town_guard_1.png", 2056, 980, "down", true, 0, 0, 0],
	["Guard_TownSouth", "res://assets/characters/people/town_guard_2.png", 2056, 1280, "down", true, 0, 0, 0],
	["NPC_WaystationMaster", "res://assets/characters/people/citizen_hugo.png", 2270, 1630, "down", false, 900, 55, 15],
	["NPC_MusicianRowan", "res://assets/characters/people/bard_lyra.png", 1850, 1630, "down", false, 500, 65, 10],

	# --- 2. ROYAL CITADEL (NORTHEAST) ---
	["NPC_KingReginald", "res://assets/characters/people/king_reginald.png", 3280, 580, "down", false, 50000, 25, 45],
	["NPC_QueenKatherine", "res://assets/characters/people/queen_katherine.png", 3320, 580, "down", false, 40000, 35, 35],
	["Guard_RoyalKnightWest", "res://assets/characters/people/royal_knight_spear.png", 3200, 580, "down", true, 0, 0, 0],
	["Guard_RoyalKnightEast", "res://assets/characters/people/heavy_knight_guard.png", 3400, 580, "down", true, 0, 0, 0],
	["Guard_CourtyardKnight", "res://assets/characters/rpg_pack/guard_knight.png", 3300, 670, "down", true, 0, 0, 0],

	# --- 3. NORTHERN SCHOLAR ACADEMY ---
	["NPC_HeadmasterThaddeus", "res://assets/characters/people/scholar_thaddeus.png", 2056, 360, "down", false, 3500, 35, 40],
	["NPC_ApprenticeLeo", "res://assets/characters/people/apprentice_leo.png", 2000, 360, "right", false, 300, 75, 10],
	["NPC_SageAlbus", "res://assets/characters/people/sage_albus.png", 2110, 360, "left", false, 2800, 45, 30],

	# --- 4. SMUGGLER CAVE & LIGHTHOUSE ---
	["NPC_SmugglerJack", "res://assets/characters/people/smuggler_jack.png", 580, 610, "down", false, 4500, 30, 50],
	["NPC_ShadowRogue", "res://assets/characters/people/shadow_rogue.png", 640, 600, "left", false, 2200, 35, 45],
	["NPC_LighthouseKeeper", "res://assets/characters/people/lighthouse_keeper.png", 240, 1220, "down", false, 1400, 60, 20],

	# --- 5. WEST VILLAGE (ARTISANS & RESIDENTS) ---
	["NPC_Marla", "res://assets/characters/rpg_pack/npc_marla.png", 1030, 1050, "down", false, 650, 65, 10],
	["NPC_BlacksmithBoros", "res://assets/characters/people/blacksmith_boros.png", 1115, 1400, "down", false, 2100, 45, 30],
	["NPC_TailorVivienne", "res://assets/characters/people/tailor_vivienne.png", 1100, 1680, "down", false, 1600, 55, 20],
	["NPC_TavernkeeperMaggie", "res://assets/characters/people/tavernkeeper_maggie.png", 1100, 1960, "down", false, 2800, 60, 15],
	["NPC_FloristLily", "res://assets/characters/people/florist_lily.png", 1400, 1050, "down", false, 950, 70, 10],
	["NPC_HerbalistMaeve", "res://assets/characters/people/herbalist_maeve.png", 1400, 1400, "down", false, 1400, 50, 30],
	["NPC_CarpenterWayne", "res://assets/characters/people/carpenter_wayne.png", 1400, 1680, "down", false, 1750, 55, 20],
	["NPC_ToymakerOswald", "res://assets/characters/people/toymaker_oswald.png", 1400, 1960, "down", false, 800, 70, 10],
	["NPC_PriestJoseph", "res://assets/characters/people/priest_joseph.png", 1620, 890, "down", false, 1200, 80, 5],
	["NPC_Arthur", "res://assets/characters/rpg_pack/npc_arthur.png", 1620, 1420, "down", false, 400, 55, 12],
	["NPC_FishermanFinn", "res://assets/characters/people/fisherman_finn.png", 656, 1050, "down", false, 550, 65, 15],
	["NPC_PotterGordon", "res://assets/characters/people/potter_gordon.png", 580, 1770, "down", false, 900, 60, 20],
	["NPC_LumberjackKarl", "res://assets/characters/people/lumberjack_karl.png", 1400, 510, "down", false, 1500, 50, 25],
	["NPC_HunterOrion", "res://assets/characters/people/hunter_orion.png", 1080, 510, "down", false, 1300, 40, 35],
	["NPC_ElderMarta", "res://assets/characters/people/elder_marta.png", 580, 2030, "down", false, 600, 70, 15],
	["NPC_ChildTimmy", "res://assets/characters/people/child_timmy.png", 1260, 1200, "right", false, 50, 85, 5],
	["NPC_ChildRosie", "res://assets/characters/people/child_rosie.png", 1300, 1200, "left", false, 40, 85, 5],

	# --- 6. EAST FARMLANDS & VALLEY ---
	["NPC_FarmerGiles", "res://assets/characters/people/farmer_giles.png", 3080, 1210, "down", false, 1400, 55, 20],
	["NPC_FarmhandPete", "res://assets/characters/people/farmhand_pete.png", 2940, 1240, "down", false, 350, 70, 10],
	["NPC_BeekeeperBeatrice", "res://assets/characters/people/beekeeper_beatrice.png", 3550, 1510, "down", false, 1100, 65, 15],
	["NPC_MillerDonald", "res://assets/characters/people/windmill_miller.png", 3450, 1210, "down", false, 1600, 50, 20],
	["NPC_GranaryJacob", "res://assets/characters/people/blacksmith_boros.png", 3250, 1790, "down", false, 1300, 55, 20],
	["NPC_CoastEli", "res://assets/characters/people/fisherman_finn.png", 3550, 1830, "down", false, 700, 60, 20],

	# --- 7. DEEP STONE MINE ---
	["NPC_ForemanIronbeard", "res://assets/characters/people/foreman_ironbeard.png", 3440, 2190, "down", false, 3200, 40, 35],
	["NPC_MinerCole", "res://assets/characters/people/miner_cole.png", 3180, 2190, "down", false, 900, 50, 25],

	# --- 8. SOUTHERN ARRIVAL BRIDGE & ENTRANCE GATES ---
	["Guard_BridgeCaptain", "res://assets/characters/rpg_pack/guard_knight.png", 1980, 2390, "down", true, 0, 0, 0],
	["Guard_BridgeSentry", "res://assets/characters/people/royal_knight_spear.png", 2116, 2390, "down", true, 0, 0, 0],
	["NPC_TravelerFelix", "res://assets/characters/rpg_pack/player_traveler.png", 2090, 2240, "left", false, 1800, 65, 15],
	["Guard_Footbridge1", "res://assets/characters/people/town_guard_1.png", 1780, 1890, "left", true, 0, 0, 0],
	["Guard_Footbridge2", "res://assets/characters/people/town_guard_2.png", 700, 1070, "right", true, 0, 0, 0],
]

func _init() -> void:
	print("▶ Building World Characters Scene...")
	var root_node := create_characters()
	if root_node == null:
		quit(1)
		return
	print("  Instantiated %d characters into root." % root_node.get_child_count())
	var scene := PackedScene.new()
	var pack_err := scene.pack(root_node)
	if pack_err != OK:
		root_node.free()
		quit(1)
		return
	var save_err := ResourceSaver.save(scene, "res://scenes/world_characters.tscn")
	root_node.free()
	quit(0 if save_err == OK else 1)


static func create_characters() -> Node2D:
	var npc_packed: PackedScene = load("res://assets/characters/npc.tscn")
	var guard_packed: PackedScene = load("res://assets/characters/guard.tscn")

	if npc_packed == null or guard_packed == null:
		print("❌ Failed to load npc.tscn or guard.tscn")
		return null

	var root_node := Node2D.new()
	root_node.name = "Characters"
	root_node.y_sort_enabled = true

	for cfg in CHARACTERS_CONFIG:
		var node_name: String = cfg[0]
		var character_id := Profiles.id_for_node(node_name)
		var profile := Profiles.load_profile(character_id)
		if profile.is_empty():
			root_node.free()
			return null
		var tex_path: String = cfg[1]
		var pos_x: float = float(cfg[2])
		var pos_y: float = float(cfg[3])
		var facing: String = cfg[4]
		var is_guard: bool = bool(cfg[5])
		var data_file := str(profile.get("profile_file", ""))
		var gold_val: int = int(cfg[6])
		var trust_val: int = int(cfg[7])
		var suspicion_val: int = int(cfg[8])

		var tex: Texture2D = load(tex_path)
		if tex == null:
			print("❌ Missing texture: ", tex_path)
			root_node.free()
			return null

		if is_guard:
			var guard := guard_packed.instantiate() as TownGuard
			guard.name = node_name
			guard.character_id = character_id
			guard.guard_name = str(profile.name)
			guard.guard_title = str(profile.occupation)
			guard.position = Vector2(pos_x, pos_y)
			var sprite := guard.get_node("Sprite2D") as Sprite2D
			if sprite:
				sprite.texture = tex
			guard.set_facing(facing)

			root_node.add_child(guard)
			guard.owner = root_node
		else:
			var npc := npc_packed.instantiate() as TownNPC
			npc.name = node_name
			npc.character_id = character_id
			npc.npc_name = str(profile.name)
			npc.npc_title = str(profile.occupation)
			npc.position = Vector2(pos_x, pos_y)
			npc.character_texture = tex
			npc.npc_data_file = data_file
			# Keep existing authored budgets; other characters retain the scene default.
			if not data_file.is_empty():
				npc.max_daily_spend = int(profile.get("max_daily_spend", npc.max_daily_spend))
			npc.gold = gold_val
			npc.trust = trust_val
			npc.suspicion = suspicion_val
			var sprite := npc.get_node("Sprite2D") as Sprite2D
			if sprite:
				sprite.texture = tex
			npc.set_facing(facing)

			root_node.add_child(npc)
			npc.owner = root_node

	return root_node
