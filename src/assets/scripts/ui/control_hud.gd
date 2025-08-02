extends Control

@export var hud_elements : Array[Control]

func _ready():
	EventBus.toggle_hud.connect(toggle_hud)
	
func _process(delta):
	$TextChat.set_process(visible)
	
func toggle_hud(toggle : bool):
	for hud_element in hud_elements:
		hud_element.visible = toggle
