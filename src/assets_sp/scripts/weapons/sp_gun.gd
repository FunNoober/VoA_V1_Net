extends SpWeapon

enum GUN_STATES {
	RELOADING,
	COOLDOWN,
	IDLE,
	OUT_OF_AMMO
}

@export var magazine_size : int = 10
@export var aim_position : Vector3

@onready var shoot_timer : Timer = $shoot_timer
@onready var reload_timer : Timer = $reload_timer
var gun_state : GUN_STATES = GUN_STATES.IDLE
var current_ammo : int = 10
var start_position : Vector3
var is_aiming : bool = false

func _ready():
	shoot_timer.connect("timeout", shoot_timer_timeout)
	reload_timer.connect("timeout", reload_timer_timeout)
	shoot_timer.one_shot = true
	reload_timer.one_shot = true
	current_ammo = magazine_size
	start_position = position

func _process(delta):
	attack()
	
	if current_ammo <= 0:
		gun_state = GUN_STATES.OUT_OF_AMMO
		
	if Input.is_action_just_pressed("control_reload") and current_ammo < magazine_size:
		start_reloading()
	
	if Input.is_action_just_pressed("control_aim"):
		if is_aiming == false:
			right_mouse_clicked.emit(1.1, {"aim_position" : aim_position, "start_position" : start_position})
			is_aiming = true
			return
		if is_aiming == true:
			right_mouse_clicked.emit(1.2, {"aim_position" : aim_position, "start_position" : start_position})
			is_aiming = false
			return

func attack():
	if Input.is_action_pressed("control_shoot") and gun_state == GUN_STATES.IDLE:
		shoot()

func shoot():
	current_ammo -= 1
	if current_ammo > 0:
		gun_state = GUN_STATES.COOLDOWN
		shoot_timer.start()
	used_attack.emit(camera_jump_when_attacking)

func shoot_timer_timeout():
	gun_state = GUN_STATES.IDLE

func start_reloading():
	gun_state = GUN_STATES.RELOADING
	reload_timer.start()

func reload_timer_timeout():
	current_ammo = magazine_size
	gun_state = GUN_STATES.IDLE
