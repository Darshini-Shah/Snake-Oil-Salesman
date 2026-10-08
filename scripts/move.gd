extends CharacterBody2D

## Player movement script supporting Keyboard (WASD / Arrows), Gamepad, and On-Screen Joystick.
## Automatically suspends movement when typing or engaged in dialogue.

@export var speed: float = 300.0
@export var joystick: Control = null
@export var can_move: bool = true
@export var anim_fps: float = 8.0

var current_facing: String = "down" # "down", "left", "right", "up"
var _anim_timer: float = 0.0
var _walk_step: int = 0
var sprite: Sprite2D = null


func _get_sprite() -> Sprite2D:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	return sprite


func _ready() -> void:
	# Automatically connect to an OnScreenJoystick if present in the scene
	if joystick == null:
		var joysticks := get_tree().get_nodes_in_group("virtual_joystick")
		if joysticks.size() > 0:
			joystick = joysticks[0] as Control
	
	var s := _get_sprite()
	if s and s.hframes >= 3 and s.vframes >= 4:
		s.frame = 1 # Front-facing idle by default


func _physics_process(delta: float) -> void:
	# 1. Do not move if a text input (LineEdit / TextEdit) currently has focus
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner is LineEdit or focus_owner is TextEdit:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(delta, false)
		return
	
	# 2. Check global can_player_move flag
	var game_state = get_node_or_null("/root/GameState")
	if (game_state and not game_state.can_player_move) or not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(delta, false)
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
	
	var is_moving := velocity.length_squared() > 10.0
	_update_animation(delta, is_moving)


func _update_animation(delta: float, is_moving: bool) -> void:
	var s := _get_sprite()
	if s == null or s.hframes < 3 or s.vframes < 4:
		return
	
	if is_moving:
		# Determine dominant movement axis
		if abs(velocity.x) > abs(velocity.y):
			current_facing = "right" if velocity.x > 0.0 else "left"
		else:
			current_facing = "down" if velocity.y > 0.0 else "up"
		
		_anim_timer += delta * anim_fps
		if _anim_timer >= 1.0:
			_anim_timer -= 1.0
			_walk_step = (_walk_step + 1) % 4
		
		var row := 0
		match current_facing:
			"down": row = 0
			"left": row = 1
			"right": row = 2
			"up": row = 3
		
		var cycle := [0, 1, 2, 1]
		s.frame = row * 3 + cycle[_walk_step]
	else:
		_anim_timer = 0.0
		_walk_step = 0
		var row := 0
		match current_facing:
			"down": row = 0
			"left": row = 1
			"right": row = 2
			"up": row = 3
		s.frame = row * 3 + 1


func set_facing(direction: String) -> void:
	current_facing = direction
	var s := _get_sprite()
	if s and s.hframes >= 3 and s.vframes >= 4:
		var row := 0
		match current_facing:
			"down": row = 0
			"left": row = 1
			"right": row = 2
			"up": row = 3
		s.frame = row * 3 + 1
