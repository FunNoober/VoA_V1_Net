extends Camera3D

var cos_t : float
var initial_y_value : float

func _ready() -> void:
	initial_y_value = rotation_degrees.y

func _process(delta: float) -> void:
	cos_t += delta
	rotation_degrees.y = (cos(cos_t * 0.25) * 5) + initial_y_value
