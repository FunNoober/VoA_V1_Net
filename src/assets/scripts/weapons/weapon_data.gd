class_name  WeaponData
extends Resource

@export_category("Metadata")
@export var WeaponName : String
@export var WeaponPickup : PackedScene
@export var WeaponDamage : float = 15
@export_range(0.00, 50) var WeaponFirerate : float = 3
@export var use_ammo_counter : bool = true
@export var damage_falloff : Curve

@export var WeaponRange : float = -150
@export var WeaponMagSize : int = 10
@export var ShootSound : AudioStream
@export_category("Sound")
@export var PlaySound : bool = true
@export var IsHeavy : bool = false
@export_category("Recoil")
@export var RaycastRandomness : float = 0.0
@export var WeaponRecoil : Vector2 = Vector2(5, 1)
@export var HorizontalSpread : Vector2 =  Vector2(-1, 1)
@export var SpeedModifier : float = 1.0

@export var RaycastCount : int = 1

const pickup_trigger_radius : float = 1

enum WEAPON_AIM {
	AIM_NORMAL,
	AIM_SCOPE
}

@export var weapon_aim : WEAPON_AIM = WEAPON_AIM.AIM_NORMAL

var weapon_hash : String

@export_category("Optic")
@export var supports_optic : bool = true
@export var optic_position : Vector3

@export_category("Grip")
@export var supports_grip : bool = false
@export var grip_position : Vector3

@export_category("Illuminator")
@export var supports_illuminator : bool = true
@export var illuminator_position : Vector3
