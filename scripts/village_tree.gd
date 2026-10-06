@tool
class_name VillageTree
extends StaticBody2D

## Decorative tree prop for Snake Oil Salesman village square.

@export var tree_texture: Texture2D:
	set(val):
		tree_texture = val
		if has_node("Sprite2D"):
			$Sprite2D.texture = val

@export var tree_scale: Vector2 = Vector2(2.0, 2.0):
	set(val):
		tree_scale = val
		if has_node("Sprite2D"):
			$Sprite2D.scale = val


func _ready() -> void:
	if has_node("Sprite2D") and tree_texture:
		$Sprite2D.texture = tree_texture
		$Sprite2D.scale = tree_scale
