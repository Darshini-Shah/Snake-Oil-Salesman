extends SceneTree

var frame_count := 0
var main: Node2D

func _init() -> void:
	print("▶ Testing Island Characters Distribution, Sprites & Placement...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "scenes/main.tscn loads successfully")
	main = main_scene.instantiate()
	root.add_child(main)
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	frame_count += 1
	if frame_count < 2:
		return

	print("▶ Physics space active. Running character tests...")

	# 1. Characters container
	var characters_node = main.get_node_or_null("Characters")
	assert(characters_node != null, "Characters node exists in main scene")
	var count = characters_node.get_child_count()
	assert(count >= 50, "Characters container has >= 50 characters (Actual: %d)" % count)
	print("  ✅ PASS: Characters container active with %d diverse characters" % count)

	# 2. Key Characters Roster Verification
	var required_characters = [
		# Civic Plaza
		"NPC_MayorVance", "NPC_Barnaby", "NPC_DoctorHawthorne", "NPC_WatchmakerTock",
		"NPC_LibrarianElena", "NPC_Cedric", "NPC_JesterPip", "NPC_BardLyra",
		"NPC_CitizenClara", "NPC_CitizenHugo", "Guard_TownNorth", "Guard_TownSouth",
		# Royal Citadel
		"NPC_KingReginald", "NPC_QueenKatherine", "Guard_RoyalKnightWest",
		"Guard_RoyalKnightEast", "Guard_CourtyardKnight",
		# Scholar Academy
		"NPC_HeadmasterThaddeus", "NPC_ApprenticeLeo", "NPC_SageAlbus",
		# Smugglers & Lighthouse
		"NPC_SmugglerJack", "NPC_ShadowRogue", "NPC_LighthouseKeeper",
		# West Village
		"NPC_Marla", "NPC_BlacksmithBoros", "NPC_TailorVivienne", "NPC_TavernkeeperMaggie",
		"NPC_FloristLily", "NPC_HerbalistMaeve", "NPC_CarpenterWayne", "NPC_ToymakerOswald",
		"NPC_PriestJoseph", "NPC_Arthur", "NPC_FishermanFinn", "NPC_PotterGordon",
		"NPC_LumberjackKarl", "NPC_HunterOrion", "NPC_ElderMarta", "NPC_ChildTimmy", "NPC_ChildRosie",
		# Farmlands
		"NPC_FarmerGiles", "NPC_FarmhandPete", "NPC_BeekeeperBeatrice", "NPC_MillerDonald",
		# Mine
		"NPC_ForemanIronbeard", "NPC_MinerCole",
		# South Bridge & Gates
		"Guard_BridgeCaptain", "Guard_BridgeSentry", "NPC_TravelerFelix",
		"Guard_Footbridge1", "Guard_Footbridge2"
	]

	for char_name in required_characters:
		var char_node = characters_node.get_node_or_null(char_name)
		assert(char_node != null, "Character '%s' exists" % char_name)
		assert(char_node is CharacterBody2D, "Character '%s' is a CharacterBody2D" % char_name)
		var sprite = char_node.get_node_or_null("Sprite2D") as Sprite2D
		assert(sprite != null and sprite.texture != null, "Character '%s' has valid sprite texture" % char_name)
		assert(sprite.hframes == 3 and sprite.vframes == 4, "Character '%s' sprite has 3x4 walk sheet frames" % char_name)
		assert(char_node.position.x > 0 and char_node.position.x < 4096, "Character '%s' within island map X bounds" % char_name)
		assert(char_node.position.y > 0 and char_node.position.y < 2816, "Character '%s' within island map Y bounds" % char_name)

	print("  ✅ PASS: All %d required landmark characters verified with valid 3x4 spritesheets" % required_characters.size())

	# 3. Verify No Overlap with Player Spawn (2048, 2560)
	var player_spawn = Vector2(2048, 2560)
	for char_node in characters_node.get_children():
		var dist = (char_node.position - player_spawn).length()
		assert(dist >= 40.0, "Character '%s' does not crowd player spawn (dist: %.1fpx)" % [char_node.name, dist])
	print("  ✅ PASS: All characters comfortably distanced from player spawn point")

	# 4. Verify NPC Interaction & Player Tracking (e.g. Barnaby in Civic Plaza)
	var barnaby = characters_node.get_node("NPC_Barnaby") as TownNPC
	assert(barnaby != null, "Barnaby exists")
	var barnaby_sprite = barnaby.get_node("Sprite2D") as Sprite2D
	var player = main.get_node("Player") as CharacterBody2D

	# Place player directly south of Barnaby
	player.global_position = barnaby.global_position + Vector2(0, 36)
	barnaby._on_interaction_area_body_entered(player)
	barnaby._process(0.016)
	assert(barnaby_sprite.frame == 1, "Barnaby faces down (frame 1) when player is south of him")

	# Move player to right of Barnaby
	player.global_position = barnaby.global_position + Vector2(36, 0)
	barnaby._process(0.016)
	assert(barnaby_sprite.frame == 7, "Barnaby dynamically turns to face right (frame 7) when player steps east")
	print("  ✅ PASS: Dynamic NPC interaction and player gaze tracking verified")

	print("\n-------------------------------------------------------")
	print("🏁 ALL ISLAND CHARACTERS TESTS PASSED!")
	print("-------------------------------------------------------")
	quit(0)
