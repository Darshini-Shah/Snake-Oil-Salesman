extends SceneTree

const BUILDINGS_CONFIG = [
	# [NodeName, DisplayName, TextureResPath, x, y, footprint_w, footprint_h, offset_y, match_poly, scale_factor]
	["RoyalCastle", "Royal Citadel & Fortress", "res://assets/landmarks/royal_castle.png", 3280, 480, 300, 70, 45, false, 1.6],
	["ScholarAcademy", "Northern Scholar Academy", "res://assets/landmarks/academy.png", 2024, 260, 200, 60, 35, false, 1.5],
	["SmugglerCave", "Smuggler's Grotto", "res://assets/landmarks/mountain_cave.png", 580, 520, 90, 40, 25, false, 1.5],
	["Lighthouse", "Gull Rock Lighthouse", "res://assets/landmarks/lighthouse.png", 240, 1120, 90, 60, 35, false, 1.5],
	["PlazaFountain", "Kurtos Plaza Fountain", "res://assets/landmarks/fountain.png", 2024, 1120, 60, 60, 0, false, 1.4],
	["Windmill", "Golden Windmill", "res://assets/landmarks/windmill.png", 3440, 1120, 90, 50, 35, false, 1.7],
	["MineEntrance", "Deep Stone Mine", "res://assets/landmarks/mine_entrance.png", 3440, 2080, 150, 40, 25, false, 1.5],
	["TownHall", "Kurtos Town Hall", "res://assets/landmarks/town_hall.png", 2024, 920, 180, 50, 35, false, 1.5],
	["MerchantShop", "Plaza Merchant Shop", "res://assets/Tiny Top-Down Village/General Store.png", 1720, 1040, 110, 44, 35, true, 1.85],
	["WatchmakersHouse", "Watchmaker's Workshop", "res://assets/Tiny Top-Down Village/Watchmakers House.png", 1720, 1200, 110, 44, 35, false, 1.85],
	["DoctorsClinic", "Doctor's Clinic", "res://assets/Tiny Top-Down Village/Doctors House.png", 2300, 1040, 110, 44, 35, false, 1.85],
	["MayorsResidence", "Mayor's Manor", "res://assets/Tiny Top-Down Village/Mayors Residence.png", 2300, 1200, 110, 44, 35, false, 1.85],
	["Library", "Kurtos Archive & Library", "res://assets/Tiny Top-Down Village/Library.png", 2300, 1360, 110, 44, 35, false, 1.85],
	["MusiciansHouse", "Bard's Cottage", "res://assets/Tiny Top-Down Village/Musicians House.png", 1880, 1380, 110, 44, 35, false, 1.85],
	["PostHouse", "Kurtos Waystation", "res://assets/Tiny Top-Down Village/Post House.png", 2160, 1380, 110, 44, 35, false, 1.85],
	["HuntersCabin", "Hunter's Cabin", "res://assets/Tiny Top-Down Village/Hunters Cabin.png", 1120, 560, 110, 44, 35, false, 1.85],
	["LumberjackHouse", "Lumberjack's Lodge", "res://assets/Tiny Top-Down Village/Lumberjack House.png", 1440, 560, 110, 44, 35, false, 1.85],
	["ChurchBuilding", "Parish Chapel", "res://assets/landmarks/church.png", 1540, 980, 140, 50, 35, true, 1.5],
	["BrewersHouse", "Brewer's Lodge", "res://assets/Tiny Top-Down Village/Brewers House.png", 1540, 1260, 110, 44, 35, false, 1.85],
	["FishermansHut", "Fisherman's Shack", "res://assets/Tiny Top-Down Village/Fishermans Hut.png", 620, 1050, 110, 44, 35, false, 1.85],
	["PottersHouse", "Potter's Kiln House", "res://assets/Tiny Top-Down Village/Potters House.png", 600, 1680, 110, 44, 35, false, 1.85],
	["SmallWoodenCottage", "Coastal Cottage", "res://assets/Tiny Top-Down Village/Small Wooden Cottage.png", 600, 1920, 110, 44, 35, false, 1.85],
	["BeachCottage", "Beachcomb House", "res://assets/Tiny Top-Down Village/Stone Village House.png", 600, 2160, 110, 44, 35, false, 1.85],
	["BakeryBuilding", "Village Bakery", "res://assets/Tiny Top-Down Village/Bakery.png", 1120, 980, 110, 44, 35, true, 1.85],
	["BlacksmithHouse", "Blacksmith Forge", "res://assets/Tiny Top-Down Village/Blacksmith House.png", 1120, 1240, 110, 44, 35, false, 1.85],
	["TailorsHouse", "Tailor's Atelier", "res://assets/Tiny Top-Down Village/Tailors House.png", 1120, 1500, 110, 44, 35, false, 1.85],
	["Tavern", "The Drunken Gull Tavern", "res://assets/Tiny Top-Down Village/Tavern.png", 1120, 1780, 110, 44, 35, false, 1.85],
	["FloristsHouse", "Florist's Garden House", "res://assets/Tiny Top-Down Village/Florists House.png", 1340, 980, 110, 44, 35, false, 1.85],
	["HerbalistHouse", "Herbalist's Cottage", "res://assets/Tiny Top-Down Village/Herbalist House.png", 1340, 1240, 110, 44, 35, false, 1.85],
	["CarpentersHouse", "Carpenter's Workshop", "res://assets/Tiny Top-Down Village/Carpenters House.png", 1340, 1500, 110, 44, 35, false, 1.85],
	["ToyMakersHouse", "Toymaker's Cottage", "res://assets/Tiny Top-Down Village/Toy Makers House.png", 1310, 1780, 110, 44, 35, false, 1.85],
	["FarmersHouse", "Valley Farmhouse", "res://assets/Tiny Top-Down Village/Farmers House.png", 3120, 1152, 110, 44, 35, false, 1.85],
	["StorageBarn", "Harvest Barn", "res://assets/landmarks/barn.png", 3120, 1400, 120, 50, 30, false, 1.6],
	["BeekeepersHut", "Beekeeper's Apiary", "res://assets/Tiny Top-Down Village/Beekeepers Hut.png", 3550, 1400, 110, 44, 35, false, 1.85],
	["MillHouse", "Granary Mill House", "res://assets/Tiny Top-Down Village/Mill House.png", 3240, 1640, 110, 44, 35, false, 1.85],
	["CoastCabin", "Eastern Shore Cabin", "res://assets/Tiny Top-Down Village/Small Wooden Cottage.png", 3550, 1680, 110, 44, 35, false, 1.85],
	["MinersShed", "Mine Equipment Depot", "res://assets/Tiny Top-Down Village/Storage House.png", 3260, 2080, 110, 44, 35, false, 1.85],
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
		var scale_factor: float = float(cfg[9])

		var tex: Texture2D = load(tex_path)
		if tex == null:
			print("❌ Missing texture: ", tex_path)
			continue

		var bld := b_packed.instantiate() as VillageBuilding
		bld.name = node_name
		bld.position = Vector2(pos_x, pos_y)
		bld.building_name = display_name
		bld.building_texture = tex
		bld.sprite_scale = Vector2(scale_factor, scale_factor)
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
