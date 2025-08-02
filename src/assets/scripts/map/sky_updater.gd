@tool
extends Node3D

func _process(delta):
	if Engine.is_editor_hint() == false: return
	if get_parent().sky_overide != null:
		$WorldEnvironment.environment.sky = get_parent().sky_overide
