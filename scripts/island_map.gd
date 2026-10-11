extends Node2D

## IslandMap terrain controller.
## If launched standalone (F6 in Godot editor), automatically spawns Player and Camera.

func _ready() -> void:
	# Check if a player already exists in the scene tree (e.g. when loaded in main.tscn)
	var existing_players := get_tree().get_nodes_in_group("player")
	if existing_players.is_empty():
		# Spawn fallback Player and Camera for standalone testing
		var player_scene := load("res://assets/characters/player.tscn") as PackedScene
		if player_scene:
			var player := player_scene.instantiate() as CharacterBody2D
			player.name = "Player"
			player.position = Vector2(2048, 2560)
			add_child(player)
			
			var cam := Camera2D.new()
			var cam_script := load("res://scripts/smooth_camera.gd") as Script
			if cam_script:
				cam.set_script(cam_script)
			cam.name = "SmoothCamera"
			cam.set("target_node", NodePath("../Player"))
			cam.set("map_limit_left", 0)
			cam.set("map_limit_top", 0)
			cam.set("map_limit_right", 4096)
			cam.set("map_limit_bottom", 2816)
			cam.position = player.position
			add_child(cam)
			print("ℹ️ Standalone IslandMap launched: Spawned Player and SmoothCamera at (2048, 2560)")
