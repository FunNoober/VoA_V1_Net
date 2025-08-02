extends TextureRect

func _process(delta: float) -> void:
	scale = lerp(scale, Vector2(0, 0), delta * 5)

func show_marker():
	scale = Vector2(1, 1)
