class_name TownGuard
extends CharacterBody2D

## Reusable Guard / Authority NPC with detection radius and alert state.

signal player_detected(guard: TownGuard, player: Node2D)
signal player_lost(guard: TownGuard, player: Node2D)

@export var guard_name: String = "Gate Guard"
@export var is_hostile: bool = false
@export var challenge_message: String = "Halt! Keep clear of restricted premises!"

var is_alert: bool = false
var _alert_indicator: Label


func _ready() -> void:
	add_to_group("guards")
	add_to_group("enemies")
	_alert_indicator = get_node_or_null("AlertIndicator") as Label
	if _alert_indicator:
		_alert_indicator.visible = false


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_alert = true
		if _alert_indicator:
			_alert_indicator.visible = true
		print("[%s]: \"%s\"" % [guard_name, challenge_message])
		emit_signal("player_detected", self, body)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_alert = false
		if _alert_indicator:
			_alert_indicator.visible = false
		emit_signal("player_lost", self, body)
