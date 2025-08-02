class_name SpWeapon
extends Node3D

signal used_attack
signal right_mouse_clicked(type_id : float, args : Dictionary)

@export var camera_jump_when_attacking : Vector2
@export var attack_cast_range : float = 100

var attack_cast : RayCast3D

func attack():
	pass
