class_name LoadComponent
extends Node

func load(category : String, var_name : String, default : Variant):
	var setting = ConfigFile.new()
	var err = setting.load("user://settings.cfg")
	if err != OK:
		return
	return setting.get_value(category, var_name, default)
