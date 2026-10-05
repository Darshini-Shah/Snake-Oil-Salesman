class_name TownNPC
extends CharacterBody2D

## Townsperson NPC with persistent personality data, interaction trigger, and speech bubble.

signal player_entered_interaction(npc: TownNPC)
signal player_exited_interaction(npc: TownNPC)

@export var npc_name: String = "Barnaby"
@export var npc_title: String = "Curious Town Merchant"
@export var npc_data_file: String = "res://data/examples/barnaby_merchant.json"

# Dynamic social stats (Godot authoritative)
@export var trust: int = 50
@export var suspicion: int = 10

var npc_profile: Dictionary = {}
var is_player_in_range: bool = false

var _prompt_label: Label
var _speech_bubble: PanelContainer
var _speech_text: Label
var _speech_speaker: Label


func _ready() -> void:
	add_to_group("npcs")
	_load_npc_data()
	
	_prompt_label = get_node_or_null("PromptLabel") as Label
	if _prompt_label:
		_prompt_label.visible = false
		
	_speech_bubble = get_node_or_null("SpeechBubble") as PanelContainer
	if _speech_bubble:
		_speech_text = _speech_bubble.get_node_or_null("%SpeechText") as Label
		_speech_speaker = _speech_bubble.get_node_or_null("%SpeakerName") as Label
		_speech_bubble.visible = false


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
	
	if npc_profile.is_empty():
		# Fallback profile
		npc_profile = {
			"name": npc_name,
			"occupation": npc_title,
			"personality": {"trusting": 0.55, "skeptical": 0.45, "greedy": 0.6},
			"values": ["profit", "curiosity"],
			"goals": ["expand booth"],
			"fears": ["guards"]
		}
	
	npc_profile["trust"] = trust
	npc_profile["suspicion"] = suspicion


func get_full_profile() -> Dictionary:
	npc_profile["trust"] = trust
	npc_profile["suspicion"] = suspicion
	return npc_profile


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


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_range = true
		if _prompt_label:
			_prompt_label.visible = true
		emit_signal("player_entered_interaction", self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_range = false
		if _prompt_label:
			_prompt_label.visible = false
		hide_speech()
		emit_signal("player_exited_interaction", self)
