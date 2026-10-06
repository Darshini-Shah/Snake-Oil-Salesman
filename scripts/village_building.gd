@tool
class_name VillageBuilding
extends StaticBody2D

## Prop building for Snake Oil Salesman village square.
## Combines pixel art building sprite, grounded collision footprint, and atmospheric sign.

@export var building_texture: Texture2D:
	set(val):
		building_texture = val
		if has_node("Sprite2D"):
			$Sprite2D.texture = val
		_update_building()

@export var building_name: String = "":
	set(val):
		building_name = val
		if has_node("NameLabel"):
			$NameLabel.text = val
			$NameLabel.visible = not val.is_empty()

@export var footprint_size: Vector2 = Vector2(140, 60):
	set(val):
		footprint_size = val
		_update_building()

@export var footprint_offset: Vector2 = Vector2(0, 35):
	set(val):
		footprint_offset = val
		_update_building()

@export var sprite_scale: Vector2 = Vector2(2.0, 2.0):
	set(val):
		sprite_scale = val
		if has_node("Sprite2D"):
			$Sprite2D.scale = val
		_update_building()


func _ready() -> void:
	_update_building()


func _update_building() -> void:
	if has_node("Sprite2D") and building_texture:
		$Sprite2D.texture = building_texture
		$Sprite2D.scale = sprite_scale
	if has_node("CollisionShape2D"):
		var col := $CollisionShape2D as CollisionShape2D
		if col.shape == null or not (col.shape is RectangleShape2D):
			col.shape = RectangleShape2D.new()
		(col.shape as RectangleShape2D).size = footprint_size
		col.position = footprint_offset
	if has_node("NameLabel"):
		$NameLabel.text = building_name
		$NameLabel.visible = not building_name.is_empty()
