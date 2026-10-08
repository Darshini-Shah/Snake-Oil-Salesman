class_name TownNPC
extends CharacterBody2D

## Townsperson NPC with dynamic social state, economy tracking, memory, and refusal mechanics.
## Adheres strictly to AGENTS.md: Godot systems are authoritative.

signal player_entered_interaction(npc: TownNPC)
signal player_exited_interaction(npc: TownNPC)
signal social_state_changed(npc: TownNPC)

@export var character_texture: Texture2D
@export var npc_name: String = "Barnaby"
@export var npc_title: String = "Curious Town Merchant"
@export var npc_data_file: String = "res://data/npcs/barnaby_merchant.json"
@export var npc_color: Color = Color(0.2, 0.7, 0.35, 1.0)

# Dynamic authoritative social stats
@export var trust: int = 50
@export var suspicion: int = 10
@export var gold: int = 1200
@export var max_daily_spend: int = 350
@export var spent_today: int = 0
@export var successful_scam_count: int = 0
@export var failed_scam_count: int = 0

# Refusal / Lock-out state
var is_refusing_to_talk: bool = false
var refusal_timer: float = 0.0

var npc_profile: Dictionary = {}
var is_player_in_range: bool = false
var _target_player: Node2D = null
var current_facing: String = "down"

var memories: Array = []
var conversation_history: Array = []
var susceptible_topics: Array = []
var skeptical_topics: Array = []

var _color_rect: ColorRect
var _prompt_label: Label
var _speech_bubble: PanelContainer
var _speech_text: Label
var _speech_speaker: Label
var _status_indicator: Label


func _ready() -> void:
	add_to_group("npcs")
	
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		if character_texture:
			sprite.texture = character_texture
		if sprite.hframes >= 3 and sprite.vframes >= 4:
			sprite.frame = 1 # Front-facing idle
	
	_color_rect = get_node_or_null("ColorRect") as ColorRect
	if _color_rect:
		_color_rect.color = npc_color
		
	_prompt_label = get_node_or_null("PromptLabel") as Label
	if _prompt_label:
		_prompt_label.visible = false
		
	_speech_bubble = get_node_or_null("SpeechBubble") as PanelContainer
	if _speech_bubble:
		_speech_text = _speech_bubble.get_node_or_null("%SpeechText") as Label
		_speech_speaker = _speech_bubble.get_node_or_null("%SpeakerName") as Label
		_speech_bubble.visible = false
	
	_load_npc_data()


func _process(delta: float) -> void:
	if is_player_in_range:
		if not is_instance_valid(_target_player):
			var players := get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				_target_player = players[0] as Node2D
		if is_instance_valid(_target_player):
			face_towards(_target_player.global_position)

	if is_refusing_to_talk:
		refusal_timer -= delta
		if refusal_timer <= 0.0:
			clear_refusal()
		elif is_player_in_range and _prompt_label:
			_prompt_label.text = "🚫 [%s refuses to talk: %ds]" % [npc_name, int(ceil(refusal_timer))]
			_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))


func _load_npc_data() -> void:
	if not npc_data_file.is_empty() and FileAccess.file_exists(npc_data_file):
		var file := FileAccess.open(npc_data_file, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			var parsed = JSON.parse_string(json_text)
			if parsed is Dictionary:
				npc_profile = parsed
				npc_name = str(npc_profile.get("name", npc_name))
				npc_title = str(npc_profile.get("occupation", npc_title))
				gold = int(npc_profile.get("gold", gold))
				max_daily_spend = int(npc_profile.get("max_daily_spend", max_daily_spend))
				spent_today = int(npc_profile.get("spent_today", spent_today))
				trust = int(npc_profile.get("trust", trust))
				suspicion = int(npc_profile.get("suspicion", suspicion))
				susceptible_topics = npc_profile.get("susceptible_topics", [])
				skeptical_topics = npc_profile.get("skeptical_topics", [])
				memories = npc_profile.get("memories", [])
	
	if npc_profile.is_empty():
		npc_profile = {
			"name": npc_name,
			"occupation": npc_title,
			"personality": {"trusting": 0.5, "skeptical": 0.5, "empathetic": 0.5, "greedy": 0.5},
			"values": ["survival"],
			"goals": ["stay safe"],
			"fears": ["trouble"]
		}
	
	_sync_profile()


func _sync_profile() -> void:
	npc_profile["name"] = npc_name
	npc_profile["occupation"] = npc_title
	npc_profile["trust"] = trust
	npc_profile["suspicion"] = suspicion
	npc_profile["gold"] = gold
	npc_profile["max_daily_spend"] = max_daily_spend
	npc_profile["spent_today"] = spent_today
	npc_profile["successful_scam_count"] = successful_scam_count
	npc_profile["failed_scam_count"] = failed_scam_count
	npc_profile["susceptible_topics"] = susceptible_topics
	npc_profile["skeptical_topics"] = skeptical_topics
	npc_profile["memories"] = memories
	npc_profile["conversation_history"] = conversation_history
	npc_profile["is_refusing_to_talk"] = is_refusing_to_talk


func get_full_profile() -> Dictionary:
	_sync_profile()
	return npc_profile


func get_conversation_history() -> Array:
	return conversation_history


func add_conversation_turn(speaker: String, text: String) -> void:
	conversation_history.append("%s: \"%s\"" % [speaker, text])
	if conversation_history.size() > 10:
		conversation_history.pop_front()
	_sync_profile()


func clear_conversation_history() -> void:
	conversation_history.clear()
	_sync_profile()


func trigger_refusal(duration_seconds: float = 35.0) -> void:
	is_refusing_to_talk = true
	refusal_timer = duration_seconds
	show_speech("Get away from me, swindler! I'm not speaking another word to you!", npc_name)
	if _prompt_label:
		_prompt_label.text = "🚫 [%s refuses to talk: %ds]" % [npc_name, int(ceil(refusal_timer))]
		_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	add_memory("Refused to speak with player due to high suspicion.")
	emit_signal("social_state_changed", self)


func clear_refusal() -> void:
	is_refusing_to_talk = false
	refusal_timer = 0.0
	suspicion = clampi(suspicion - 15, 0, 100)
	if _prompt_label:
		_prompt_label.text = "[In Range]"
		_prompt_label.remove_theme_color_override("font_color")
	emit_signal("social_state_changed", self)


func add_memory(event_text: String) -> void:
	var memory_entry := {
		"text": event_text,
		"timestamp": Time.get_unix_time_from_system()
	}
	memories.append(memory_entry)
	if memories.size() > 8:
		memories.pop_front() # Keep compact memory per AGENTS.md Rule 3


func on_day_rollover(_new_day: int) -> void:
	# Reset daily spend
	spent_today = 0
	# Cool down suspicion with time
	suspicion = clampi(suspicion - 20, 0, 100)
	is_refusing_to_talk = false
	refusal_timer = 0.0
	clear_conversation_history()
	if _prompt_label:
		_prompt_label.text = "[In Range]"
		_prompt_label.remove_theme_color_override("font_color")
	_sync_profile()
	emit_signal("social_state_changed", self)


func show_speech(text: String, speaker: String = "") -> void:
	if _speech_bubble:
		if _speech_speaker:
			_speech_speaker.text = speaker if not speaker.is_empty() else npc_name
		if _speech_text:
			_speech_text.text = text
		_speech_bubble.visible = true


func show_thinking() -> void:
	show_speech("Thinking...", npc_name)


func hide_speech() -> void:
	if _speech_bubble:
		_speech_bubble.visible = false


func set_facing(dir: String) -> void:
	current_facing = dir
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.hframes >= 3 and sprite.vframes >= 4:
		var row := 0
		match dir:
			"down": row = 0
			"left": row = 1
			"right": row = 2
			"up": row = 3
		var target_frame := row * 3 + 1
		if sprite.frame != target_frame:
			sprite.frame = target_frame


func face_towards(target_pos: Vector2) -> void:
	var diff := target_pos - global_position
	if diff.length_squared() < 0.1:
		return
	if abs(diff.x) > abs(diff.y):
		set_facing("right" if diff.x > 0.0 else "left")
	else:
		set_facing("down" if diff.y > 0.0 else "up")


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_range = true
		_target_player = body
		face_towards(body.global_position)
		if _prompt_label:
			if is_refusing_to_talk:
				_prompt_label.text = "🚫 [%s refuses to talk: %ds]" % [npc_name, int(ceil(refusal_timer))]
				_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			else:
				_prompt_label.text = "[In Range]"
				_prompt_label.remove_theme_color_override("font_color")
			_prompt_label.visible = true
		emit_signal("player_entered_interaction", self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_range = false
		_target_player = null
		set_facing("down")
		if _prompt_label:
			_prompt_label.visible = false
		hide_speech()
		emit_signal("player_exited_interaction", self)
