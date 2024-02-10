extends Button

func _on_pressed():
	# Change to world scene
	get_tree().change_scene_to_file("res://world/world.tscn")
