extends Node3D

enum OPEN_STATES {
	OPEN_BACK,
	OPEN_FRONT,
	OPEN_CLOSED
}
@onready var door = $door_frame/door
@export var locked_shut : bool = false
@export var current_open_state : OPEN_STATES = OPEN_STATES.OPEN_CLOSED
@export var open_angle : float = 75
@export var time_to_open : float = 3
var tween_transition = Tween.TRANS_CUBIC

func _ready():
	if locked_shut:
		$door_frame/door/Back/Label3D.hide()
		$door_frame/door/Front/Label3D.hide()

func _on_front_interacted_with(data):
	match current_open_state:
		OPEN_STATES.OPEN_BACK:
			update_door_status.rpc(OPEN_STATES.OPEN_CLOSED)
		OPEN_STATES.OPEN_FRONT:
			update_door_status.rpc(OPEN_STATES.OPEN_CLOSED)
		OPEN_STATES.OPEN_CLOSED:
			update_door_status.rpc(OPEN_STATES.OPEN_FRONT)

func _on_back_interacted_with(data):
	match current_open_state:
		OPEN_STATES.OPEN_BACK:
			update_door_status.rpc(OPEN_STATES.OPEN_CLOSED)
		OPEN_STATES.OPEN_FRONT:
			update_door_status.rpc(OPEN_STATES.OPEN_CLOSED)
		OPEN_STATES.OPEN_CLOSED:
			update_door_status.rpc(OPEN_STATES.OPEN_BACK)

@rpc("any_peer", "call_local")
func update_door_status(open_state):
	if locked_shut:
		open_state = OPEN_STATES.OPEN_CLOSED
	current_open_state = open_state
	
	var tween = get_tree().create_tween()
	match current_open_state:
		OPEN_STATES.OPEN_CLOSED:
			tween.tween_property(door, "rotation_degrees:y", 0, time_to_open).set_trans(tween_transition)
		OPEN_STATES.OPEN_FRONT:
			tween.tween_property(door, "rotation_degrees:y", -open_angle, time_to_open).set_trans(tween_transition)
		OPEN_STATES.OPEN_BACK:
			tween.tween_property(door, "rotation_degrees:y", open_angle, time_to_open).set_trans(tween_transition)
