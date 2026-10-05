@tool
class_name Wall
extends StaticBody2D

## Resizable 2D Wall with synchronized collision shape and visuals.

@export var size: Vector2 = Vector2(200, 32):
	set(value):
		size = Vector2(max(8.0, value.x), max(8.0, value.y))
		_update_wall()

@export var wall_color: Color = Color(0.22, 0.25, 0.3, 1.0):
	set(value):
		wall_color = value
		queue_redraw()

@export var border_color: Color = Color(0.4, 0.45, 0.52, 1.0):
	set(value):
		border_color = value
		queue_redraw()

@export var border_width: float = 2.0:
	set(value):
		border_width = max(0.0, value)
		queue_redraw()

var _collision_shape: CollisionShape2D


func _ready() -> void:
	add_to_group("walls")
	_setup_collision()
	_update_wall()


func _setup_collision() -> void:
	_collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _collision_shape == null:
		_collision_shape = CollisionShape2D.new()
		_collision_shape.name = "CollisionShape2D"
		add_child(_collision_shape)
		if Engine.is_editor_hint():
			_collision_shape.owner = get_tree().edited_scene_root

	if _collision_shape.shape == null or not (_collision_shape.shape is RectangleShape2D):
		_collision_shape.shape = RectangleShape2D.new()
	else:
		# Ensure unique shape resource per instance
		_collision_shape.shape = _collision_shape.shape.duplicate()


func _update_wall() -> void:
	if _collision_shape == null:
		_collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _collision_shape and _collision_shape.shape is RectangleShape2D:
		var rect_shape := _collision_shape.shape as RectangleShape2D
		rect_shape.size = size
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	# Main wall fill
	draw_rect(rect, wall_color, true)
	# Inner decorative line / brick edge for extra detail
	if size.y > 16.0 and size.x > 16.0:
		var inner_rect := Rect2(-size * 0.5 + Vector2(2, 2), size - Vector2(4, 4))
		draw_rect(inner_rect, Color(wall_color.r * 1.15, wall_color.g * 1.15, wall_color.b * 1.15, 0.4), false, 1.0)
	# Outline border
	if border_width > 0.0:
		draw_rect(rect, border_color, false, border_width)
