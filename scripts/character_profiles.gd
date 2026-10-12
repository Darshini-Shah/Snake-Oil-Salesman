class_name CharacterProfiles
extends RefCounted
## Identity only. Scene exports own social/economy state; prose is never a scam trait.
const CATALOG_PATH := "res://data/npcs/character_catalog.json"
const NEUTRAL_TRAITS := {"trusting": 0.5, "skeptical": 0.5, "empathetic": 0.5, "greedy": 0.5}
static var _entries: Dictionary = {}
static var _loaded := false
static var _errors: Array[String] = []

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var parser := JSON.new()
	var parsed: Variant = parser.data if parser.parse(FileAccess.get_file_as_string(CATALOG_PATH)) == OK else null
	if not parsed is Array:
		_errors.append("Character catalog must be an array")
		return
	_errors = validate_entries(parsed)
	if not _errors.is_empty():
		push_warning("Invalid character catalog: " + "; ".join(_errors))
		return # Reject ambiguous identity mappings rather than pick a duplicate.
	for entry in parsed:
		_entries[entry.id] = entry

static func validate_entries(entries: Array) -> Array[String]:
	var errors: Array[String] = []
	var ids := {}
	var nodes := {}
	var files := {}
	var names := {}
	for entry in entries:
		if not entry is Dictionary:
			errors.append("Non-object character entry")
			continue
		for field in ["id", "node_name", "identity_personality", "llm_summary", "speech_style", "location"]:
			if not entry.get(field) is String or str(entry.get(field, "")).strip_edges().is_empty():
				errors.append("Missing character field: " + field)
		var id := str(entry.get("id", ""))
		var node := str(entry.get("node_name", ""))
		if ids.has(id) or nodes.has(node):
			errors.append("Duplicate character ID or node: " + id)
		ids[id] = true
		nodes[node] = true
		var path := str(entry.get("profile_file", ""))
		if not path.is_empty():
			if files.has(path): errors.append("Duplicate profile assignment: " + path)
			files[path] = true
		elif not _valid_identity(entry, id):
			errors.append("Invalid identity: " + id)
		if path.is_empty():
			var display_name := str(entry.get("name", ""))
			if names.has(display_name): errors.append("Duplicate display name: " + display_name)
			names[display_name] = true
			if not entry.get("background") is String or str(entry.get("background", "")).is_empty():
				errors.append("Missing background for " + id)
		if not entry.get("chat_enabled") is bool:
			errors.append("Missing chat eligibility for " + id)
		for field in ["motivations", "likes", "dislikes", "ambitions", "habits", "knowledge", "relationships"]:
			if not entry.get(field) is Array:
				errors.append("Invalid narrative array " + field + " for " + id)
	for entry in entries:
		if not entry is Dictionary: continue
		var relations: Variant = entry.get("relationships", [])
		if not relations is Array: continue
		for relation in relations:
			if not relation is Dictionary or not ids.has(relation.get("character_id", "")):
				errors.append("Unknown relationship for " + str(entry.get("id", "")))
	return errors

static func _valid_identity(profile: Dictionary, id: String) -> bool:
	if str(profile.get("id", "")) != id or id.is_empty(): return false
	for field in ["name", "occupation"]:
		if not profile.get(field) is String or str(profile.get(field, "")).strip_edges().is_empty(): return false
	return true

static func _valid_authored_profile(profile: Dictionary, id: String) -> bool:
	if not _valid_identity(profile, id) or not profile.get("personality") is Dictionary:
		return false
	for trait_value in profile.personality.values():
		if not (trait_value is float or trait_value is int): return false
	for field in ["susceptible_topics", "skeptical_topics", "memories"]:
		if profile.has(field) and not profile[field] is Array: return false
	return true

static func validation_errors() -> Array[String]:
	_ensure_loaded()
	return _errors.duplicate()

static func entry_for(id: String) -> Dictionary:
	_ensure_loaded()
	return _entries.get(id, {}).duplicate(true)

static func id_for_node(node_name: String) -> String:
	_ensure_loaded()
	for id in _entries:
		if _entries[id].node_name == node_name: return id
	return ""

static func id_for_file(path: String) -> String:
	_ensure_loaded()
	for id in _entries:
		if _entries[id].get("profile_file", "") == path: return id
	return ""

static func load_profile(id: String, assigned_file: String = "") -> Dictionary:
	var entry := entry_for(id)
	if entry.is_empty():
		push_warning("Missing character profile: " + id)
		return {}
	var source := str(entry.get("profile_file", ""))
	if not assigned_file.is_empty() and assigned_file != source:
		push_warning("Mismatched profile assignment for " + id)
		return {}
	var profile := entry.duplicate(true)
	if not source.is_empty():
		if not FileAccess.file_exists(source):
			push_warning("Missing authored profile for " + id)
			return {}
		var parser := JSON.new()
		var parsed: Variant = parser.data if parser.parse(FileAccess.get_file_as_string(source)) == OK else null
		if not parsed is Dictionary or not _valid_authored_profile(parsed, id):
			push_warning("Invalid authored profile for " + id)
			return {}
		# Authored fields win over catalog enrichment, including lore and numeric traits.
		profile.merge(parsed, true)
	else:
		profile["personality"] = NEUTRAL_TRAITS.duplicate()
	return profile

static func safe_profile(id: String, display_name: String, occupation: String) -> Dictionary:
	return {"id": id, "name": display_name, "occupation": occupation,
		"personality": NEUTRAL_TRAITS.duplicate(), "identity_personality": "Reserved and practical.",
		"values": ["survival"], "goals": ["stay safe"], "fears": ["trouble"],
		"llm_summary": "Speak only as yourself; discuss your own work without inventing personal history.",
		"greeting": "Good day, traveler. What brings you here?"}
