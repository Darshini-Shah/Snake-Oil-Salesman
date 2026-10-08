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
var _target_player: Node2D = null
var current_facing: String = "down"


func _ready() -> void:
	add_to_group("guards")
	add_to_group("enemies")
	_alert_indicator = get_node_or_null("AlertIndicator") as Label
	if _alert_indicator:
		_alert_indicator.visible = false


func _process(_delta: float) -> void:
	if is_alert:
		if not is_instance_valid(_target_player):
			var players := get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				_target_player = players[0] as Node2D
		if is_instance_valid(_target_player):
			face_towards(_target_player.global_position)


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


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_alert = true
		_target_player = body
		face_towards(body.global_position)
		if _alert_indicator:
			_alert_indicator.visible = true
		print("[%s]: \"%s\"" % [guard_name, challenge_message])
		emit_signal("player_detected", self, body)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_alert = false
		_target_player = null
		set_facing("down")
		if _alert_indicator:
			_alert_indicator.visible = false
		emit_signal("player_lost", self, body)
