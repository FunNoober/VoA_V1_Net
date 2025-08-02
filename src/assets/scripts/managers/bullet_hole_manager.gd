extends Node3D

func add_bullet_hole(collision_point, look_dir):
	instance_bullethole.rpc(collision_point, look_dir)
	
@rpc("call_local", "any_peer")
func instance_bullethole(position_to_add, look_dir):
	var made_bullethole = load("res://assets/prefabs/weapons/particles/bullethole_weaponimpact.tscn").instantiate()
	add_child(made_bullethole, true)
	made_bullethole.position = position_to_add
	made_bullethole.get_node("GPUParticles3D").emitting = true
	if look_dir.y != 1 and look_dir.y != -1:
		made_bullethole.rotation = Transform3D.IDENTITY.looking_at(look_dir, Vector3.UP).basis.get_euler()
	elif look_dir == Vector3.UP:
		made_bullethole.rotation_degrees.x = 90
	elif look_dir.y == -1:
		made_bullethole.rotation_degrees.x = 90
