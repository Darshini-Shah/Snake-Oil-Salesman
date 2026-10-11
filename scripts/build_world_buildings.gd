extends SceneTree

const BUILDINGS_CONFIG = [
	# [NodeName, DisplayName, TextureResPath, x, y, footprint_w, footprint_h, offset_y, match_poly, scale_factor]
	["RoyalCastle", "Royal Citadel & Fortress", "res://assets/landmarks/royal_castle.png", 3300, 460, 400, 90, 60, false, 2.0],
	["ScholarAcademy", "Northern Scholar Academy", "res://assets/landmarks/academy.png", 2056, 250, 260, 70, 45, false, 1.85],
	["SmugglerCave", "Smuggler's Grotto", "res://assets/landmarks/mountain_cave.png", 580, 520, 120, 50, 35, false, 1.8],
	["Lighthouse", "Gull Rock Lighthouse", "res://assets/landmarks/lighthouse.png", 240, 1120, 120, 80, 50, false, 1.8],
	["PlazaFountain", "Kurtos Plaza Fountain", "res://assets/landmarks/fountain.png", 2056, 1128, 80, 80, 0, false, 1.6],
	["Windmill", "Golden Windmill", "res://assets/landmarks/windmill.png", 3450, 1120, 120, 70, 50, false, 2.2],
	["MineEntrance", "Deep Stone Mine", "res://assets/landmarks/mine_entrance.png", 3440, 2100, 200, 60, 35, false, 1.85],
	["TownHall", "Kurtos Town Hall", "res://assets/landmarks/town_hall.png", 2056, 800, 240, 70, 50, false, 1.85],
	["MerchantShop", "Plaza Merchant Shop", "res://assets/Tiny Top-Down Village/General Store.png", 1850, 1030, 140, 55, 45, false, 2.4],
	["WatchmakersHouse", "Watchmaker's Workshop", "res://assets/Tiny Top-Down Village/Watchmakers House.png", 1850, 1260, 140, 55, 45, false, 2.4],
	["DoctorsClinic", "Doctor's Clinic", "res://assets/Tiny Top-Down Village/Doctors House.png", 2270, 1030, 140, 55, 45, false, 2.4],
	["MayorsResidence", "Mayor's Manor", "res://assets/Tiny Top-Down Village/Mayors Residence.png", 2270, 1260, 140, 55, 45, false, 2.4],
	["Library", "Kurtos Archive & Library", "res://assets/Tiny Top-Down Village/Library.png", 2520, 1260, 140, 55, 45, false, 2.4],
	["MusiciansHouse", "Bard's Cottage", "res://assets/Tiny Top-Down Village/Musicians House.png", 1850, 1520, 140, 55, 45, false, 2.4],
	["PostHouse", "Kurtos Waystation", "res://assets/Tiny Top-Down Village/Post House.png", 2270, 1520, 140, 55, 45, false, 2.4],
	["HuntersCabin", "Hunter's Cabin", "res://assets/Tiny Top-Down Village/Hunters Cabin.png", 1080, 420, 140, 55, 45, false, 2.4],
	["LumberjackHouse", "Lumberjack's Lodge", "res://assets/Tiny Top-Down Village/Lumberjack House.png", 1400, 420, 140, 55, 45, false, 2.4],
	["ChurchBuilding", "Parish Chapel", "res://assets/landmarks/church.png", 1620, 780, 180, 70, 50, false, 1.85],
	["BrewersHouse", "Brewer's Lodge", "res://assets/Tiny Top-Down Village/Brewers House.png", 1620, 1310, 140, 55, 45, false, 2.4],
	["FishermansHut", "Fisherman's Shack", "res://assets/Tiny Top-Down Village/Fishermans Hut.png", 620, 1040, 130, 45, 35, false, 2.4],
	["PottersHouse", "Potter's Kiln House", "res://assets/Tiny Top-Down Village/Potters House.png", 580, 1680, 140, 55, 45, false, 2.4],
	["SmallWoodenCottage", "Coastal Cottage", "res://assets/Tiny Top-Down Village/Small Wooden Cottage.png", 580, 1940, 140, 55, 45, false, 2.4],
	["BeachCottage", "Beachcomb House", "res://assets/Tiny Top-Down Village/Stone Village House.png", 580, 2200, 140, 55, 45, false, 2.4],
	["BakeryBuilding", "Village Bakery", "res://assets/Tiny Top-Down Village/Bakery.png", 1100, 960, 140, 55, 45, false, 2.4],
	["BlacksmithHouse", "Blacksmith Forge", "res://assets/Tiny Top-Down Village/Blacksmith House.png", 1115, 1310, 135, 55, 45, false, 2.4],
	["TailorsHouse", "Tailor's Atelier", "res://assets/Tiny Top-Down Village/Tailors House.png", 1100, 1590, 140, 55, 45, false, 2.4],
	["Tavern", "The Drunken Gull Tavern", "res://assets/Tiny Top-Down Village/Tavern.png", 1100, 1870, 140, 55, 45, false, 2.4],
	["FloristsHouse", "Florist's Garden House", "res://assets/Tiny Top-Down Village/Florists House.png", 1400, 960, 140, 55, 45, false, 2.4],
	["HerbalistHouse", "Herbalist's Cottage", "res://assets/Tiny Top-Down Village/Herbalist House.png", 1400, 1310, 140, 55, 45, false, 2.4],
	["CarpentersHouse", "Carpenter's Workshop", "res://assets/Tiny Top-Down Village/Carpenters House.png", 1400, 1590, 140, 55, 45, false, 2.4],
	["ToyMakersHouse", "Toymaker's Cottage", "res://assets/Tiny Top-Down Village/Toy Makers House.png", 1400, 1870, 140, 55, 45, false, 2.4],
	["FarmersHouse", "Valley Farmhouse", "res://assets/Tiny Top-Down Village/Farmers House.png", 3080, 1120, 140, 55, 45, false, 2.4],
	["StorageBarn", "Harvest Barn", "res://assets/landmarks/barn.png", 3080, 1420, 160, 70, 40, false, 2.0],
	["BeekeepersHut", "Beekeeper's Apiary", "res://assets/Tiny Top-Down Village/Beekeepers Hut.png", 3550, 1420, 140, 55, 45, false, 2.4],
	["MillHouse", "Granary Mill House", "res://assets/Tiny Top-Down Village/Mill House.png", 3250, 1700, 140, 55, 45, false, 2.4],
	["CoastCabin", "Eastern Shore Cabin", "res://assets/Tiny Top-Down Village/Small Wooden Cottage.png", 3550, 1740, 140, 55, 45, false, 2.4],
	["MinersShed", "Mine Equipment Depot", "res://assets/Tiny Top-Down Village/Storage House.png", 3180, 2100, 140, 55, 45, false, 2.4],
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
