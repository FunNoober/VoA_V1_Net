class_name Player
extends CharacterBody3D

@export var camera : Camera3D
@export var health_bar : ProgressBar
@export var raycast_interactcast : RayCast3D

@export var weapons : Node3D
@export var weapon_container : Node3D

@export var bullethole : PackedScene

@export var environment : Environment = load("res://assets/grahpics/environment.res")

@export var torso : CharacterBody3D

@export var nvg_overlay : ColorRect
@export var character_models : Node3D

const JUMP_VELOCITY : float = 3.5
const MOUSE_SENSITIVITY : float = 0.005
const BASE_MOVE_SPEED : float = 2.5
const SPRINT_MOVE_SPEED : float = 5.5
const AIM_MOVE_SPEED : float = 1.0

signal add_bullethole(collision_point, look_dir)

var SPEED = 2.5
var gravity = 15

var is_aiming = false
var can_aim : bool = true

var player_health = 100.0

var available_weapons = []
var current_weapon : Weapon
var current_weapon_index : int = 0

var can_switch_weapon

#var player_rot_last_frame : Vector3
#var cam_rot_last_frame : Vector3

var rel_input : Vector2

var normal_fov : float = 100
var ads_fov : float = 45

var stamina : float = 4.0
var sprinting : bool = false

var game_manager : Node

var faction : int = 0

var text_chat_focused : bool = false

var det : float

var bullet_projectile : PackedScene = load("res://assets/prefabs/weapons/particles/bullet_tracer.tscn")

var is_paused : bool = false

@export var weapon_move_curve : Curve

var time : float

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	game_manager = get_parent()

@rpc("call_local", "any_peer")
func initialize_player(bullet_hole_manager, faction_to_set):
	connect("add_bullethole", get_node(bullet_hole_manager).add_bullet_hole)
	faction = faction_to_set
	var faction_label : Label = $Torso/Camera3D/PlayerHUDLayer/Control/FactionLabel
	if faction == 0:
		faction_label.text = "VIPER GROUP"
		$"Root Scene/pmc".visible = true
	if faction == 1:
		faction_label.text = "La mano de la muerte"
		$"Root Scene/cartel".visible = true

func _ready() -> void:
	if not is_multiplayer_authority(): return
	if text_chat_focused == true: return
	position = game_manager.get_node("PlayerSpawn").position
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	for n in weapon_container.get_children():
		n.connect("is_reloading", is_reloading)
		n.connect("finished_reload", finished_reload)
		n.set_multiplayer_authority(str(name).to_int())
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		return
	normal_fov = config.get_value("settings", "fov", 100)
	ads_fov = config.get_value("settings", "fov_ads", 45)
	health_bar.visible = true
	EventBus.toggle_text_chat.connect(text_chat_toggled)

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if text_chat_focused == true: return
	if is_paused: return
	
	if event is InputEventMouseMotion:
		if current_weapon != null:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY * current_weapon.weapon_data.SpeedModifier)
			camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY * current_weapon.weapon_data.SpeedModifier)
		else:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		rel_input = event.relative

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	if text_chat_focused == true: return
	
	if Input.is_action_just_pressed("ui_cancel"):
		is_paused = !is_paused
		if is_paused == true:
			$Torso/Camera3D/PlayerHUDLayer/PauseMenu.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
		if is_paused == false:
			$Torso/Camera3D/PlayerHUDLayer/PauseMenu.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
	
	if is_paused: return
	det = delta
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	health_bar.value = float(player_health)
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80, 80)

		
	lean_logic(delta)
	if Input.is_action_pressed("control_shoot"):
		shoot_logic()
	if Input.is_action_just_pressed("control_shoot"):
		if current_weapon == null: return
		if current_weapon.current_ammo_in_mag <= 0 and current_weapon.can_shoot == true:
			$Torso/Camera3D/WeaponEmptySound.play()
	pickup_logic()
	switch_weapon()
	dynamic_weapon_logic(delta)
		
	var input_dir = Input.get_vector("control_left", "control_right", "control_forward", "control_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if Input.is_action_just_pressed("control_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	var vel = velocity
	vel = vel.lerp(direction * SPEED, 6 * delta)
	vel.y = velocity.y
	velocity = vel

	move_and_slide()
		
	if Input.is_action_just_pressed("control_aim") and current_weapon:
		if is_aiming == false:
			if can_aim:
				is_aiming = true
			return
		if is_aiming == true:
			is_aiming = false
			game_manager.hud_elements.reticle.visible = true
			return
	if current_weapon == null:
		is_aiming = false
	if is_aiming:
		match current_weapon.weapon_data.weapon_aim:
			current_weapon.weapon_data.WEAPON_AIM.AIM_NORMAL:
				camera.fov = lerp(camera.fov, ads_fov, delta * 6)
				current_weapon.position = lerp(current_weapon.position, current_weapon.aim_pos, delta * 6)
				SPEED = AIM_MOVE_SPEED * current_weapon.weapon_data.SpeedModifier
				can_switch_weapon = false
				game_manager.hud_elements.reticle.visible = false
			current_weapon.weapon_data.WEAPON_AIM.AIM_SCOPE:
				camera.fov = lerp(camera.fov, ads_fov / 3, delta * 4)
				SPEED = 0.5 * current_weapon.weapon_data.SpeedModifier
				can_switch_weapon = false
				$Torso/Camera3D/PlayerHUDLayer/Control/SniperOverlay.visible = true
				game_manager.hud_elements.reticle.visible = false
	else:
		camera.fov = lerp(camera.fov, normal_fov, delta * 2)
		if current_weapon != null:
			current_weapon.position = lerp(current_weapon.position, current_weapon.init_pos, delta * 4)
		if current_weapon:
			SPEED = BASE_MOVE_SPEED * current_weapon.weapon_data.SpeedModifier
		else:
			SPEED = BASE_MOVE_SPEED
		can_switch_weapon = true
		$Torso/Camera3D/PlayerHUDLayer/Control/SniperOverlay.visible = false
		
	if Input.is_action_pressed("control_sprint") and stamina > 1.5:
		if stamina <= 0:
			return
		sprinting = true
	if Input.is_action_pressed("control_sprint") == false or stamina <= 0 or is_aiming:
		sprinting = false
	if sprinting == true:
		if current_weapon:
			SPEED = SPRINT_MOVE_SPEED * current_weapon.weapon_data.SpeedModifier
		else:
			SPEED = SPRINT_MOVE_SPEED
		stamina -= delta
	if sprinting == false:
		SPEED = BASE_MOVE_SPEED
		if stamina < 4.0:
			stamina += delta
			
	if Input.is_action_just_pressed("control_nightvision"):
		nightivision()
	
	time += delta
	
	if Input.is_action_pressed("control_compass"):
		$Torso/Camera3D/CompassFrame.show()
	else:
		$Torso/Camera3D/CompassFrame.hide()
	$Torso/Camera3D/CompassFrame/CompassNeedle.rotation_degrees.y = rotation_degrees.y - Vector3.FORWARD.z

func nightivision():
	if nvg_overlay.visible == false:
		nvg_overlay.visible = true
		environment.adjustment_saturation = 0.5
		environment.adjustment_brightness = 3.0
		$Torso/Camera3D/IRLight.visible = true
		return
	else:
		nvg_overlay.visible = false
		environment.adjustment_saturation = 1.0
		environment.adjustment_brightness = 1.0
		$Torso/Camera3D/IRLight.visible = false

func lean_logic(delta):
	var lean_left_intensity : float = Input.get_action_strength("control_leanleft") * 25
	var lean_right_intensity : float = Input.get_action_strength("control_leanright") * 25
	torso.rotation_degrees.z = lerp(torso.rotation_degrees.z, lean_left_intensity - lean_right_intensity, delta * 3)
	character_models.rotation_degrees.x = lerp(character_models.rotation_degrees.x, -lean_left_intensity + lean_right_intensity, delta * 3)

func dynamic_weapon_logic(delta):
	weapon_container.rotation_degrees.x = lerp(weapon_container.rotation_degrees.x, 0.0, delta * 2)
	var reticle : TextureRect = get_parent().hud_elements.reticle
	reticle.scale = lerp(reticle.scale, Vector2(1, 1), delta * 2)
	
	var rot = Vector3(0 - velocity.y, 0, 0)
	if current_weapon != null:
		current_weapon.rotation_degrees.x = lerp(current_weapon.rotation_degrees.x, rel_input.x * 1.5, delta * 3 * weapon_move_curve.sample(abs(current_weapon.rotation_degrees.x) / 10))
		current_weapon.rotation_degrees.z = lerp(current_weapon.rotation_degrees.z, rel_input.y, delta * 6 * weapon_move_curve.sample(abs(current_weapon.rotation_degrees.z) / 10))
		if current_weapon.weapon_data.SpeedModifier < 1:
			camera.rotation_degrees.x -= (current_weapon.weapon_data.SpeedModifier / 2) * 0.01
	weapons.rotation_degrees = weapons.rotation_degrees.lerp(rot, delta * 10)

func shoot_logic():
	if not current_weapon: return
	if current_weapon.can_shoot == false: return

	if  current_weapon.current_ammo_in_mag > 0 and current_weapon.currently_reloading == false:
		var shootcasts = []
		var cur_weapon_data : WeaponData = current_weapon.weapon_data
		for i in cur_weapon_data.RaycastCount:
			var shootcast : RayCast3D = $Torso/Camera3D/RayCast3D.duplicate(8)
			camera.add_child(shootcast)
			shootcasts.append(shootcast)
			shootcast.rotation_degrees.x = randf_range(-1, 1) * cur_weapon_data.RaycastRandomness
			shootcast.rotation_degrees.y = randf_range(-1, 1) * cur_weapon_data.RaycastRandomness
			shootcast.target_position.z = cur_weapon_data.WeaponRange
		current_weapon.just_shot()
		
		if cur_weapon_data.PlaySound == true:
			play_shoot_sound.rpc(cur_weapon_data.ShootSound.resource_path, $Torso/Camera3D/ShootSound.get_path())
		var shoot_cast_timer = Timer.new()
		shoot_cast_timer.wait_time = 0.05
		add_child(shoot_cast_timer)
		shoot_cast_timer.start()
		await shoot_cast_timer.timeout
		for shootcast in shootcasts:
			if shootcast.is_colliding():
				var shootcast_hit : Node = shootcast.get_collider()
				if shootcast_hit.is_in_group("group_player"):
					var weapon_hash = str(cur_weapon_data.WeaponName + str(cur_weapon_data.RaycastRandomness) + str(cur_weapon_data.WeaponDamage) + str(cur_weapon_data.WeaponMagSize) + str(cur_weapon_data.WeaponRange)).sha256_text()
					var damage_amount = cur_weapon_data.damage_falloff.sample(shootcast.global_transform.origin.distance_to(shootcast_hit.global_transform.origin) / -cur_weapon_data.WeaponRange)
					hit_player.rpc(cur_weapon_data.WeaponDamage * damage_amount, shootcast_hit.get_path(), weapon_hash)
					$Torso/Camera3D/PlayerHUDLayer/Control/Hitmarker.show_marker()
				else:
					var look_dir = shootcast.get_collision_normal()
					add_bullethole.emit(shootcast.get_collision_point(), look_dir)
			var spawned_projectile : Node3D = bullet_projectile.instantiate()
			game_manager.add_child(spawned_projectile)
			spawned_projectile.global_position = current_weapon.get_node("muzzle_flash").global_position
			var position_tween = get_tree().create_tween()
			if shootcast.is_colliding():
				position_tween.tween_property(spawned_projectile, "global_position", shootcast.get_collision_point(), 0.05)
			else:
				var pos_to_go = shootcast.to_global(shootcast.target_position)
				position_tween.tween_property(spawned_projectile, "global_position", pos_to_go, 0.05)
			spawned_projectile.look_at(shootcast.target_position, Vector3.UP)
			position_tween.tween_callback(spawned_projectile.queue_free)
			shootcast.queue_free()
			
		if is_aiming == false and sprinting == false:
			weapon_container.rotation_degrees.x = weapon_container.rotation_degrees.x + current_weapon.weapon_data.WeaponRecoil.x
			get_parent().hud_elements.reticle.scale += Vector2(1, 1)
			camera.rotation_degrees.x += current_weapon.weapon_data.WeaponRecoil.x
			rotation_degrees.y += randf_range(cur_weapon_data.HorizontalSpread.x, cur_weapon_data.HorizontalSpread.y)
		if is_aiming == true and sprinting == false:
			#weapon_container.rotation_degrees.x = weapon_container.rotation_degrees.x + current_weapon.weapon_data.WeaponRecoil.y
			get_parent().hud_elements.reticle.scale += Vector2(0.5, 0.5)
			camera.rotation_degrees.x += current_weapon.weapon_data.WeaponRecoil.y
			rotation_degrees.y += randf_range(cur_weapon_data.HorizontalSpread.x /2, cur_weapon_data.HorizontalSpread.y /2)
		if sprinting == true:
			weapon_container.rotation_degrees.x = weapon_container.rotation_degrees.x + current_weapon.weapon_data.WeaponRecoil.x
			get_parent().hud_elements.reticle.scale += Vector2(1.5, 1.5)
			camera.rotation_degrees.x += current_weapon.weapon_data.WeaponRecoil.x * 1.5
		camera.fov += 1

func clear_blood_on_screen():
	var hurt_graphic = game_manager.hud_elements.hurt_graphic
	var clear_blood_tween = get_tree().create_tween()
	clear_blood_tween.tween_property(hurt_graphic, "modulate", Color(255, 0, 0, 0), 2)
	
@rpc("call_local", "any_peer")
func play_shoot_sound(sound_path, path_to_player):
	var s_player : AudioStreamPlayer3D = get_node(path_to_player)
	s_player.stream = load(sound_path)
	s_player.play()

func pickup_logic():
	get_parent().hud_elements.interact_label.hide()
	if raycast_interactcast.is_colliding():
		var intercast_hit : Node = raycast_interactcast.get_collider()
		if intercast_hit == null: return
		if intercast_hit.is_in_group("group_weaponpickup"):
			game_manager.hud_elements.interact_label.show()
	
	if Input.is_action_just_pressed("control_pickup"):
		if raycast_interactcast.is_colliding():
			var interactcast_hit : Node = raycast_interactcast.get_collider()
			if interactcast_hit.is_in_group("group_weaponpickup"):
				var weapon_name = interactcast_hit.get_parent().WeaponName
				if available_weapons.size() >= 2 and weapon_name != current_weapon.weapon_data.WeaponName:
					drop_gun()
				if available_weapons.has(weapon_name) == false:
					available_weapons.append(weapon_name)
				$Torso/Camera3D/PickupWeaponSound.play()
				if interactcast_hit.get_parent().DeleteOnPickup == true:
					delete_pickup.rpc(interactcast_hit.get_parent().get_path())
				if can_switch_weapon == false: return
				for i in Weapons.new().weapons_list:
					if weapon_name == i.name:
						hide_weapon(weapon_container.get_node(i.name), i.name)
	if Input.is_action_just_pressed("control_pickup"):
		if raycast_interactcast.is_colliding():
			var interactcast_hit : Node = raycast_interactcast.get_collider()
			if interactcast_hit.is_in_group("group_interactable"):
				interactcast_hit.interacted({"path": get_path()})
		clear_blood_on_screen()
				
	if Input.is_action_just_pressed("control_dropweapon"):
		drop_gun()

func drop_gun():
	if current_weapon:
		for weapon in available_weapons:
			if weapon == current_weapon.weapon_data.WeaponName:
				available_weapons.erase(weapon)
		create_dropped_weapon.rpc(camera.global_transform.origin, rotation_degrees, current_weapon.weapon_data.WeaponPickup.get_path())
		current_weapon.hide()
		current_weapon = null

@rpc("any_peer", "call_local")
func create_dropped_weapon(position_to_spawn, rotation_to_spawn, current_weapon_pickup):
	var created_pickup = load(current_weapon_pickup).instantiate()
	created_pickup.set_multiplayer_authority(1)
	created_pickup.position = position_to_spawn
	rotation_to_spawn.y = rotation_to_spawn.y + 270
	randomize()
	rotation_to_spawn.x = randf_range(-45, 45)
	created_pickup.rotation_degrees = rotation_to_spawn
	created_pickup.DeleteOnPickup = true
	game_manager.get_node("SpawnedPickups").add_child(created_pickup)

@rpc("any_peer", "call_local")
func delete_pickup(weapon_pickup):
	get_node(weapon_pickup).queue_free()

func switch_weapon():
	if can_switch_weapon == false: return
	if Input.is_action_just_pressed("control_weapon1"):
		if available_weapons.size() == 0:
			return
		if current_weapon_index >= available_weapons.size():
			current_weapon_index = 0
		if current_weapon_index > 2:
			current_weapon_index = 0
		hide_weapon(weapon_container.get_node(available_weapons[current_weapon_index]), available_weapons[current_weapon_index])
		current_weapon_index += 1
	if Input.is_action_just_pressed("control_weapon2"):
		if available_weapons.size() == 0:
			return
		if current_weapon_index >= available_weapons.size():
			current_weapon_index = 0
		if current_weapon_index > 2:
			current_weapon_index = 0
		hide_weapon(weapon_container.get_node(available_weapons[current_weapon_index]), available_weapons[current_weapon_index])
		current_weapon_index += 1

func hide_weapon(weapon, weapon_name):
	if available_weapons.has(weapon_name) == false: return
	for n in weapon_container.get_children():
		if not n == weapon:
			n.hide()
	if available_weapons.has(weapon_name):
		if weapon.visible == false:
			weapon.visible = true
			current_weapon = weapon as Weapon
			return
			
@rpc("any_peer", "call_local")
func hit_player(damage_amount, target_player, weapon_hash : String):
	if multiplayer.is_server():
		var weapon_hash_valid : bool = false
		for weapon : Weapon in weapon_container.get_children():
			if weapon.weapon_data.weapon_hash == weapon_hash:
				weapon_hash_valid = true
				break
		if weapon_hash_valid == false: return
		if get_node(target_player).has_signal("part_hit") == false:
			recieve_damage.rpc_id(get_node(target_player).name.to_int(), damage_amount, target_player)
		if get_node(target_player).has_signal("part_hit"):
			get_node(target_player).take_damage.rpc_id(get_node(target_player).root_node.name.to_int(), damage_amount)
			
@rpc("any_peer", "call_local")
func recieve_damage(damage_amount, target_player):
	if multiplayer.get_remote_sender_id() != 1: return
	var player : Node
	if get_node(target_player).name == "Torso":
		player = get_node(target_player).get_parent()
	else:
		player = get_node(target_player)
	player.player_health -= damage_amount
	player.game_manager.hud_elements.hurt_graphic.modulate = Color(255, 0, 0, 1)
	player.get_node("Torso/Camera3D/HitSound").play()
	if player.player_health <= 0:
		var death_cam = Camera3D.new()
		death_cam.fov = camera.fov
		get_parent().add_child(death_cam)
		death_cam.global_transform = camera.global_transform
		environment.adjustment_saturation = 0
		var cam_tween = get_tree().create_tween()
		cam_tween.tween_property(death_cam, "rotation_degrees:x", -90, 1).set_trans(Tween.TRANS_BACK)
		death_cam.current = true
		reset_player_pos.rpc(player.get_path())
		var wait_timer = get_tree().create_timer(4)
		await wait_timer.timeout
		death_cam.queue_free()
		player.camera.current = true
		cam_tween.kill()
		player.player_health = 100
		player.clear_blood_on_screen()
		player.rotation_degrees = Vector3.ZERO
		environment.adjustment_saturation = 1

@rpc("any_peer", "call_local")
func reset_player_pos(player_path):
	get_node(player_path).global_position = game_manager.player_spawn.global_position

func is_reloading():
	can_switch_weapon = false
	weapon_container.rotation_degrees.x = 0.0
	$AnimationPlayer.play("reload")
	camera.get_node("ReloadWeaponSound").play()

func finished_reload():
	can_switch_weapon = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("transition")

func text_chat_toggled(toggled : bool):
	text_chat_focused = toggled

func _on_resume_button_pressed():
	is_paused = false
	$Torso/Camera3D/PlayerHUDLayer/PauseMenu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_return_to_menu_button_pressed():
	if name != "1":
		game_manager.disconnect_self(name.to_int())
	if name == "1":
		game_manager.disconnect_self_as_server()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "transition":
		$AnimationPlayer.play("RESET")

func _on_head_part_hit(damage_amount : float):
	recieve_damage(damage_amount, self.get_path())

func _on_torso_part_hit(damage_amount):
	recieve_damage(damage_amount, self.get_path())
