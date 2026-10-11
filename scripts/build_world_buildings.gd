extends SceneTree

const BUILDINGS_CONFIG = [
	# [NodeName, DisplayName, TextureResPath, x, y, footprint_w, footprint_h, offset_y, match_poly]
	["RoyalCastle", "Royal Citadel & Fortress", "res://assets/landmarks/royal_castle.png", 3280, 480, 200, 60, 30, false],
	["ScholarAcademy", "Northern Scholar Academy", "res://assets/landmarks/academy.png", 2016, 240, 140, 50, 25, false],
	["SmugglerCave", "Smuggler's Grotto", "res://assets/landmarks/mountain_cave.png", 580, 520, 70, 40, 20, false],
	["Lighthouse", "Gull Rock Lighthouse", "res://assets/landmarks/lighthouse.png", 240, 1120, 64, 48, 24, false],
	["PlazaFountain", "Kurtos Plaza Fountain", "res://assets/landmarks/fountain.png", 2016, 1120, 48, 48, 0, false],
	["Windmill", "Golden Windmill", "res://assets/landmarks/windmill.png", 3440, 1120, 64, 48, 24, false],
	["MineEntrance", "Deep Stone Mine", "res://assets/landmarks/mine_entrance.png", 3440, 2080, 110, 40, 20, false],
	["TownHall", "Kurtos Town Hall", "res://assets/landmarks/town_hall.png", 2016, 960, 120, 50, 25, false],
	["MerchantShop", "Plaza Merchant Shop", "res://assets/Tiny Top-Down Village/General Store.png", 1800, 1040, 64, 36, 18, true],
	["DoctorsClinic", "Doctor's Clinic", "res://assets/Tiny Top-Down Village/Doctors House.png", 2232, 1040, 64, 36, 18, false],
	["Library", "Kurtos Archive & Library", "res://assets/Tiny Top-Down Village/Library.png", 2232, 1260, 64, 36, 18, false],
	["MayorsResidence", "Mayor's Manor", "res://assets/Tiny Top-Down Village/Mayors Residence.png", 2232, 1150, 64, 36, 18, false],
	["HuntersCabin", "Hunter's Cabin", "res://assets/Tiny Top-Down Village/Hunters Cabin.png", 1120, 560, 64, 36, 18, false],
	["LumberjackHouse", "Lumberjack's Lodge", "res://assets/Tiny Top-Down Village/Lumberjack House.png", 1440, 560, 64, 36, 18, false],
	["WatchmakersHouse", "Watchmaker's Workshop", "res://assets/Tiny Top-Down Village/Watchmakers House.png", 1800, 1150, 64, 36, 18, false],
	["ChurchBuilding", "Parish Chapel", "res://assets/landmarks/church.png", 1440, 1000, 96, 50, 25, true],
	["FishermansHut", "Fisherman's Shack", "res://assets/Tiny Top-Down Village/Fishermans Hut.png", 680, 1050, 64, 36, 18, false],
	["PottersHouse", "Potter's Kiln House", "res://assets/Tiny Top-Down Village/Potters House.png", 640, 1680, 64, 36, 18, false],
	["SmallWoodenCottage", "Coastal Cottage", "res://assets/Tiny Top-Down Village/Small Wooden Cottage.png", 640, 1920, 64, 36, 18, false],
	["BeachCottage", "Beachcomb House", "res://assets/Tiny Top-Down Village/Stone Village House.png", 640, 2140, 64, 36, 18, false],
	["BakeryBuilding", "Village Bakery", "res://assets/Tiny Top-Down Village/Bakery.png", 1060, 1024, 64, 36, 18, true],
	["BlacksmithHouse", "Blacksmith Forge", "res://assets/Tiny Top-Down Village/Blacksmith House.png", 1060, 1280, 64, 36, 18, false],
	["TailorsHouse", "Tailor's Atelier", "res://assets/Tiny Top-Down Village/Tailors House.png", 1060, 1540, 64, 36, 18, false],
	["Tavern", "The Drunken Gull Tavern", "res://assets/Tiny Top-Down Village/Tavern.png", 1060, 1800, 64, 36, 18, false],
	["BrewersHouse", "Brewer's Lodge", "res://assets/Tiny Top-Down Village/Brewers House.png", 1440, 1280, 64, 36, 18, false],
	["FloristsHouse", "Florist's Garden House", "res://assets/Tiny Top-Down Village/Florists House.png", 1180, 1024, 64, 36, 18, false],
	["HerbalistHouse", "Herbalist's Cottage", "res://assets/Tiny Top-Down Village/Herbalist House.png", 1180, 1280, 64, 36, 18, false],
	["CarpentersHouse", "Carpenter's Workshop", "res://assets/Tiny Top-Down Village/Carpenters House.png", 1180, 1540, 64, 36, 18, false],
	["ToyMakersHouse", "Toymaker's Cottage", "res://assets/Tiny Top-Down Village/Toy Makers House.png", 1180, 1800, 64, 36, 18, false],
	["MusiciansHouse", "Bard's Cottage", "res://assets/Tiny Top-Down Village/Musicians House.png", 1920, 1340, 64, 36, 18, false],
	["PostHouse", "Kurtos Waystation", "res://assets/Tiny Top-Down Village/Post House.png", 2112, 1340, 64, 36, 18, false],
	["FarmersHouse", "Valley Farmhouse", "res://assets/Tiny Top-Down Village/Farmers House.png", 3120, 1152, 64, 36, 18, false],
	["StorageBarn", "Harvest Barn", "res://assets/landmarks/barn.png", 3120, 1400, 80, 40, 20, false],
	["BeekeepersHut", "Beekeeper's Apiary", "res://assets/Tiny Top-Down Village/Beekeepers Hut.png", 3550, 1400, 64, 36, 18, false],
	["MillHouse", "Granary Mill House", "res://assets/Tiny Top-Down Village/Mill House.png", 3120, 1680, 64, 36, 18, false],
	["CoastCabin", "Eastern Shore Cabin", "res://assets/Tiny Top-Down Village/Small Wooden Cottage.png", 3550, 1680, 64, 36, 18, false],
	["MinersShed", "Mine Equipment Depot", "res://assets/Tiny Top-Down Village/Storage House.png", 3260, 2080, 64, 36, 18, false],
]

func _init() -> void:
	print("▶ Building World Buildings Scene...")
	var b_packed: PackedScene = load("res://assets/objects/village_building.tscn")
	assert(b_packed != null, "village_building.tscn must load")

	var root_node := Node2D.new()
	root_node.name = "Buildings"
	root_node.y_sort_enabled = true

	for cfg in BUILDINGS_CONFIG:
		var node_name: String = cfg[0]
		var display_name: String = cfg[1]
		var tex_path: String = cfg[2]
		var pos_x: float = float(cfg[3])
		var pos_y: float = float(cfg[4])
		var fp_w: float = float(cfg[5])
		var fp_h: float = float(cfg[6])
		var off_y: float = float(cfg[7])
		var match_poly: bool = bool(cfg[8])

		var tex: Texture2D = load(tex_path)
		if tex == null:
			print("❌ Missing texture: ", tex_path)
			continue

		var bld := b_packed.instantiate() as VillageBuilding
		bld.name = node_name
		bld.position = Vector2(pos_x, pos_y)
		bld.building_name = display_name
		bld.building_texture = tex
		bld.footprint_size = Vector2(fp_w, fp_h)
		bld.footprint_offset = Vector2(0, off_y)
		bld.match_asset_collider = match_poly
		bld.show_label = false

		root_node.add_child(bld)
		bld.owner = root_node
		# NOTE: Do NOT set child.owner = root_node! Setting child.owner corrupts instance inheritance and causes editor dialog popup errors.

		# Call setup on each
		bld._update_building()

	print("  Added %d buildings to Buildings container." % root_node.get_child_count())

	var scene := PackedScene.new()
	var pack_err := scene.pack(root_node)
	if pack_err != OK:
		print("❌ Failed to pack scene: ", pack_err)
		quit(1)
		return

	var save_err := ResourceSaver.save(scene, "res://scenes/world_buildings.tscn")
	if save_err != OK:
		print("❌ Failed to save res://scenes/world_buildings.tscn: ", save_err)
		quit(1)
		return

	print("✅ Successfully built and saved res://scenes/world_buildings.tscn!")
	quit(0)
