extends Node

@onready var popup : PackedScene = load("res://assets/scripts/popup-system/PopupSystem_Popup.tscn")

func new_popup(duration, window_title : String, window_contents : String):
	var created_popup = popup.instantiate()
	add_child(created_popup)
	created_popup.initialize(duration, window_title, window_contents)
