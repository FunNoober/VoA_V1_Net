class_name SaveComponent
extends Node

func save(category : String, var_name : String, value : Variant):
	var setting = ConfigFile.new()
	var err = setting.load("user://settings.cfg")
	if err != OK:
		return
	setting.set_value(category, var_name, value)
	setting.save("user://settings.cfg")
