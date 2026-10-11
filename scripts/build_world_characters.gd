extends SceneTree

const CHARACTERS_CONFIG = [
	# [NodeName, DisplayName, Title, TexturePath, PosX, PosY, Facing, IsGuard, DataFile, Gold, Trust, Suspicion]

	# --- 1. KURTOS CENTRAL PLAZA (CIVIC CENTER) ---
	["NPC_MayorVance", "Mayor Vance", "Mayor of Kurtos", "res://assets/characters/people/mayor_vance.png", 2056, 920, "down", false, "", 5000, 40, 30],
	["NPC_Barnaby", "Barnaby", "Curious Town Merchant", "res://assets/characters/rpg_pack/npc_barnaby.png", 1850, 1140, "down", false, "res://data/npcs/barnaby_merchant.json", 1200, 45, 15],
	["NPC_DoctorHawthorne", "Dr. Hawthorne", "Town Physician", "res://assets/characters/people/doctor_hawthorne.png", 2270, 1140, "down", false, "", 2200, 60, 20],
	["NPC_WatchmakerTock", "Master Tock", "Master Horologist", "res://assets/characters/people/watchmaker_tock.png", 1850, 1370, "down", false, "", 1800, 50, 25],
	["NPC_LibrarianElena", "Elena", "Chief Archivist", "res://assets/characters/people/librarian_elena.png", 2520, 1370, "down", false, "", 1100, 55, 15],
	["NPC_Cedric", "Lord Cedric", "Wealthy Aristocrat", "res://assets/characters/rpg_pack/npc_cedric.png", 2270, 1370, "down", false, "res://data/npcs/cedric_aristocrat.json", 8500, 30, 25],
	["NPC_JesterPip", "Pip", "Court Jester", "res://assets/characters/people/jester_pip.png", 1990, 1128, "right", false, "", 350, 70, 10],
	["NPC_BardLyra", "Lyra", "Wandering Minstrel", "res://assets/characters/people/bard_lyra.png", 2120, 1128, "left", false, "", 450, 65, 15],
	["NPC_CitizenClara", "Clara", "Plaza Shopper", "res://assets/characters/people/citizen_clara.png", 1940, 1220, "up", false, "", 600, 60, 15],
	["NPC_CitizenHugo", "Hugo", "Townsperson", "res://assets/characters/people/citizen_hugo.png", 2170, 1220, "left", false, "", 750, 50, 20],
	["Guard_TownNorth", "Plaza Guard", "Civic Sentry", "res://assets/characters/people/town_guard_1.png", 2056, 980, "down", true, "", 0, 0, 0],
	["Guard_TownSouth", "Plaza Guard", "Civic Sentry", "res://assets/characters/people/town_guard_2.png", 2056, 1280, "down", true, "", 0, 0, 0],
	["NPC_WaystationMaster", "Clerk Robert", "Post Waystation Courier", "res://assets/characters/people/citizen_hugo.png", 2270, 1630, "down", false, "", 900, 55, 15],
	["NPC_MusicianRowan", "Rowan", "Fiddle Player", "res://assets/characters/people/bard_lyra.png", 1850, 1630, "down", false, "", 500, 65, 10],

	# --- 2. ROYAL CITADEL (NORTHEAST) ---
	["NPC_KingReginald", "King Reginald", "Sovereign of Kurtos", "res://assets/characters/people/king_reginald.png", 3280, 580, "down", false, "", 50000, 25, 45],
	["NPC_QueenKatherine", "Queen Katherine", "Queen of Kurtos", "res://assets/characters/people/queen_katherine.png", 3320, 580, "down", false, "", 40000, 35, 35],
	["Guard_RoyalKnightWest", "Sir Jeffrey", "Royal Citadel Guard", "res://assets/characters/people/royal_knight_spear.png", 3200, 580, "down", true, "", 0, 0, 0],
	["Guard_RoyalKnightEast", "Sir Donald", "Royal Citadel Guard", "res://assets/characters/people/heavy_knight_guard.png", 3400, 580, "down", true, "", 0, 0, 0],
	["Guard_CourtyardKnight", "Citadel Sentry", "Citadel Gate Guard", "res://assets/characters/rpg_pack/guard_knight.png", 3300, 670, "down", true, "", 0, 0, 0],

	# --- 3. NORTHERN SCHOLAR ACADEMY ---
	["NPC_HeadmasterThaddeus", "Thaddeus", "Academy Headmaster", "res://assets/characters/people/scholar_thaddeus.png", 2056, 360, "down", false, "", 3500, 35, 40],
	["NPC_ApprenticeLeo", "Leo", "Scholar Apprentice", "res://assets/characters/people/apprentice_leo.png", 2000, 360, "right", false, "", 300, 75, 10],
	["NPC_SageAlbus", "Sage Albus", "Ancient Astrologer", "res://assets/characters/people/sage_albus.png", 2110, 360, "left", false, "", 2800, 45, 30],

	# --- 4. SMUGGLER CAVE & LIGHTHOUSE ---
	["NPC_SmugglerJack", "'Slick' Jack", "Contraband Dealer", "res://assets/characters/people/smuggler_jack.png", 580, 610, "down", false, "", 4500, 30, 50],
	["NPC_ShadowRogue", "Vesper", "Shadow Informant", "res://assets/characters/people/shadow_rogue.png", 640, 600, "left", false, "", 2200, 35, 45],
	["NPC_LighthouseKeeper", "Captain Finn", "Gull Rock Lighthouse Keeper", "res://assets/characters/people/lighthouse_keeper.png", 240, 1220, "down", false, "", 1400, 60, 20],

	# --- 5. WEST VILLAGE (ARTISANS & RESIDENTS) ---
	["NPC_Marla", "Marla", "Empathetic Baker", "res://assets/characters/rpg_pack/npc_marla.png", 1030, 1050, "down", false, "res://data/npcs/marla_baker.json", 650, 65, 10],
	["NPC_BlacksmithBoros", "Boros", "Village Blacksmith", "res://assets/characters/people/blacksmith_boros.png", 1115, 1400, "down", false, "", 2100, 45, 30],
	["NPC_TailorVivienne", "Vivienne", "Master Clothier", "res://assets/characters/people/tailor_vivienne.png", 1100, 1680, "down", false, "", 1600, 55, 20],
	["NPC_TavernkeeperMaggie", "Maggie", "Drunken Gull Hostess", "res://assets/characters/people/tavernkeeper_maggie.png", 1100, 1960, "down", false, "", 2800, 60, 15],
	["NPC_FloristLily", "Lily", "Botanist & Florist", "res://assets/characters/people/florist_lily.png", 1400, 1050, "down", false, "", 950, 70, 10],
	["NPC_HerbalistMaeve", "Maeve", "Apothecary & Herbalist", "res://assets/characters/people/herbalist_maeve.png", 1400, 1400, "down", false, "", 1400, 50, 30],
	["NPC_CarpenterWayne", "Wayne", "Master Woodworker", "res://assets/characters/people/carpenter_wayne.png", 1400, 1680, "down", false, "", 1750, 55, 20],
	["NPC_ToymakerOswald", "Oswald", "Master Toymaker", "res://assets/characters/people/toymaker_oswald.png", 1400, 1960, "down", false, "", 800, 70, 10],
	["NPC_PriestJoseph", "Father Joseph", "Parish Chapel Priest", "res://assets/characters/people/priest_joseph.png", 1620, 890, "down", false, "", 1200, 80, 5],
	["NPC_Arthur", "Old Arthur", "Superstitious Elder", "res://assets/characters/rpg_pack/npc_arthur.png", 1620, 1420, "down", false, "res://data/npcs/arthur_elder.json", 400, 55, 12],
	["NPC_FishermanFinn", "Old Finn", "Canal Angler", "res://assets/characters/people/fisherman_finn.png", 656, 1050, "down", false, "", 550, 65, 15],
	["NPC_PotterGordon", "Gordon", "Master Potter", "res://assets/characters/people/potter_gordon.png", 580, 1770, "down", false, "", 900, 60, 20],
	["NPC_LumberjackKarl", "Karl", "Lumberjack Foreman", "res://assets/characters/people/lumberjack_karl.png", 1400, 510, "down", false, "", 1500, 50, 25],
	["NPC_HunterOrion", "Orion", "Master Tracker", "res://assets/characters/people/hunter_orion.png", 1080, 510, "down", false, "", 1300, 40, 35],
	["NPC_ElderMarta", "Marta", "Coast Matriarch", "res://assets/characters/people/elder_marta.png", 580, 2030, "down", false, "", 600, 70, 15],
	["NPC_ChildTimmy", "Timmy", "Village Youth", "res://assets/characters/people/child_timmy.png", 1260, 1200, "right", false, "", 50, 85, 5],
	["NPC_ChildRosie", "Rosie", "Village Youth", "res://assets/characters/people/child_rosie.png", 1300, 1200, "left", false, "", 40, 85, 5],

	# --- 6. EAST FARMLANDS & VALLEY ---
	["NPC_FarmerGiles", "Farmer Giles", "Valley Patriarch", "res://assets/characters/people/farmer_giles.png", 3080, 1210, "down", false, "", 1400, 55, 20],
	["NPC_FarmhandPete", "Pete", "Harvest Farmhand", "res://assets/characters/people/farmhand_pete.png", 2940, 1240, "down", false, "", 350, 70, 10],
	["NPC_BeekeeperBeatrice", "Beatrice", "Master Apiarist", "res://assets/characters/people/beekeeper_beatrice.png", 3550, 1510, "down", false, "", 1100, 65, 15],
	["NPC_MillerDonald", "Donald", "Windmill Miller", "res://assets/characters/people/windmill_miller.png", 3450, 1210, "down", false, "", 1600, 50, 20],
	["NPC_GranaryJacob", "Jacob", "Granary Miller", "res://assets/characters/people/blacksmith_boros.png", 3250, 1790, "down", false, "", 1300, 55, 20],
	["NPC_CoastEli", "Eli", "Eastern Shore Cabin Resident", "res://assets/characters/people/fisherman_finn.png", 3550, 1830, "down", false, "", 700, 60, 20],

	# --- 7. DEEP STONE MINE ---
	["NPC_ForemanIronbeard", "Foreman Ironbeard", "Mine Overseer", "res://assets/characters/people/foreman_ironbeard.png", 3440, 2190, "down", false, "", 3200, 40, 35],
	["NPC_MinerCole", "Cole", "Deep Ore Miner", "res://assets/characters/people/miner_cole.png", 3180, 2190, "down", false, "", 900, 50, 25],

	# --- 8. SOUTHERN ARRIVAL BRIDGE & ENTRANCE GATES ---
	["Guard_BridgeCaptain", "Captain Stewart", "Gate Commander", "res://assets/characters/rpg_pack/guard_knight.png", 1980, 2390, "down", true, "", 0, 0, 0],
	["Guard_BridgeSentry", "Sentry Lucas", "Bridge Gate Guard", "res://assets/characters/people/royal_knight_spear.png", 2116, 2390, "down", true, "", 0, 0, 0],
	["NPC_TravelerFelix", "Felix", "Visiting Traveler", "res://assets/characters/rpg_pack/player_traveler.png", 2090, 2240, "left", false, "", 1800, 65, 15],
	["Guard_Footbridge1", "Bridge Guard", "River Footbridge Sentry", "res://assets/characters/people/town_guard_1.png", 1780, 1890, "left", true, "", 0, 0, 0],
	["Guard_Footbridge2", "Canal Guard", "Canal Footbridge Sentry", "res://assets/characters/people/town_guard_2.png", 700, 1070, "right", true, "", 0, 0, 0],
]

func _init() -> void:
	print("▶ Building World Characters Scene...")
	var npc_packed: PackedScene = load("res://assets/characters/npc.tscn")
	var guard_packed: PackedScene = load("res://assets/characters/guard.tscn")

	if npc_packed == null or guard_packed == null:
		print("❌ Failed to load npc.tscn or guard.tscn")
		quit(1)
		return

	var root_node := Node2D.new()
	root_node.name = "Characters"
	root_node.y_sort_enabled = true

	for cfg in CHARACTERS_CONFIG:
		var node_name: String = cfg[0]
		var display_name: String = cfg[1]
		var title: String = cfg[2]
		var tex_path: String = cfg[3]
		var pos_x: float = float(cfg[4])
		var pos_y: float = float(cfg[5])
		var facing: String = cfg[6]
		var is_guard: bool = bool(cfg[7])
		var data_file: String = cfg[8]
		var gold_val: int = int(cfg[9])
		var trust_val: int = int(cfg[10])
		var suspicion_val: int = int(cfg[11])

		var tex: Texture2D = load(tex_path)
		if tex == null:
			print("❌ Missing texture: ", tex_path)
			continue

		if is_guard:
			var guard := guard_packed.instantiate() as TownGuard
			guard.name = node_name
			guard.guard_name = display_name
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
			npc.npc_name = display_name
			npc.npc_title = title
			npc.position = Vector2(pos_x, pos_y)
			npc.character_texture = tex
			if not data_file.is_empty():
				npc.npc_data_file = data_file
			npc.gold = gold_val
			npc.trust = trust_val
			npc.suspicion = suspicion_val
			var sprite := npc.get_node("Sprite2D") as Sprite2D
			if sprite:
				sprite.texture = tex
			npc.set_facing(facing)

			root_node.add_child(npc)
			npc.owner = root_node

	print("  Instantiated %d characters into root." % root_node.get_child_count())

	var scene := PackedScene.new()
	var pack_err := scene.pack(root_node)
	if pack_err != OK:
		print("❌ Failed to pack scene: ", pack_err)
		quit(1)
		return

	var save_err := ResourceSaver.save(scene, "res://scenes/world_characters.tscn")
	if save_err != OK:
		print("❌ Failed to save res://scenes/world_characters.tscn: ", save_err)
		quit(1)
		return

	print("✅ Successfully built and saved res://scenes/world_characters.tscn!")
	root_node.queue_free()
	quit(0)
