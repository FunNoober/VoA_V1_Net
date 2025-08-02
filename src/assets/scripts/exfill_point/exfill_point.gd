extends StaticBody3D

@export var interact_area : Area3D
@export var spawn_point : Marker3D

func _ready():
	interact_area = $Interact
	interact_area.interacted_with.connect(interacted_with)

func interacted_with(data: Dictionary):
	var player : CharacterBody3D = get_node(data.path)
	player.global_position = get_parent().spawn_point.global_position
