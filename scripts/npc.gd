class_name TownNPC
extends CharacterBody2D

## Reusable NPC for townspeople with physical collision and an interaction trigger zone.

signal player_entered_interaction(npc: TownNPC)
signal player_exited_interaction(npc: TownNPC)

@export var npc_name: String = "Townsperson"
@export var npc_title: String = "Local Resident"

var is_player_in_range: bool = false
var _prompt_label: Label


func _ready() -> void:
	add_to_group("npcs")
	_prompt_label = get_node_or_null("PromptLabel") as Label
	if _prompt_label:
		_prompt_label.visible = false
		_prompt_label.text = "[Talk: %s]" % npc_name


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_range = true
		if _prompt_label:
			_prompt_label.visible = true
		print("[NPC %s] Player came in range to talk!" % npc_name)
		emit_signal("player_entered_interaction", self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_range = false
		if _prompt_label:
			_prompt_label.visible = false
		emit_signal("player_exited_interaction", self)
