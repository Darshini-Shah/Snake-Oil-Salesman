extends CharacterBody2D

## Player movement script supporting Keyboard (WASD / Arrows), Gamepad, and On-Screen Joystick.
## Automatically suspends movement when typing or engaged in dialogue.

@export var speed: float = 300.0
@export var joystick: Control = null
@export var can_move: bool = true


func _ready() -> void:
	# Automatically connect to an OnScreenJoystick if present in the scene
	if joystick == null:
		var joysticks := get_tree().get_nodes_in_group("virtual_joystick")
		if joysticks.size() > 0:
			joystick = joysticks[0] as Control


func _physics_process(_delta: float) -> void:
	# 1. Do not move if a text input (LineEdit / TextEdit) currently has focus
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner is LineEdit or focus_owner is TextEdit:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# 2. Check global can_player_move flag
	var game_state = get_node_or_null("/root/GameState")
	if (game_state and not game_state.can_player_move) or not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Read vector from configured actions (W/A/S/D, Arrow keys, controller stick/D-pad)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# If on-screen joystick is actively producing analog input, prioritize direct 360-degree vector
	if joystick and joystick.has_method("is_active") and joystick.is_active():
		var joy_vec: Vector2 = joystick.get_output()
		if joy_vec.length_squared() > 0.0001:
			direction = joy_vec

	velocity = direction * speed
	move_and_slide()
