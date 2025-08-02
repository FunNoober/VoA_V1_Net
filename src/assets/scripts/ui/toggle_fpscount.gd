extends CheckButton

func _ready() -> void:
	toggled.connect(_on_toggled)
	var timer = Timer.new()
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	timer.start(0.1)
	await timer.timeout
	var toggle_fps_counter = LoadComponent.new().load("settings", "fps_counter", true)
	set_pressed_no_signal(toggle_fps_counter)
	EventBus.toggle_fpscounter.emit(toggle_fps_counter)
	
func _on_toggled(toggled_on: bool):
	EventBus.toggle_fpscounter.emit(toggled_on)
	var save = SaveComponent.new().save("settings", "fps_counter", toggled_on)
