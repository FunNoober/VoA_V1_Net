class_name Illuminator extends MeshInstance3D

var light_visible : bool = true

@export var light_node : Node3D

func toggle_light():
	sync_light.rpc(light_node.get_path())

@rpc("any_peer", "call_local")
func sync_light(light_path : NodePath):
	var light = get_node(light_path)
	light.visible = !light.visible
