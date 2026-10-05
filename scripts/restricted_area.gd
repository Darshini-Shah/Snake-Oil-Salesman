@tool
class_name RestrictedArea
extends StaticBody2D

## Restricted zone that physically blocks player entry and triggers trespass warnings.

signal player_approached(body: Node2D)
signal player_retreated(body: Node2D)

@export var area_name: String = "Restricted Area":
	set(value):
		area_name = value
		queue_redraw()

@export var size: Vector2 = Vector2(240, 160):
	set(value):
		size = Vector2(max(32.0, value.x), max(32.0, value.y))
		_update_dimensions()

## If true, physically prevents the player from passing through
@export var blocks_player: bool = true:
	set(value):
		blocks_player = value
		_update_collision_state()

@export var zone_color: Color = Color(0.8, 0.18, 0.15, 0.22):
	set(value):
		zone_color = value
		queue_redraw()

@export var border_color: Color = Color(0.95, 0.7, 0.15, 0.85):
	set(value):
		border_color = value
		queue_redraw()

@export var border_width: float = 3.0:
	set(value):
		border_width = max(1.0, value)
		queue_redraw()

@export var show_hazard_stripes: bool = true:
	set(value):
		show_hazard_stripes = value
		queue_redraw()

@export var warning_message: String = "RESTRICTED: Trespassing will increase town suspicion!"

var _collision_shape: CollisionShape2D
var _detector_area: Area2D
var _detector_shape: CollisionShape2D


func _ready() -> void:
	add_to_group("restricted_areas")
	_setup_nodes()
	_update_dimensions()
	_update_collision_state()


func _setup_nodes() -> void:
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
		_collision_shape.shape = _collision_shape.shape.duplicate()

	# Detector Area
	_detector_area = get_node_or_null("SensorArea") as Area2D
	if _detector_area == null:
		_detector_area = Area2D.new()
		_detector_area.name = "SensorArea"
		add_child(_detector_area)
		if Engine.is_editor_hint():
			_detector_area.owner = get_tree().edited_scene_root

		_detector_shape = CollisionShape2D.new()
		_detector_shape.name = "CollisionShape2D"
		_detector_shape.shape = RectangleShape2D.new()
		_detector_area.add_child(_detector_shape)
		if Engine.is_editor_hint():
			_detector_shape.owner = get_tree().edited_scene_root
	else:
		_detector_shape = _detector_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if _detector_shape and _detector_shape.shape:
			_detector_shape.shape = _detector_shape.shape.duplicate()

	if not Engine.is_editor_hint() and _detector_area:
		if not _detector_area.is_connected("body_entered", Callable(self, "_on_sensor_body_entered")):
			_detector_area.connect("body_entered", Callable(self, "_on_sensor_body_entered"))
		if not _detector_area.is_connected("body_exited", Callable(self, "_on_sensor_body_exited")):
			_detector_area.connect("body_exited", Callable(self, "_on_sensor_body_exited"))


func _update_collision_state() -> void:
	if _collision_shape:
		_collision_shape.disabled = not blocks_player


func _update_dimensions() -> void:
	if _collision_shape and _collision_shape.shape is RectangleShape2D:
		(_collision_shape.shape as RectangleShape2D).size = size
	if _detector_shape and _detector_shape.shape is RectangleShape2D:
		# Sensor is slightly larger by 16px to detect approach
		(_detector_shape.shape as RectangleShape2D).size = size + Vector2(16.0, 16.0)
	queue_redraw()


func _on_sensor_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		print("[%s] %s" % [area_name, warning_message])
		emit_signal("player_approached", body)


func _on_sensor_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		emit_signal("player_retreated", body)


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	# Semi-transparent red/tint fill
	draw_rect(rect, zone_color, true)

	# Diagonal warning stripes
	if show_hazard_stripes:
		var stripe_color := Color(border_color.r, border_color.g, border_color.b, 0.25)
		var stripe_step: float = 24.0
		var half_w := size.x * 0.5
		var half_h := size.y * 0.5
		var total_span := size.x + size.y
		var current := -half_w - half_h
		while current < total_span:
			var p1 := Vector2(current, -half_h)
			var p2 := Vector2(current + 20.0, half_h)
			# Clamp stripe lines within the rect
			p1.x = clamp(p1.x, -half_w, half_w)
			p2.x = clamp(p2.x, -half_w, half_w)
			if p1.distance_squared_to(p2) > 4.0:
				draw_line(p1, p2, stripe_color, 2.0)
			current += stripe_step

	# Perimeter border
	if border_width > 0.0:
		draw_rect(rect, border_color, false, border_width)

	# Corner accent brackets
	var bracket_len: float = min(20.0, min(size.x, size.y) * 0.2)
	var tl := -size * 0.5
	var tr := Vector2(size.x * 0.5, -size.y * 0.5)
	var bl := Vector2(-size.x * 0.5, size.y * 0.5)
	var br := size * 0.5
	var accent_col := Color(border_color.r, border_color.g, border_color.b, 1.0)
	var accent_w := border_width + 1.5

	# Top-left corner
	draw_line(tl, tl + Vector2(bracket_len, 0), accent_col, accent_w)
	draw_line(tl, tl + Vector2(0, bracket_len), accent_col, accent_w)
	# Top-right corner
	draw_line(tr, tr - Vector2(bracket_len, 0), accent_col, accent_w)
	draw_line(tr, tr + Vector2(0, bracket_len), accent_col, accent_w)
	# Bottom-left corner
	draw_line(bl, bl + Vector2(bracket_len, 0), accent_col, accent_w)
	draw_line(bl, bl - Vector2(0, bracket_len), accent_col, accent_w)
	# Bottom-right corner
	draw_line(br, br - Vector2(bracket_len, 0), accent_col, accent_w)
	draw_line(br, br - Vector2(0, bracket_len), accent_col, accent_w)
