class_name SpWeaponsManager
extends Node3D

@export var weapon_cast : RayCast3D
@export var sp_player : CharacterBody3D
var current_weapon : SpWeapon
var current_weapon_index : int

var time : float = 0

func _ready():
	for weapon : SpWeapon in get_children():
		weapon.attack_cast = weapon_cast
		weapon.connect("used_attack", sp_player.used_attack)
		weapon.connect("right_mouse_clicked", sp_player.right_mouse_clicked)
	get_parent().get_node("AnimationPlayer").play("weapon_bob")

func _process(delta):
	switch_weapon()
	time += delta

func switch_weapon():
	if Input.is_action_just_pressed("control_weapon1"):
		current_weapon_index += 1
		if current_weapon_index >= get_children().size():
			current_weapon_index = 0
		var target_weapon : SpWeapon = get_child(current_weapon_index)
		for weapon : SpWeapon in get_children():
			weapon.hide()
			weapon.set_process(false)
		target_weapon.set_process(true)
		target_weapon.show()
		current_weapon = target_weapon
		weapon_cast.target_position.z = -current_weapon.attack_cast_range
