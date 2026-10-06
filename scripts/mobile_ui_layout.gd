extends Node
## Presentation only. Keyboard/safe-area pixels are converted into UI coordinates;
## neither the world viewport nor camera is moved. Layout changes only on events
## or changed metrics (Godot has no virtual-keyboard-height changed signal).
const EDGE := 12.0
const TOUCH_HEIGHT := 48.0

@onready var chat: ChatUI = $"../ChatUI"
@onready var hud: GameHUD = $"../HUD"
@onready var joystick: Control = $"../VirtualJoystick"
var mobile := false
# Optional platform adapter used by deterministic keyboard/safe-area tests.
var metrics_source: Callable
var _last_metrics: Array = []
var _refresh_pending := false

func _ready() -> void:
	mobile = OS.has_feature("android") or OS.has_feature("ios")
	chat.mobile_input = mobile
	chat.resized.connect(queue_refresh)
	chat.conversation_started.connect(_conversation_changed)
	chat.conversation_ended.connect(_conversation_changed)
	hud.get_node("TopPanel").resized.connect(queue_refresh)
	hud.toast_panel.resized.connect(queue_refresh)
	hud.toast_panel.visibility_changed.connect(queue_refresh)
	hud.layout_requested.connect(queue_refresh)
	chat.message_input.focus_entered.connect(queue_refresh)
	chat.message_input.focus_exited.connect(queue_refresh)
	if mobile:
		var timer := Timer.new()
		timer.wait_time = 0.1
		timer.timeout.connect(refresh)
		add_child(timer)
		timer.start()
	queue_refresh()

func _conversation_changed(_npc: Node2D) -> void:
	# A second finger can open dialogue while the first holds the joystick.
	# Release its actions before it is hidden, preventing stuck movement later.
	if chat.is_chatting and joystick.is_active():
		joystick.reset()
	queue_refresh()

func queue_refresh() -> void:
	_last_metrics.clear()
	if not _refresh_pending:
		_refresh_pending = true
		call_deferred("refresh")

static func unobscured_rect(ui_bounds: Rect2, screen_to_ui: Transform2D,
		screen_rect: Rect2, safe_pixels: Rect2, keyboard_height: float) -> Rect2:
	var safe := screen_to_ui * safe_pixels
	if not safe.has_area():
		safe = ui_bounds
	safe = safe.intersection(ui_bounds)
	if keyboard_height > 0.0:
		# Intersect with the keyboard's screen-space TOP, rather than subtracting
		# its height from the viewport. This also avoids double-insetting if the
		# operating system already resized the application surface.
		var keyboard_top := (screen_to_ui * Vector2(screen_rect.position.x,
			screen_rect.end.y - keyboard_height)).y
		safe.size.y = maxf(0.0, minf(safe.end.y, keyboard_top) - safe.position.y)
	return safe

func refresh() -> void:
	_refresh_pending = false
	var safe := Rect2(Vector2.ZERO, chat.size)
	var available := safe
	var keyboard_height := 0
	if metrics_source.is_valid():
		var supplied: Array = metrics_source.call()
		safe = supplied[0]
		available = supplied[1]
		keyboard_height = supplied[2]
	elif mobile:
		var screen := DisplayServer.window_get_current_screen()
		var origin := Vector2(DisplayServer.screen_get_position(screen))
		var screen_rect := Rect2(origin, Vector2(DisplayServer.screen_get_size(screen)))
		var safe_pixels := Rect2(DisplayServer.get_display_safe_area())
		safe_pixels.position += origin
		var transform := chat.get_screen_transform().affine_inverse()
		keyboard_height = DisplayServer.virtual_keyboard_get_height()
		safe = unobscured_rect(safe, transform, screen_rect, safe_pixels, 0)
		available = unobscured_rect(Rect2(Vector2.ZERO, chat.size), transform,
			screen_rect, safe_pixels, keyboard_height)
	var metrics := [mobile, safe, available, keyboard_height, chat.is_chatting,
		hud.get_node("TopPanel").size, hud.toast_panel.visible, hud.toast_panel.size]
	if metrics == _last_metrics:
		return
	_last_metrics = metrics
	apply_layout(mobile, safe, available, keyboard_height > 0)

func place(control: Control, rect: Rect2) -> void:
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		if control.get_anchor(side) != 0.0:
			control.set_anchor(side, 0.0)
	control.position = rect.position.round()
	control.size = rect.size.floor()

## Separate from device reads so desktop tests can exercise real mobile layouts.
func apply_layout(is_mobile: bool, safe: Rect2, available: Rect2, keyboard_open: bool) -> void:
	var panel: Control = hud.get_node("TopPanel")
	var toast := hud.toast_panel
	hud.visible = not (is_mobile and chat.is_chatting and keyboard_open)
	for control in [chat.message_input, chat.send_btn, chat.close_btn, chat.pitch_btn]:
		control.custom_minimum_size.y = TOUCH_HEIGHT if is_mobile else 0.0
	chat.chat_prompt_btn.custom_minimum_size.y = TOUCH_HEIGHT if is_mobile else 0.0
	var inner := safe.grow(-EDGE)
	if is_mobile:
		# Keep original joystick geometry, adding only physical safe-area insets.
		joystick.offset_left = safe.position.x + 30.0
		joystick.offset_right = safe.position.x + 160.0
		joystick.offset_top = -(chat.size.y - safe.end.y) - 150.0
		joystick.offset_bottom = -(chat.size.y - safe.end.y) - 20.0
		var hud_y := inner.end.y - panel.size.y if chat.is_chatting else inner.position.y
		place(panel, Rect2(Vector2(inner.position.x, hud_y), Vector2(inner.size.x, panel.size.y)))
		var bottom := available.end.y - EDGE
		if chat.is_chatting and not keyboard_open:
			bottom = minf(bottom, panel.position.y - EDGE)
			if toast.visible:
				bottom -= toast.size.y + EDGE
		place(chat.chat_window, Rect2(inner.position,
			Vector2(inner.size.x, maxf(0.0, bottom - inner.position.y))))
		var prompt_width := minf(320.0, inner.size.x - 170.0)
		place(chat.chat_prompt_btn, Rect2(Vector2(inner.end.x - prompt_width,
			inner.end.y - TOUCH_HEIGHT - 16.0), Vector2(prompt_width, TOUCH_HEIGHT)))
		var toast_y := panel.position.y - toast.size.y - EDGE if chat.is_chatting else panel.get_rect().end.y + EDGE
		place(toast, Rect2(Vector2(inner.position.x, toast_y), Vector2(inner.size.x, toast.size.y)))
	else:
		place(panel, Rect2(Vector2(8, 8), Vector2(chat.size.x - 16, panel.size.y)))
		place(chat.chat_window, Rect2(Vector2(12, chat.size.y * 0.46),
			Vector2(chat.size.x - 24, chat.size.y * 0.54 - 12)))
		place(toast, Rect2(Vector2(12, panel.get_rect().end.y + 8), Vector2(chat.size.x - 24, toast.size.y)))
