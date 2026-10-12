extends SceneTree
## Actual _ready() identity, generation, prompt and gameplay preservation checks.
const Profiles = preload("res://scripts/character_profiles.gd")
const Builder = preload("res://scripts/build_world_characters.gd")
var failures := 0
var checks := 0
var baseline: Array

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	if ProjectSettings.get_setting("application/config/name") != "Snake Oil Salesman Integration Tests":
		push_error("Run through tests/run_isolated.ps1 to keep fixtures and saves isolated")
		quit(1)
		return
	baseline = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/npc_identity_baseline.json"))
	check(Profiles.validation_errors().is_empty(), "Catalog validates")
	var world: Node2D = load("res://scenes/world_characters.tscn").instantiate()
	root.add_child(world)
	await process_frame
	verify_world(world, "saved scene")
	# Pack and initialize regenerated instances without replacing the actual world file.
	var built := Builder.create_characters()
	check(built != null, "Generator builds all characters")
	if built:
		var packed := PackedScene.new()
		check(packed.pack(built) == OK, "Generator packs")
		built.free()
		var regenerated := packed.instantiate()
		root.add_child(regenerated)
		await process_frame
		verify_world(regenerated, "regenerated scene")
		regenerated.free()
	verify_invalid_profiles()
	await verify_chat(world)
	world.free()
	await process_frame
	print("NPC identity: %d checks, %d failures (46 NPCs, 9 guards; saved and regenerated _ready)" % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_world(world: Node2D, source: String) -> void:
	check(world.get_child_count() == 55, source + " has exactly 55 characters")
	var seen_ids := {}
	var seen_names := {}
	var npc_count := 0
	var guard_count := 0
	var llm := LocalLLM.new()
	for expected in baseline:
		var character = world.get_node_or_null(expected.node_name)
		check(character != null, source + " contains " + expected.node_name)
		if character == null: continue
		var profile: Dictionary = character.get_full_profile()
		var label: String = source + ": " + expected.node_name
		check(character.character_id == expected.id and profile.get("id") == expected.id, label + " stable exported/runtime ID")
		check(profile.get("name") == expected.name and not str(profile.get("name", "")).is_empty(), label + " authored name")
		check(profile.get("occupation") == expected.occupation, label + " occupation")
		check(not seen_ids.has(expected.id) and not seen_names.has(profile.get("name")), label + " unique identity")
		seen_ids[expected.id] = true
		seen_names[profile.get("name")] = true
		check(not Profiles.entry_for(expected.id).is_empty(), label + " catalog entry")
		for field in ["age_group", "identity_personality", "background", "motivations", "likes", "dislikes", "fears", "ambitions", "habits", "speech_style", "knowledge", "relationships", "llm_summary"]:
			check(profile.has(field) and not str(profile[field]).is_empty(), label + " complete " + field)
		check(character.position == Vector2(expected.position[0], expected.position[1]), label + " unchanged position")
		check(character.get_node("Sprite2D").texture.resource_path == expected.texture, label + " unchanged sprite")
		if expected.guard:
			guard_count += 1
			check(character is TownGuard and character.guard_name == expected.name and character.guard_title == expected.occupation, label + " distinct guard")
			check(not character.is_in_group("npcs") and not profile.chat_enabled and not character.has_method("add_conversation_turn"), label + " no new guard chat")
			check(not character.is_hostile and character.challenge_message == "Halt! Keep clear of restricted premises!", label + " guard behavior unchanged")
		else:
			npc_count += 1
			check(character is TownNPC and profile.chat_enabled and character.is_in_group("npcs"), label + " existing chat eligibility")
			check(character.npc_name == expected.name and character.npc_title == expected.occupation, label + " runtime display identity")
			check(character.npc_data_file == expected.profile_file, label + " correct original file assignment")
			for stat in ["gold", "trust", "suspicion", "max_daily_spend"]:
				check(character.get(stat) == expected[stat] and profile[stat] == expected[stat], label + " scene gameplay stat " + stat)
			check(character.spent_today == 0 and character.successful_scam_count == 0 and character.failed_scam_count == 0, label + " untouched counters")
			if not expected.profile_file.is_empty():
				var authored: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(expected.profile_file))
				for field in authored:
					check(profile[field] == authored[field], label + " preserved original field " + field)
			else:
				check(profile.personality == Profiles.NEUTRAL_TRAITS and character.susceptible_topics.is_empty() and character.skeptical_topics.is_empty(), label + " prose has no numeric scam effects")
				check(profile.id != "npc_barnaby_merchant" and profile.name != "Barnaby" and not profile.background.contains("seasoned merchant"), label + " no Barnaby inheritance")
			var context: String = llm.build_chat_payload(profile, "Who are you?", []).messages[0].content
			# Removing every narrative addition must leave the existing gameplay formula identical.
			var stats_only := profile.duplicate(true)
			for field in ["identity_personality", "llm_summary", "background", "motivations", "likes", "dislikes", "fears", "ambitions", "habits", "speech_style", "knowledge", "relationships", "secrets", "greeting", "values", "goals"]:
				stats_only.erase(field)
			var inventory: Array[Dictionary] = [{"id": "fabric_sample", "name": "Fabric Sample"}]
			for speech in ["Good day", "I will sell this fabric sample for 40 Kurtos", "Tell me about local rumors", "Give me your coin"]:
				var category := ScamManager.categorize_message(speech, inventory)
				var evaluation := {"score": 70}
				check(ScamManager.resolve_interaction(category, profile, speech, evaluation, inventory, 25) == ScamManager.resolve_interaction(category, stats_only, speech, evaluation, inventory, 25), label + " narrative cannot change gameplay: " + speech)
			check(llm._get_heuristic_evaluation_score(profile, "profit charity miracle") == llm._get_heuristic_evaluation_score(stats_only, "profit charity miracle"), label + " no narrative heuristic changes")
			check(context.contains(expected.name) and context.contains(expected.occupation) and context.contains(profile.llm_summary), label + " active Qwen persona")
			check(context.length() < 2300 and not context.contains("character_catalog") and not context.contains("node_name"), label + " bounded self-only context")
			check(context.contains("cannot award money/items") and context.contains("no transaction or gifts"), label + " dialogue authority boundary")
			check(llm._get_default_dialogue_for_decision(profile, "CONVERSE_POSITIVE").find("Barnaby") == -1 if expected.name != "Barnaby" else true, label + " safe offline identity")
	check(npc_count == 46 and guard_count == 9, source + " NPC/guard counts")
	llm.free()

func verify_invalid_profiles() -> void:
	var npc := TownNPC.new()
	npc.character_id = "missing_character"
	npc.npc_name = "Test Resident"
	npc.npc_title = "Test Craftsperson"
	npc.gold = 77
	npc.trust = 19
	npc.suspicion = 42
	npc.max_daily_spend = 23
	npc.spent_today = 8
	root.add_child(npc)
	check(npc.npc_name == "Test Resident" and npc.npc_title == "Test Craftsperson" and npc.npc_profile.id == "missing_character", "Missing profile keeps self identity")
	check(npc.gold == 77 and npc.trust == 19 and npc.suspicion == 42 and npc.max_daily_spend == 23 and npc.spent_today == 8, "Missing profile preserves all configured stats")
	npc.free()
	var mismatch := TownNPC.new()
	mismatch.character_id = "npc_mayor_vance"
	mismatch.npc_data_file = "res://data/npcs/barnaby_merchant.json"
	mismatch.npc_name = "Mayor Vance"
	root.add_child(mismatch)
	check(mismatch.npc_profile.id == "npc_mayor_vance" and mismatch.npc_name == "Mayor Vance" and mismatch.susceptible_topics.is_empty(), "Wrong Barnaby assignment fails safely")
	mismatch.free()
	var entry := Profiles.entry_for("npc_mayor_vance")
	check(not Profiles.validate_entries([entry, entry]).is_empty(), "Duplicate IDs/nodes rejected")
	check(not Profiles.validate_entries([{}, 2]).is_empty(), "Malformed/missing identity rejected")
	# Exercise missing file, malformed JSON, wrong ID and invalid identity after _ready.
	var saved: Dictionary = Profiles._entries["npc_mayor_vance"].duplicate(true)
	var path := "user://invalid_identity.json"
	for contents in ["MISSING", "not json", '{"id":"npc_barnaby_merchant","name":"Barnaby","occupation":"Merchant","personality":{}}', '{"id":"npc_mayor_vance","name":"","occupation":"Mayor","personality":{}}', '{"id":"npc_mayor_vance","name":"Mayor Vance","occupation":"Mayor","personality":{"greedy":"very"}}', '{"id":"npc_mayor_vance","name":"Mayor Vance","occupation":"Mayor","personality":{},"memories":"wrong type"}']:
		if contents != "MISSING":
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_string(contents)
			file.close()
		Profiles._entries["npc_mayor_vance"] = saved.duplicate(true)
		Profiles._entries["npc_mayor_vance"]["profile_file"] = path
		var invalid := TownNPC.new()
		invalid.character_id = "npc_mayor_vance"
		invalid.npc_name = "Mayor Vance"
		invalid.gold = 987
		invalid.max_daily_spend = 29
		root.add_child(invalid)
		check(invalid.npc_name == "Mayor Vance" and invalid.npc_profile.id == "npc_mayor_vance" and invalid.gold == 987 and invalid.max_daily_spend == 29, "Invalid profile fails safely: " + contents.left(18))
		invalid.free()
	Profiles._entries["npc_mayor_vance"] = saved
	DirAccess.remove_absolute(path)
	var custom := TownNPC.new()
	custom.character_id = "npc_marla_baker"
	custom.gold = 99
	custom.trust = 3
	custom.suspicion = 88
	custom.max_daily_spend = 17
	custom.spent_today = 11
	root.add_child(custom)
	check(custom.gold == 99 and custom.trust == 3 and custom.suspicion == 88 and custom.max_daily_spend == 17 and custom.spent_today == 11, "Valid authored profile cannot override scene stats")
	custom.free()

func verify_chat(world: Node2D) -> void:
	var chat: ChatUI = load("res://scenes/ui/chat_ui.tscn").instantiate()
	chat.get_node("LocalLLM").enabled = false
	root.add_child(chat)
	var prior: TownNPC
	var prior_history: Array = []
	for node in ["NPC_Barnaby", "NPC_Marla", "NPC_Cedric", "NPC_Arthur", "NPC_DoctorHawthorne", "NPC_KingReginald", "NPC_ApprenticeLeo", "NPC_SmugglerJack", "NPC_MinerCole"]:
		var npc: TownNPC = world.get_node(node)
		chat.start_conversation(npc)
		check(chat.get_npc_id(npc) == npc.character_id and chat.get_active_npc_history().is_empty(), node + " isolated empty history")
		if node != "NPC_Barnaby": check(not chat.dialogue_text.text.contains("Barnaby's"), node + " greeting is not Barnaby")
		chat._on_pitch_pressed()
		if node != "NPC_Barnaby": check(not chat.message_input.text.contains("Barnaby"), node + " pitch is not Barnaby")
		chat.message_input.text = "How fares your work?"
		chat._on_send_pressed()
		for i in range(4): await process_frame
		check(npc.conversation_history.size() == 2 and str(npc.conversation_history[1]).begins_with(npc.npc_name + ": "), node + " actual offline reply/history belongs to self")
		if prior: check(prior.conversation_history == prior_history, node + " preserves previous NPC history")
		prior = npc
		prior_history = npc.conversation_history.duplicate()
		chat.end_conversation()
	chat.queue_free()
	await process_frame
