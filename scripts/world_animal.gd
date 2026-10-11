class_name WorldAnimal
extends CharacterBody2D

## Reusable, lightweight animated animal controller for Island world critters & livestock.
## Supports Cows, Sheep, Pigs, Chickens, Cats, and Birds with idle animations, grazing,
## gentle wandering, and player proximity reactions.

@export var animal_type: String = "cow" # "cow", "sheep", "pig", "chicken", "cat", "bird"
@export var behavior: String = "idle" # "idle", "graze", "sleep", "wander", "peck"
@export var wander_radius: float = 28.0
@export var move_speed: float = 25.0
@export var react_to_player: bool = true

var home_position: Vector2
var target_wander_pos: Vector2
var wander_timer: float = 0.0
var anim_timer: float = 0.0
var current_anim_frame: int = 0
var total_frames: int = 4
var is_fleeing: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = get_node_or_null("DetectionArea")


func _ready() -> void:
	home_position = position
	target_wander_pos = position
	wander_timer = randf_range(1.5, 4.0)
	
	if sprite:
		total_frames = sprite.hframes * sprite.vframes
		current_anim_frame = randi() % maxi(1, total_frames)
		sprite.frame = current_anim_frame


func _physics_process(delta: float) -> void:
	# 1. Animation Frame Cycling
	anim_timer += delta
	var frame_interval: float = 0.4 if (velocity.length() < 1.0) else 0.2
	if animal_type == "bird":
		frame_interval = 0.2
	elif animal_type == "cat" and behavior == "sleep":
		frame_interval = 0.8

	if anim_timer >= frame_interval:
		anim_timer = 0.0
		if total_frames > 1:
			current_anim_frame = (current_anim_frame + 1) % total_frames
			if sprite:
				sprite.frame = current_anim_frame

	# 2. Sleeping animals remain resting
	if behavior == "sleep":
		velocity = Vector2.ZERO
		return

	# 3. Wander State Logic
	wander_timer -= delta
	if wander_timer <= 0.0:
		if is_fleeing:
			is_fleeing = false
			wander_timer = randf_range(3.0, 6.0)
			target_wander_pos = home_position + Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		else:
			wander_timer = randf_range(2.5, 5.5)
			if randf() < 0.5 and wander_radius > 0:
				# Pick a gentle wander target within home radius
				var offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
				target_wander_pos = home_position + offset
			else:
				# Pause to graze / idle / peck
				target_wander_pos = position

	# 4. Movement execution
	var to_target := target_wander_pos - position
	if to_target.length() > 4.0:
		var speed: float = move_speed * (1.6 if is_fleeing else 1.0)
		velocity = to_target.normalized() * speed
		if sprite:
			sprite.flip_h = velocity.x < -1.0
		move_and_slide()
	else:
		velocity = Vector2.ZERO


func _on_detection_area_body_entered(body: Node2D) -> void:
	if not react_to_player or not body.is_in_group("player"):
		return

	if animal_type in ["chicken", "bird"]:
		# Scatter away from player
		var flee_dir := (global_position - body.global_position).normalized()
		target_wander_pos = home_position + flee_dir * wander_radius
		is_fleeing = true
		wander_timer = 1.8
	elif animal_type == "cat":
		# Turn toward player
		if sprite:
			sprite.flip_h = body.global_position.x < global_position.x
	elif animal_type in ["cow", "sheep", "pig"]:
		if sprite:
			sprite.flip_h = body.global_position.x < global_position.x
