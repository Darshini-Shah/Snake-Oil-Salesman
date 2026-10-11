extends SceneTree
var count := 0
func _init() -> void:
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	count += 1
	if count > 30:
		quit(0)
