extends Control

@export var setting_to_change : String

const CURRENT_VERSION = "000001"

func _ready() -> void:
	match get_class():
		"CheckButton":
			connect("toggled", toggled)
		"OptionButton":
			connect("item_selected", item_selected)
			
	var player_settings = ConfigFile.new()
	var err = player_settings.load("user://settings.cfg")
	if err != OK:
		return
	var save_version = player_settings.get_value("meta", "version", "000000")
	if save_version != CURRENT_VERSION:
		player_settings.clear()
		player_settings.set_value("meta", "version", CURRENT_VERSION)
		player_settings.save("user://settings.cfg")
		return
	match get_class():
		"OptionButton":
			get_node(get_path()).select(player_settings.get_value("settings", setting_to_change, 3))
			item_selected(player_settings.get_value("settings", setting_to_change, 3))
		"CheckButton":
			get_node(get_path()).set_pressed_no_signal(player_settings.get_value("settings", setting_to_change, true))
			toggled(player_settings.get_value("settings", setting_to_change, true))

func toggled(toggled_on : bool) -> void:
	var change_setting : ChangeSetting = ChangeSetting.new().set_value_to_change(setting_to_change, toggled_on, get_viewport())
	
	var save = SaveComponent.new().save("settings", setting_to_change, toggled_on)

func item_selected(index : int) -> void:
	var change_setting : ChangeSetting = ChangeSetting.new().set_value_to_change(setting_to_change, index, get_viewport())
	
	var save = SaveComponent.new().save("settings", setting_to_change, index)
