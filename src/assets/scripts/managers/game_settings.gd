extends Node

@export var World_Env : Environment

var player_settings = ConfigFile.new()
var settings_elements

const CURRENT_VERSION = "000001"

func _ready() -> void:
	var err = player_settings.load("user://settings.cfg")
	if err != OK:
		player_settings.save("user://settings.cfg")
		return
	var save_version = player_settings.get_value("meta", "version", "000000")
	if save_version != CURRENT_VERSION:
		player_settings.set_value("meta", "version", CURRENT_VERSION)
		player_settings.save("user://settings.cfg")
		return
