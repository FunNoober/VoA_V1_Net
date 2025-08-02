class_name ChangeSetting
extends Node

var world_env = load("res://assets/grahpics/environment.res")

var resolutions : Dictionary = {
	"256x144": Vector2(256, 144),
	"960x540": Vector2(960, 540),
	"1280x720": Vector2(1280, 720),
	"1920x1080": Vector2(1920, 1080),
	"2560x1440": Vector2(2560, 1440),
	"3840x2160": Vector2(3840, 2160)
}

func change_resolution(index : int, viewport : Viewport):
	DisplayServer.window_set_size(resolutions.values()[index])
	viewport.set_scaling_3d_scale(resolutions.values()[index].x / 3840)

func set_value_to_change(value_to_change : Variant, change_to : Variant, viewport : Viewport):
	match value_to_change:
		"screen_resolution":
			change_resolution(change_to, viewport)
			return
		"windowed":
			if change_to == false:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			return
	world_env.set(value_to_change, change_to)
	return self
