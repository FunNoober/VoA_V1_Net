class_name AmmoCounterView extends Node3D

@onready var ammo_label : Label = $SubViewport/CanvasLayer/Control/Label
@onready var ammo_bar : ProgressBar = $SubViewport/CanvasLayer/Control/ProgressBar

func _ready():
	ammo_bar.modulate.a = 0.0

func update_ammo_counter(current_ammo : int, ammo_in_mag : int):
	#ammo_label.text = str(current_ammo) + "/" + str(ammo_in_mag)
	ammo_bar.max_value = ammo_in_mag
	ammo_bar.value = current_ammo
	
func show_ammo_counter():
	var modulate_tween : Tween = get_tree().create_tween()
	modulate_tween.tween_property(ammo_bar, "modulate:a", 1, 0.5)
	modulate_tween.tween_callback(fade_out_label)

#func _process(delta):
	#ammo_label.modulate.a = lerp(ammo_label.modulate.a, 0.0, delta * 2)

func fade_out_label():
	await get_tree().create_timer(1).timeout
	var modulate_tween : Tween = get_tree().create_tween()
	modulate_tween.tween_property(ammo_bar, "modulate:a", 0, 0.5)
