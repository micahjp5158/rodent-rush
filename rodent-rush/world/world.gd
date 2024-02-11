extends Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_camera_detector_area_entered(area):
	print("entered new room")
	var room_shape = area.get_node("CollisionShape2D").get_shape()
	var room_center = area.get_node("CollisionShape2D").get_position()
	var room_size = room_shape.size
	$player/Camera2D.limit_left = room_center.x - room_size.x/2
	$player/Camera2D.limit_top = room_center.y - room_size.y/2
	$player/Camera2D.limit_right = room_center.x + room_size.x/2
	$player/Camera2D.limit_bottom = room_center.y + room_size.y/2
	
