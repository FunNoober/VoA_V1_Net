extends Label

var show_counter : bool = true

func _ready() -> void:
	EventBus.toggle_fpscounter.connect(toggle_counter)
	
func _process(delta: float) -> void:
	text = "FPS: " + str(Engine.get_frames_per_second()) + "\n" + str(Performance.get_monitor(Performance.TIME_PROCESS)) + "\n" + str(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	
func toggle_counter(toggle: bool):
	show_counter = toggle
	visible = toggle
