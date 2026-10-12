extends RefCounted
## Whitelisted mutable character state. Profiles and transient UI/network state stay out.
const MAX_INTEGER := 9007199254740991 # Exact JSON integer range.
const MAX_TEXT := 16384
const NPC_INTEGERS := ["trust", "suspicion", "gold", "max_daily_spend", "spent_today", "successful_scam_count", "failed_scam_count"]

static func valid_number(value: Variant, minimum: float, maximum: float, integral := false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum and (not integral or float(value) == floor(float(value)))

static func history(raw: Variant, npc_name: String) -> Array:
	# Match the existing NPC-owned representation; retain only completed own-speaker pairs.
	var result: Array = []
	var pending := ""
	if not raw is Array: return result
	for entry in raw:
		if not entry is String or entry.length() > MAX_TEXT:
			pending = ""
			continue
		var split: int = entry.find(": \"")
		if split < 0 or not entry.ends_with("\""):
			pending = ""
			continue
		var content: String = entry.substr(split + 3, entry.length() - split - 4)
		var speaker: String = entry.left(split)
		if content.strip_edges().is_empty() or content == "Thinking...":
			pending = ""
		elif speaker == "PLAYER":
			pending = entry
		elif speaker == npc_name and not pending.is_empty():
			result.append(pending)
			result.append(entry)
			pending = ""
		else:
			pending = ""
	return result.slice(-10) if result.size() > 10 else result

static func memories(raw: Variant) -> Array:
	var result: Array = []
	if not raw is Array: return result
	for entry in raw:
		if entry is String and not entry.is_empty() and entry.length() <= MAX_TEXT:
			result.append(entry) # Supported authored memory format.
		elif entry is Dictionary and entry.get("text") is String and not entry.text.is_empty() and entry.text.length() <= MAX_TEXT and valid_number(entry.get("timestamp"), 0, MAX_INTEGER):
			result.append({"text": entry.text, "timestamp": entry.timestamp})
	return result.slice(-8) if result.size() > 8 else result

static func validate(raw: Variant, id: String, kind: String, npc_name: String) -> Dictionary:
	if not raw is Dictionary or raw.get("character_id", id) != id or raw.get("kind", kind) != kind:
		return {}
	var result := {"character_id": id, "kind": kind}
	if kind == "guard":
		if raw.get("is_hostile") is bool: result.is_hostile = raw.is_hostile
		return result
	for field in NPC_INTEGERS:
		var maximum: int = 100 if field in ["trust", "suspicion"] else MAX_INTEGER
		if valid_number(raw.get(field), 0, maximum, true): result[field] = int(raw[field])
	if raw.get("is_refusing_to_talk") is bool and valid_number(raw.get("refusal_timer"), 0, MAX_INTEGER):
		result.is_refusing_to_talk = raw.is_refusing_to_talk and float(raw.refusal_timer) > 0.0
		result.refusal_timer = float(raw.refusal_timer) if result.is_refusing_to_talk else 0.0
	if raw.has("memories"): result.memories = memories(raw.memories)
	if raw.has("conversation_history"): result.conversation_history = history(raw.conversation_history, npc_name)
	return result

static func capture(character: Node, committed_history: Variant = null) -> Dictionary:
	var kind := "npc" if character is TownNPC else "guard"
	var result := {"character_id": character.character_id, "kind": kind}
	if kind == "guard":
		result.is_hostile = character.is_hostile
	else:
		for field in NPC_INTEGERS: result[field] = character.get(field)
		result.is_refusing_to_talk = character.is_refusing_to_talk
		result.refusal_timer = character.refusal_timer
		result.memories = character.memories
		result.conversation_history = character.conversation_history if committed_history == null else committed_history
	return validate(result, character.character_id, kind, character.npc_name if kind == "npc" else "")

static func apply(character: Node, state: Dictionary) -> void:
	for field in NPC_INTEGERS + ["is_refusing_to_talk", "refusal_timer", "is_hostile"]:
		if state.has(field): character.set(field, state[field])
	if character is TownNPC:
		# Keep existing array references used by ChatUI and the runtime profile.
		if state.has("memories"): character.memories.assign(state.memories.duplicate(true))
		if state.has("conversation_history"): character.conversation_history.assign(state.conversation_history.duplicate())
		character._sync_profile()

static func rollover(state: Dictionary) -> void:
	if state.get("kind") != "npc": return
	state.spent_today = 0
	if state.has("suspicion"): state.suspicion = clampi(int(state.suspicion) - 20, 0, 100)
	state.is_refusing_to_talk = false
	state.refusal_timer = 0.0
	state.conversation_history = []
