class_name GameHUD
extends Control

## In-game HUD displaying player currency progress toward 1 Million, Day counter,
## Overall trust rating, inventory, advance-day controls, and notification toasts.

@onready var kurtos_label: Label = %KurtosLabel
@onready var day_label: Label = %DayLabel
@onready var trust_label: Label = %TrustLabel
@onready var inventory_label: Label = %InventoryLabel
@onready var advance_day_btn: Button = %AdvanceDayBtn
@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_label: Label = %ToastLabel

var _toast_timer: float = 0.0


func _ready() -> void:
	toast_panel.visible = false
	advance_day_btn.pressed.connect(_on_advance_day_pressed)
	
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.connect("kurtos_changed", Callable(self, "_on_kurtos_changed"))
		game_state.connect("day_changed", Callable(self, "_on_day_changed"))
		game_state.connect("overall_trust_changed", Callable(self, "_on_overall_trust_changed"))
		game_state.connect("item_added", Callable(self, "_on_item_added"))
		game_state.connect("game_ended", Callable(self, "_on_game_ended"))
		
		# Initial UI sync
		_update_kurtos(game_state.player_kurtos, game_state.goal_kurtos)
		_update_day(game_state.current_day, game_state.max_days)
		_update_trust(game_state.overall_trust)
		_update_inventory(game_state.inventory)


func _process(delta: float) -> void:
	if toast_panel.visible:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast_panel.visible = false


func show_toast(message: String, is_positive: bool = true, duration: float = 3.5) -> void:
	toast_label.text = message
	var style_box = toast_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style_box:
		if is_positive:
			style_box.border_color = Color(0.2, 0.85, 0.4, 0.9)
			style_box.bg_color = Color(0.08, 0.18, 0.12, 0.95)
		else:
			style_box.border_color = Color(0.9, 0.25, 0.25, 0.9)
			style_box.bg_color = Color(0.2, 0.08, 0.08, 0.95)
		toast_panel.add_theme_stylebox_override("panel", style_box)
	
	toast_panel.visible = true
	_toast_timer = duration


func _on_advance_day_pressed() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("advance_day"):
		game_state.advance_day()
		show_toast("🌅 Day %d has begun! All NPC daily budgets have been reset." % game_state.current_day, true, 3.0)


func _on_kurtos_changed(new_amount: int, delta: int) -> void:
	var game_state = get_node_or_null("/root/GameState")
	var goal: int = game_state.goal_kurtos if game_state else 1_000_000
	_update_kurtos(new_amount, goal)
	if delta > 0:
		show_toast("💰 Received +%d Kurtos!" % delta, true, 3.0)


func _on_day_changed(new_day: int) -> void:
	var game_state = get_node_or_null("/root/GameState")
	var max_d: int = game_state.max_days if game_state else 30
	_update_day(new_day, max_d)


func _on_overall_trust_changed(new_val: int, _delta: int) -> void:
	_update_trust(new_val)


func _on_item_added(item: Dictionary) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		_update_inventory(game_state.inventory)
	show_toast("🎒 Acquired item: %s!" % str(item.get("name", "Item")), true, 3.0)


func _on_game_ended(won: bool, message: String) -> void:
	show_toast("👑 %s" % message, won, 10.0)


func _update_kurtos(val: int, goal: int) -> void:
	kurtos_label.text = "💰 %s / %s Kurtos" % [_format_number(val), _format_number(goal)]


func _update_day(day: int, max_d: int) -> void:
	day_label.text = "📅 Day %d / %d" % [day, max_d]


func _update_trust(trust: int) -> void:
	trust_label.text = "🤝 Reputation: %d%%" % trust


func _update_inventory(items: Array[Dictionary]) -> void:
	if items.is_empty():
		inventory_label.text = "🎒 Empty"
		return
	var names: Array = []
	for it in items:
		names.append(str(it.get("name", "Item")))
	inventory_label.text = "🎒 %s" % ", ".join(names)


func _format_number(n: int) -> String:
	var s := str(n)
	var res := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			res = "," + res
		res = s[i] + res
		count += 1
	return res
