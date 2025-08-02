extends CharacterBody3D

@export var camera : Camera3D
@export var weapons : SpWeaponsManager

const gravity = 10.0
const MOUSE_SENSITIVITY : float = 0.005
const BASE_MOVE_SPEED : float = 3.5
const SPRINT_MOVE_SPEED : float = 5.5

var player_health = 100.0

var stamina : float = 4.0
var SPEED = 3.5
var sprinting : bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)

func _process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var input_dir = Input.get_vector("control_left", "control_right", "control_forward", "control_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	var vel = velocity
	vel = vel.lerp(direction * SPEED, 14 * delta)
	vel.y = velocity.y
	velocity = vel

	move_and_slide()
	
	if Input.is_action_pressed("control_sprint") and stamina > 1.5:
		if stamina <= 0:
			sprinting = false
			return
		sprinting = true
	if Input.is_action_pressed("control_sprint") == false:
		sprinting = false
	if stamina <= 0:
		sprinting = false
		
	if sprinting == true:
		SPEED = SPRINT_MOVE_SPEED
		stamina -= delta
	if sprinting == false:
		SPEED = BASE_MOVE_SPEED
		if stamina < 4.0:
			stamina += delta
			
	var lean_left_intensity : float = Input.get_action_strength("control_leanleft") * 25
	var lean_right_intensity : float = Input.get_action_strength("control_leanright") * 25
	
	rotation_degrees.z = lerp(rotation_degrees.z, lean_left_intensity - lean_right_intensity, delta * 3)
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80, 80)
	
	var rot = Vector3(0 - velocity.y, 0, 0)
	weapons.rotation_degrees = weapons.rotation_degrees.lerp(rot, delta * 10)

func used_attack(camera_jump : Vector2):
	camera.rotation_degrees.x += randf_range(-camera_jump.x, camera_jump.x)
	rotation_degrees.y += randf_range(-camera_jump.y, camera_jump.y)

func right_mouse_clicked(type_id : float, args : Dictionary):
	if !weapons.current_weapon:
		return
	if type_id == 1.1:
		var move_tween = get_tree().create_tween()
		move_tween.tween_property(weapons.current_weapon, "position", args.aim_position, 0.5).set_trans(Tween.TRANS_QUAD)
	if type_id == 1.2:
		var move_tween = get_tree().create_tween()
		move_tween.tween_property(weapons.current_weapon, "position", args.start_position, 0.5).set_trans(Tween.TRANS_QUAD)
