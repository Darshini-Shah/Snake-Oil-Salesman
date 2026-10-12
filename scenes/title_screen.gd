extends Control

@onready var start_btn = $Buttons/StartBtn
@onready var continue_btn = $Buttons/ContinueBtn
@onready var settings_btn = $Buttons/SettingsBtn
@onready var quit_btn = $Buttons/QuitBtn
@onready var settings_panel = $SettingsPanel
@onready var confirm_panel = $ConfirmPanel

func _ready():
	settings_panel.hide()
	confirm_panel.hide()
	
	start_btn.pressed.connect(_on_start_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	$SettingsPanel/VBox/CloseSettingsBtn.pressed.connect(func(): settings_panel.hide())
	$SettingsPanel/VBox/FullscreenBtn.pressed.connect(_on_fullscreen_toggled)
	
	$ConfirmPanel/VBox/HBox/YesBtn.pressed.connect(_on_confirm_start)
	$ConfirmPanel/VBox/HBox/NoBtn.pressed.connect(func(): confirm_panel.hide())
	
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_save():
		continue_btn.disabled = false
	else:
		continue_btn.disabled = true
	
	var buttons = [start_btn, continue_btn, settings_btn, quit_btn]
	for btn in buttons:
		if btn:
			btn.mouse_entered.connect(func(): if not btn.disabled: btn.grab_focus())
			# Match clicks to the visible pixels, including the notched outer border.
			var mask := BitMap.new()
			mask.create_from_image_alpha(btn.texture_normal.get_image(), 0.1)
			btn.texture_click_mask = mask
			btn.mouse_entered.connect(_update_button_feedback.bind(btn))
			btn.mouse_exited.connect(_update_button_feedback.bind(btn))
			btn.focus_entered.connect(_update_button_feedback.bind(btn))
			btn.focus_exited.connect(_update_button_feedback.bind(btn))
			btn.button_down.connect(func(): btn.self_modulate = Color(0.9, 0.9, 0.9))
			btn.button_up.connect(_update_button_feedback.bind(btn))
			_update_button_feedback(btn)
	
	if not continue_btn.disabled:
		continue_btn.grab_focus()
	else:
		start_btn.grab_focus()

func _update_button_feedback(btn: TextureButton) -> void:
	if btn.disabled:
		btn.self_modulate = Color(0.45, 0.45, 0.45)
	elif btn.is_hovered() or btn.has_focus():
		btn.self_modulate = Color(1.08, 1.08, 1.08)
	else:
		btn.self_modulate = Color.WHITE

func _on_start_pressed():
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_save():
		confirm_panel.show()
	else:
		_on_confirm_start()

func _on_confirm_start():
	var gs = get_node_or_null("/root/GameState")
	if gs: gs.reset_game_keep_debug()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_continue_pressed():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.load_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed():
	settings_panel.show()

func _on_quit_pressed():
	get_tree().quit()

func _on_fullscreen_toggled():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
