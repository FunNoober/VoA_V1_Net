extends Node3D

@export var interact_area : Area3D
@export var wait_timer : Timer
@export var move_points : Array[Marker3D]
var interacted_count : int = 0
var cur_pos : int = 0

signal control_point_interacted

func _ready() -> void:
	interact_area.interacted_with.connect(interacted_with)
	wait_timer.timeout.connect(can_interact_again)
	wait_timer = $WaitTimer
	interact_area = $Interact
	
func interacted_with(data : Dictionary):
	interact_area.can_interact_with = false
	control_point_interacted.emit(data)
	wait_timer.start()
	randomize()
	var pos_to_move_to = randi_range(0, move_points.size() -1)
	while pos_to_move_to == cur_pos:
		pos_to_move_to = randi_range(0, move_points.size() -1)
	sync_interacted_count.rpc(pos_to_move_to)

func can_interact_again():
	interact_area.can_interact_with = true

@rpc("any_peer", "call_local")
func sync_interacted_count(pos_to_move_to : int):
	interacted_count += 1
	cur_pos = pos_to_move_to
	if interacted_count >= 8:
		global_position = move_points[pos_to_move_to].global_position
		interacted_count = 0
