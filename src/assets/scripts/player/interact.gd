class_name Interactable extends Area3D

signal interacted_with(data : Dictionary)

@export var InteractText : String = "[F] To Interact"
@export var InteractLabel : Label3D
@export var InteractLabelPivot : Marker3D
@export var can_interact_with : bool = true

var cam : Camera3D
var distance_between_cam : float

func _ready() -> void:
	add_to_group("group_interactable")
	InteractLabel.text = InteractText

func _physics_process(delta: float) -> void:
	cam = get_viewport().get_camera_3d()
	distance_between_cam = (global_position.distance_to(cam.global_position))

func interacted(data : Dictionary):
	if can_interact_with == false: return
	interacted_with.emit(data)
