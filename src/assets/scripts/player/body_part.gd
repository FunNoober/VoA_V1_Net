extends CharacterBody3D

signal part_hit(damage_amount)
@export_range(1, 10) var damage_multiplayer : float = 1
@export var root_node : Node

@rpc("any_peer", "call_local")
func take_damage(damage_amount : float):
	part_hit.emit(damage_amount * damage_multiplayer)
