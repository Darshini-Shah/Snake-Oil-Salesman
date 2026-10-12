extends SceneTree
## Rendered title menu and native Godot GUI event tests. Isolated saves only.
## Use -- --capture with a real renderer; headless mode covers asset/layout checks.
var checks := 0
var failures := 0
var deadline := 0
var title: Control
var state: GameStateManager
var capturing := false
const BUTTONS := ["StartBtn", "ContinueBtn", "SettingsBtn", "QuitBtn"]
const ASSETS := ["start", "continue", "settings", "quit"]
const LAYOUTS := [
	{"size": Vector2i(1152, 648), "x": 294.912, "y": [289.656, 339.656, 389.656, 439.656], "width": 175.0, "height": [40.0, 40.0, 40.0, 40.0]},
	{"size": Vector2i(1280, 720), "x": 327.680, "y": [321.840, 376.840, 431.840, 486.840], "width": 194.0, "height": [45.0, 45.0, 45.0, 45.0]},
	{"size": Vector2i(1920, 1080), "x": 491.520, "y": [482.760, 563.760, 645.760, 726.760], "width": 291.0, "height": [71.0, 72.0, 71.0, 72.0]},
	{"size": Vector2i(1600, 720), "x": 409.600, "y": [321.840, 376.840, 431.840, 486.840], "width": 243.0, "height": [45.0, 45.0, 45.0, 45.0]}
]

func _init() -> void:
	call_deferred("run")

func _process(_delta: float) -> bool:
	if deadline > 0 and Time.get_ticks_msec() > deadline:
		push_error("Title button suite watchdog expired")
		quit(1)
	return false

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func settle() -> void:
	for i in range(6): await process_frame

func open_title() -> void:
	if is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null
		await settle()
	title = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	await settle()

func capture(label: String) -> void:
	if capturing:
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://.godot/title_buttons_review/" + label + ".png") == OK, "Capture " + label)

func move_mouse(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	root.push_input(event, true)
	await settle()

func mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	root.push_input(event, true)
	await settle()

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	await move_mouse(point)
	await mouse_button(point, true)
	await mouse_button(point, false)

func key(keycode: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		root.push_input(event, true)
	await settle()

func joy_button(button: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func touch(control: Control) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = control.get_global_rect().get_center()
		event.pressed = pressed
		root.push_input(event, true)
	await settle()

func check_world(description: String) -> void:
	await settle()
	check(is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/main.tscn", description + " loads main scene")
	if is_instance_valid(current_scene):
		check(current_scene.has_node("Ground/IslandMap") and current_scene.get_node("Characters").get_child_count() == 55, description + " loads existing village")

func run() -> void:
	if ProjectSettings.get_setting("application/config/name") != "Snake Oil Salesman Integration Tests":
		push_error("Use tests/run_isolated.ps1 or the isolated test project; refusing real save fixtures")
		quit(1)
		return
	deadline = Time.get_ticks_msec() + 60000
	capturing = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://.godot/title_buttons_review")
	state = root.get_node("GameState")
	DirAccess.remove_absolute("user://save_game.dat")
	await open_title()
	check(title.continue_btn.disabled and title.continue_btn.self_modulate.r < 0.5, "No save visibly disables Continue")
	check(title.start_btn.has_focus(), "No save initially focuses Start")
	for layout in LAYOUTS:
		root.size = layout.size
		root.content_scale_size = layout.size
		if capturing: DisplayServer.window_set_size(layout.size)
		await settle()
		var texture_size := Vector2i.ZERO
		for i in range(4):
			var button: TextureButton = title.get_node("Buttons/" + BUTTONS[i])
			check(button.texture_normal.resource_path == "res://assets/ui/title_buttons/%s.png" % ASSETS[i], BUTTONS[i] + " correct texture")
			check(button.texture_normal.get_size() == Vector2(1611, 430), BUTTONS[i] + " shared final canvas")
			check(button.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and button.stretch_mode == TextureButton.STRETCH_KEEP_ASPECT_CENTERED, BUTTONS[i] + " crisp proportional rendering")
			check(button.mouse_default_cursor_shape == Control.CURSOR_ARROW and button.focus_mode == Control.FOCUS_ALL, BUTTONS[i] + " arrow cursor and keyboard focus")
			check(button.global_position.distance_to(Vector2(layout.x, layout.y[i])) < 0.01 and button.size == Vector2(layout.width, layout.height[i]), BUTTONS[i] + " exact original slot at " + str(layout.size))
			check(button.texture_click_mask != null and not button.texture_click_mask.get_bit(0, 0) and button.texture_click_mask.get_bit(805, 215), BUTTONS[i] + " transparent boundary click mask")
			var image := button.texture_normal.get_image()
			check(image.get_pixel(0,0).a < 0.01 and image.get_pixel(805,215).a > 0.9, BUTTONS[i] + " real image transparency")
			texture_size = Vector2i(image.get_size())
		check(texture_size == Vector2i(1611,430), "Identical asset dimensions")
		await capture("menu_%dx%d_disabled" % [layout.size.x,layout.size.y])
	# Native GUI routing below requires a renderer to compute TextureButton's draw rect.
	if not capturing:
		print("Title buttons: %d checks, %d failures (headless asset/layout checks; input and screenshots require --capture)" % [checks,failures])
		quit(0 if failures == 0 else 1)
		return
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	await settle()
	await click(title.continue_btn)
	check(current_scene == title, "Disabled Continue mouse click cannot load game")
	# Transparent letterbox and corner are not part of the visible hitbox.
	await move_mouse(title.settings_btn.global_position + Vector2(1, 20))
	check(not title.settings_btn.is_hovered(), "Transparent side margin rejects hover")
	await mouse_button(title.settings_btn.global_position + Vector2(1,20), true)
	await mouse_button(title.settings_btn.global_position + Vector2(1,20), false)
	check(not title.settings_panel.visible, "Transparent margin cannot trigger Settings")
	var scale: float = minf(title.settings_btn.size.x / 1611.0, title.settings_btn.size.y / 430.0)
	var texture_origin: Vector2 = title.settings_btn.global_position + (title.settings_btn.size - Vector2(1611,430) * scale) / 2.0
	await move_mouse(texture_origin + Vector2(2,2) * scale)
	check(not title.settings_btn.is_hovered(), "Transparent notched corner rejects hover")
	await move_mouse(title.settings_btn.get_global_rect().get_center())
	check(title.settings_btn.is_hovered() and title.settings_btn.has_focus() and title.settings_btn.self_modulate.r > 1.0, "Mouse hover visibly highlights and focuses Settings")
	await capture("settings_hover")
	await mouse_button(title.settings_btn.get_global_rect().get_center(), true)
	check(title.settings_btn.self_modulate.r < 1.0, "Held mouse press provides subtle feedback")
	await capture("settings_pressed")
	await mouse_button(title.settings_btn.get_global_rect().get_center(), false)
	check(title.settings_panel.visible, "Mouse click opens existing Settings")
	await capture("settings_open")
	await click(title.get_node("SettingsPanel/VBox/CloseSettingsBtn"))
	check(not title.settings_panel.visible, "Mouse click closes existing Settings")
	await move_mouse(Vector2(1100,50))
	title.start_btn.grab_focus()
	await key(KEY_TAB)
	check(title.continue_btn.has_focus(), "Tab preserves original button focus order")
	await key(KEY_ENTER)
	check(current_scene == title, "Keyboard cannot activate disabled Continue")
	await key(KEY_TAB)
	check(title.settings_btn.has_focus(), "Next Tab reaches Settings")
	await key(KEY_ENTER)
	check(title.settings_panel.visible, "Keyboard Enter activates Settings")
	await click(title.get_node("SettingsPanel/VBox/CloseSettingsBtn"))
	title.start_btn.grab_focus()
	await joy_button(JOY_BUTTON_DPAD_DOWN)
	check(title.continue_btn.has_focus(), "Controller preserves original focus order")
	await joy_button(JOY_BUTTON_DPAD_DOWN)
	check(title.settings_btn.has_focus(), "Controller D-pad reaches Settings")
	# This project's existing ui_accept has keyboard bindings only. Preserve that
	# mapping; controller coverage checks the already-supported D-pad focus behavior.
	print("Controller D-pad focus verified; face-button activation is not mapped by existing ui_accept.")
	await touch(title.settings_btn)
	check(title.settings_panel.visible, "Synthetic landscape touch opens Settings")
	await touch(title.get_node("SettingsPanel/VBox/CloseSettingsBtn"))
	check(not title.settings_panel.visible, "Synthetic touch closes Settings")
	await click(title.start_btn)
	await check_world("No-save mouse Start")
	check(state.player_kurtos == 50 and state.current_day == 1, "No-save Start preserves existing new-game values")
	await capture("village_after_start")
	state.player_kurtos = 777
	state.current_day = 12
	state.overall_trust = 67
	state.save_game()
	await open_title()
	check(not title.continue_btn.disabled and title.continue_btn.has_focus() and title.continue_btn.self_modulate.r > 1.0, "Valid save enables and focuses Continue")
	await capture("menu_valid_save")
	await click(title.start_btn)
	check(title.confirm_panel.visible and state.player_kurtos == 777, "Mouse Start with save preserves existing confirmation")
	await click(title.get_node("ConfirmPanel/VBox/HBox/NoBtn"))
	check(not title.confirm_panel.visible and state.player_kurtos == 777, "Mouse Cancel preserves progress")
	await click(title.continue_btn)
	await check_world("Mouse Continue")
	check(state.player_kurtos == 777 and state.current_day == 12 and state.overall_trust == 67, "Continue restores existing currency, day and reputation")
	await open_title()
	await touch(title.start_btn)
	check(title.confirm_panel.visible, "Touch Start keeps confirmation behavior")
	await touch(title.get_node("ConfirmPanel/VBox/HBox/YesBtn"))
	await check_world("Touch confirmed Start")
	check(state.player_kurtos == 50 and state.current_day == 1, "Confirmed touch Start preserves reset behavior")
	await open_title()
	print("Title buttons: %d checks, %d failures (real renderer; synthetic mouse/keyboard/controller/touch)" % [checks,failures])
	if failures > 0:
		quit(1)
		return
	# No scripted quit follows this event: process exit proves the actual Quit callback.
	print("QUIT_BUTTON_EVENT_SENT: awaiting actual desktop menu Quit")
	await click(title.quit_btn)
