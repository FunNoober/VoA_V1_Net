extends Node3D
class_name Weapon

@export var weapon_data : WeaponData
@onready var ammo_counter_view : AmmoCounterView = $AmmoCounterView
@onready var current_ammo_in_mag : int = weapon_data.WeaponMagSize
signal is_reloading
signal finished_reload
var can_shoot = true
var currently_reloading : bool = false

var sin_time : float = 0

var init_pos : Vector3
@export var aim_pos : Vector3

@export var current_optic : Node3D
var current_grip : Node3D
@export var current_illuminator : Illuminator

var holding_r_time : float

func _ready() -> void:
	$weapon_timer.wait_time = weapon_data.WeaponFirerate
	$weapon_timer.connect("timeout", reset_weapon)
	$reload_timer.connect("timeout", reload)
	init_pos = position
	weapon_data.weapon_hash = str(weapon_data.WeaponName + str(weapon_data.RaycastRandomness) + str(weapon_data.WeaponDamage) + str(weapon_data.WeaponMagSize) + str(weapon_data.WeaponRange)).sha256_text()

func _process(delta: float) -> void:
	if weapon_data.WeaponName == "weapon_shield":
		$CharacterBody3D/CollisionShape3D.disabled = !visible
	if is_multiplayer_authority() == false: return
	
	sin_time += delta
	#position.y = init_pos.y + sin(sin_time * 0.2) * 0.02
	#position.x = init_pos.x + cos(sin_time * 0.2) * 0.02
	#position.z = lerp(position.z, init_pos.z, delta * 2)
	
	if currently_reloading: return
	if visible == false: return
	
	if Input.is_action_pressed("control_reload"):
		holding_r_time += delta
		if weapon_data.use_ammo_counter == false: return
		if holding_r_time >= 0.5:
			ammo_counter_view.show_ammo_counter()
	if Input.is_action_just_released("control_reload"):
		if holding_r_time <= 0.5:
			reload_logic()
		holding_r_time = 0
	
	if Input.is_action_just_pressed("control_illuminator") and current_illuminator != null:
		current_illuminator.toggle_light()
	if weapon_data.use_ammo_counter == false: return
	ammo_counter_view.update_ammo_counter(current_ammo_in_mag, weapon_data.WeaponMagSize)

func reload_logic():
	if current_ammo_in_mag == weapon_data.WeaponMagSize: return
	can_shoot = false
	is_reloading.emit()
	$reload_timer.start()
	currently_reloading = true

func just_shot():
	$weapon_timer.start()
	can_shoot = false
	current_ammo_in_mag = current_ammo_in_mag - 1
	if get_node("muzzle_flash"):
		sync_bullet_effects.rpc($muzzle_flash.get_path())
	position.z += weapon_data.WeaponRecoil.y * 0.05

@rpc("any_peer", "call_local")
func sync_bullet_effects(muzzle_flash_path : NodePath):
	var muzzle_flash : GPUParticles3D = get_node(muzzle_flash_path)
	muzzle_flash.restart()

func reset_weapon():
	can_shoot = true

func reload():
	current_ammo_in_mag = weapon_data.WeaponMagSize
	finished_reload.emit()
	currently_reloading = false

func add_illuminator(illuminator_to_add : PackedScene):
	if weapon_data.supports_illuminator == false: return
	if current_illuminator != null:
		current_illuminator.queue_free()
		current_illuminator = null
	
	var illuminator : Illuminator = illuminator_to_add.instantiate()
	add_child(illuminator)
	illuminator.position = weapon_data.illuminator_position
	current_illuminator = illuminator
	sync_illuminiator.rpc(get_path(), illuminator_to_add.get_path())

@rpc("any_peer")
func sync_illuminiator(weapon_path : NodePath, illuminator_to_add_path : String):
	var weapon : Weapon = get_node(weapon_path)
	if weapon.current_illuminator != null:
		weapon.current_illuminator.queue_free()
		weapon.current_illuminator = null
		
	var illuminator : Illuminator = load(illuminator_to_add_path).instantiate()
	weapon.add_child(illuminator)
	illuminator.position = weapon_data.illuminator_position
	weapon.current_illuminator = illuminator
