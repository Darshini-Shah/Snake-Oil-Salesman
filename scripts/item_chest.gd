class_name ItemChest
extends Area2D

## Simple interactable chest or stall allowing player to acquire key disguise items.

@export var item_id: String = "beggars_robe"
@export var item_name: String = "Beggar's Robe"
@export var item_description: String = "An old tattered robe that evokes deep sympathy from kind-hearted folks."
@export var chest_color: Color = Color(0.8, 0.5, 0.2, 1.0)

var is_player_in_range: bool = false
var is_collected: bool = false

@onready var prompt_label: Label = $PromptLabel
@onready var color_rect: ColorRect = $ColorRect
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("get_item_icon"):
		sprite.texture = game_state.get_item_icon(item_id)
	
	if game_state and game_state.has_item(item_id):
		is_collected = true
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	color_rect.color = chest_color
	prompt_label.visible = false
	prompt_label.text = "[E] Pick up %s" % item_name
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and is_player_in_range and not is_collected:
			_collect_item()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_range = true
		if not is_collected:
			prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_range = false
		prompt_label.visible = false


func _collect_item() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("add_item"):
		game_state.add_item(item_id, item_name, item_description)
		is_collected = true
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
