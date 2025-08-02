extends Node
	
func _process(delta):
	if Input.is_action_just_pressed("control_screenshot"):
		var img = get_viewport().get_texture().get_image()
		img.save_jpg("user://screenshot_VoA_" + str(Time.get_unix_time_from_system()) + ".jpg", 0.7)
