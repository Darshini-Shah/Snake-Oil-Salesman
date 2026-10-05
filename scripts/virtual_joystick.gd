@tool
class_name OnScreenJoystick
extends Control

## Virtual Joystick for mobile touchscreens and desktop mouse input.
## Can simulate InputMap actions (WASD/arrows) and/or provide direct analog vector output.

signal joystick_vector_changed(vector: Vector2)
signal joystick_released()

enum JoystickMode {
	FIXED,     ## Joystick stays at its fixed position
	DYNAMIC,   ## Joystick appears where the screen is touched
	FOLLOWING  ## Joystick appears on touch and follows the touch position when dragged beyond radius
}

@export_category("Joystick Settings")
## Joystick behavior mode
@export var joystick_mode: JoystickMode = JoystickMode.FIXED:
	set(value):
		joystick_mode = value
		queue_redraw()

## Maximum drag distance for the knob in pixels
@export var clamp_zone: float = 75.0:
	set(value):
		clamp_zone = max(10.0, value)
		queue_redraw()

## Distance (0.0 to 1.0) under which the joystick reports zero movement
@export_range(0.0, 0.5, 0.01) var deadzone: float = 0.05

## If true, automatically updates Godot InputMap actions
@export var use_input_actions: bool = true

@export_category("Input Actions")
@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_up: String = "move_up"
@export var action_down: String = "move_down"

@export_category("Visual Appearance")
## Radius of the outer base circle
@export var base_radius: float = 75.0:
	set(value):
		base_radius = max(10.0, value)
		queue_redraw()

## Radius of the inner draggable knob
@export var tip_radius: float = 30.0:
	set(value):
		tip_radius = max(5.0, value)
		queue_redraw()

## Outer base background fill color
@export var base_color: Color = Color(0.1, 0.12, 0.18, 0.5)

## Outer base border ring color
@export var base_border_color: Color = Color(0.85, 0.75, 0.5, 0.7)

## Base border width in pixels
@export var base_border_width: float = 3.0

## Draggable knob fill color
@export var tip_color: Color = Color(0.9, 0.7, 0.25, 0.8)

## Draggable knob border color
@export var tip_border_color: Color = Color(1.0, 0.95, 0.85, 0.95)

## Knob border width in pixels
@export var tip_border_width: float = 2.5

## Whether to draw a directional connecting line from center to knob
@export var show_direction_line: bool = true

## Optional custom texture for the base (replaces procedural drawing)
@export var base_texture: Texture2D = null:
	set(value):
		base_texture = value
		queue_redraw()

## Optional custom texture for the knob (replaces procedural drawing)
@export var tip_texture: Texture2D = null:
	set(value):
		tip_texture = value
		queue_redraw()

# Runtime state
var _touch_index: int = -1
var _is_active: bool = false
var _base_position: Vector2 = Vector2.ZERO
var _tip_position: Vector2 = Vector2.ZERO
var _output: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("virtual_joystick")
	mouse_filter = MOUSE_FILTER_STOP
	_reset_positions()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			if not _is_active:
				_reset_positions()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			reset()


func _reset_positions() -> void:
	_base_position = size * 0.5
	_tip_position = _base_position
	_output = Vector2.ZERO
	queue_redraw()


## Returns the current normalized analog direction vector (-1 to 1)
func get_output() -> Vector2:
	return _output


## Returns whether the joystick is currently being touched/dragged
func is_active() -> bool:
	return _is_active


## Reset the joystick to center and release any pressed actions
func reset() -> void:
	_touch_index = -1
	_is_active = false
	_output = Vector2.ZERO
	_tip_position = _base_position
	_release_all_actions()
	emit_signal("joystick_released")
	emit_signal("joystick_vector_changed", Vector2.ZERO)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	# Touch screen events
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and _can_start_touch(event.position):
				_start_touch(event.index, event.position)
				accept_event()
		elif event.index == _touch_index:
			_end_touch()
			accept_event()
	
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_touch(event.position)
			accept_event()

	# Desktop mouse fallback (in addition to emulate_touch_from_mouse)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _touch_index == -1 and _can_start_touch(event.position):
					_start_touch(-2, event.position)
					accept_event()
			elif _touch_index == -2:
				_end_touch()
				accept_event()
				
	elif event is InputEventMouseMotion:
		if _touch_index == -2:
			_update_touch(event.position)
			accept_event()


func _unhandled_input(event: InputEvent) -> void:
	# Safety check: if finger/mouse released outside the control rect
	if not _is_active:
		return
		
	if event is InputEventScreenTouch and not event.pressed:
		if event.index == _touch_index:
			_end_touch()
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and _touch_index == -2:
			_end_touch()


func _can_start_touch(pos: Vector2) -> bool:
	if joystick_mode == JoystickMode.FIXED:
		# In FIXED mode, allow touch if within base radius + extra leeway
		var dist: float = pos.distance_to(_base_position)
		return dist <= (base_radius * 1.5)
	return true


func _start_touch(index: int, pos: Vector2) -> void:
	_touch_index = index
	_is_active = true
	
	if joystick_mode == JoystickMode.DYNAMIC:
		_base_position = pos
		_tip_position = pos
	elif joystick_mode == JoystickMode.FOLLOWING:
		_base_position = pos
		_tip_position = pos
	
	_update_touch(pos)


func _update_touch(pos: Vector2) -> void:
	var offset: Vector2 = pos - _base_position
	var dist: float = offset.length()
	var dir: Vector2 = offset.normalized() if dist > 0.0001 else Vector2.ZERO
	
	if joystick_mode == JoystickMode.FOLLOWING and dist > clamp_zone:
		var extra_dist: float = dist - clamp_zone
		_base_position += dir * extra_dist
		dist = clamp_zone
	
	var clamped_dist: float = min(dist, clamp_zone)
	_tip_position = _base_position + dir * clamped_dist
	
	# Calculate normalized output with deadzone
	var normalized_dist: float = clamped_dist / clamp_zone
	if normalized_dist < deadzone:
		_output = Vector2.ZERO
	else:
		var scaled_magnitude: float = (normalized_dist - deadzone) / (1.0 - deadzone)
		_output = dir * clamp(scaled_magnitude, 0.0, 1.0)
	
	_update_input_actions(_output)
	emit_signal("joystick_vector_changed", _output)
	queue_redraw()


func _end_touch() -> void:
	reset()
	if joystick_mode == JoystickMode.DYNAMIC:
		_reset_positions()


func _update_input_actions(vec: Vector2) -> void:
	if not use_input_actions:
		return
	
	# Horizontal actions
	if vec.x > 0.0:
		_safe_action_press(action_right, vec.x)
		_safe_action_release(action_left)
	elif vec.x < 0.0:
		_safe_action_press(action_left, -vec.x)
		_safe_action_release(action_right)
	else:
		_safe_action_release(action_left)
		_safe_action_release(action_right)

	# Vertical actions
	if vec.y > 0.0:
		_safe_action_press(action_down, vec.y)
		_safe_action_release(action_up)
	elif vec.y < 0.0:
		_safe_action_press(action_up, -vec.y)
		_safe_action_release(action_down)
	else:
		_safe_action_release(action_up)
		_safe_action_release(action_down)


func _release_all_actions() -> void:
	if not use_input_actions:
		return
	_safe_action_release(action_left)
	_safe_action_release(action_right)
	_safe_action_release(action_up)
	_safe_action_release(action_down)


func _safe_action_press(action_name: String, strength: float) -> void:
	if action_name != "" and InputMap.has_action(action_name):
		Input.action_press(action_name, strength)


func _safe_action_release(action_name: String) -> void:
	if action_name != "" and InputMap.has_action(action_name):
		Input.action_release(action_name)


func _draw() -> void:
	var base_center := _base_position
	var tip_center := _tip_position
	
	if Engine.is_editor_hint() and not _is_active:
		base_center = size * 0.5
		tip_center = base_center
	
	# In dynamic mode, hide when not active if desired
	if joystick_mode == JoystickMode.DYNAMIC and not _is_active and not Engine.is_editor_hint():
		return

	# Draw direction connecting line
	if show_direction_line and base_center.distance_to(tip_center) > 2.0:
		var line_color := Color(tip_border_color.r, tip_border_color.g, tip_border_color.b, 0.4)
		draw_line(base_center, tip_center, line_color, 2.0, true)

	# Draw Base
	if base_texture != null:
		var rect := Rect2(base_center - Vector2(base_radius, base_radius), Vector2(base_radius * 2.0, base_radius * 2.0))
		draw_texture_rect(base_texture, rect, false)
	else:
		# Outer fill
		draw_circle(base_center, base_radius, base_color)
		# Outer border ring
		draw_arc(base_center, base_radius, 0.0, TAU, 48, base_border_color, base_border_width, true)
		# Subtle inner guide ring
		draw_arc(base_center, base_radius * 0.5, 0.0, TAU, 32, Color(base_border_color.r, base_border_color.g, base_border_color.b, 0.25), 1.5, true)
		# Crosshair / directional accent dots (N, E, S, W)
		var dot_radius := 2.5
		var dot_color := Color(base_border_color.r, base_border_color.g, base_border_color.b, 0.6)
		draw_circle(base_center + Vector2(0, -base_radius * 0.75), dot_radius, dot_color)
		draw_circle(base_center + Vector2(base_radius * 0.75, 0), dot_radius, dot_color)
		draw_circle(base_center + Vector2(0, base_radius * 0.75), dot_radius, dot_color)
		draw_circle(base_center + Vector2(-base_radius * 0.75, 0), dot_radius, dot_color)

	# Draw Knob (Tip)
	if tip_texture != null:
		var rect := Rect2(tip_center - Vector2(tip_radius, tip_radius), Vector2(tip_radius * 2.0, tip_radius * 2.0))
		draw_texture_rect(tip_texture, rect, false)
	else:
		# Knob fill
		draw_circle(tip_center, tip_radius, tip_color)
		# Knob border
		draw_arc(tip_center, tip_radius, 0.0, TAU, 36, tip_border_color, tip_border_width, true)
		# Knob center highlight pip
		draw_circle(tip_center, tip_radius * 0.25, Color(tip_border_color.r, tip_border_color.g, tip_border_color.b, 0.8))
