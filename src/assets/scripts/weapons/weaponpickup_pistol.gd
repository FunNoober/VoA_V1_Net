extends RigidBody3D

@export var WeaponName : String
@export var FreezeOnStart : bool = false
@export var DeleteOnPickup : bool = false

func _ready() -> void:
	if FreezeOnStart == true:
		stop_physics()
	
	var backward_local : Vector3 = Vector3(-1, 0, 0)
	var backward : Vector3 = (transform.basis * backward_local).normalized()
	apply_impulse(backward * 2, Vector3.ZERO)
	
	var stop_physics_timer := Timer.new()
	stop_physics_timer.wait_time = 15
	stop_physics_timer.one_shot = true
	stop_physics_timer.autostart = false
	stop_physics_timer.connect("timeout", stop_physics)
	add_child(stop_physics_timer)
	stop_physics_timer.start()
	
	$pickup_trigger/CollisionShape3D.shape.radius = 0.5
	
func stop_physics():
	freeze = true
	sleeping = true
