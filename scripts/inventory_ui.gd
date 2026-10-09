class_name InventoryUI
extends Control

@onready var grid: GridContainer = %ItemGrid
@onready var close_btn: Button = %CloseBtn
@onready var item_name_label: Label = %ItemNameLabel
@onready var item_desc_label: Label = %ItemDescLabel
@onready var item_icon_rect: TextureRect = %ItemIconRect
@onready var equip_btn: Button = %EquipBtn

var selected_item_id: String = ""

func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)
	equip_btn.pressed.connect(_on_equip_pressed)
	equip_btn.disabled = true
	_refresh_inventory()
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.item_added.connect(_on_item_added)


func _on_close_pressed() -> void:
	var hud = get_parent()
	if hud and hud.has_method("_on_inventory_btn_pressed"):
		hud._on_inventory_btn_pressed()
	else:
		queue_free()


func _on_item_added(_item: Dictionary) -> void:
	_refresh_inventory()


func _refresh_inventory() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	var gs = get_node_or_null("/root/GameState")
	if not gs: return
	
	for item in gs.inventory:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(72, 72)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.icon = gs.get_item_icon(item.id)
		
		var bound_item = item
		btn.pressed.connect(func(): _on_item_selected(bound_item))
		grid.add_child(btn)


func _on_item_selected(item: Dictionary) -> void:
	selected_item_id = item.id
	item_name_label.text = item.get("name", "Unknown Item")
	item_desc_label.text = item.get("description", "No description available.")
	var gs = get_node_or_null("/root/GameState")
	if gs:
		item_icon_rect.texture = gs.get_item_icon(item.id)
	
	equip_btn.text = "Inspect"
	equip_btn.disabled = false


func _on_equip_pressed() -> void:
	# Inspection is default, we don't have equipment systems implemented per requirements
	pass
