extends CheckButton

func _ready() -> void:
	set_pressed_no_signal(LoadComponent.new().load("settings", "real_time_shadows", true))
	await get_tree().create_timer(0.5).timeout
	EventBus.toggle_shadows.emit(LoadComponent.new().load("settings", "real_time_shadows", true))

func _on_toggled(toggled_on: bool) -> void:
	EventBus.toggle_shadows.emit(toggled_on)
	var save = SaveComponent.new().save("settings", "real_time_shadows", toggled_on)
