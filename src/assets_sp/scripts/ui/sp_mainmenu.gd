extends Control

func _on_quit_button_pressed():
	get_tree().quit()

func _on_alpha_mission_pressed():
	get_tree().change_scene_to_file("res://assets_sp/scenes/missions/specops/AlphaMission.tscn")
