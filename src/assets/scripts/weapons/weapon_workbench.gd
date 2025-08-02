extends Node3D


func _on_interactable_interacted_with(data):
	var player : Player = get_node(data.path)
	if player.current_weapon != null:
		player.current_weapon.add_illuminator(load("res://assets/prefabs/weapon_attachements/flashlight.tscn"))
