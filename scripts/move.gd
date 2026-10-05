extends CharacterBody2D

## Player movement script supporting Keyboard (WASD / Arrows), Gamepad, and On-Screen Joystick.

@export var speed: float = 300.0
@export var joystick: Control = null


func _ready() -> void:
	# Automatically connect to an OnScreenJoystick if present in the scene
	if joystick == null:
		var joysticks := get_tree().get_nodes_in_group("virtual_joystick")
		if joysticks.size() > 0:
			joystick = joysticks[0] as Control


func _physics_process(_delta: float) -> void:
	# Read vector from configured actions (W/A/S/D, Arrow keys, controller stick/D-pad)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# If on-screen joystick is actively producing analog input, prioritize direct 360-degree vector
	if joystick and joystick.has_method("is_active") and joystick.is_active():
		var joy_vec: Vector2 = joystick.get_output()
		if joy_vec.length_squared() > 0.0001:
			direction = joy_vec

	velocity = direction * speed
	move_and_slide()
