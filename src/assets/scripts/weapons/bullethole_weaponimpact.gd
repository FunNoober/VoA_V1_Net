extends Node3D

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = 5
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	timer.connect("timeout", despawn_bullet_hole)
	timer.start()
	play_impact_sound.rpc($AudioStreamPlayer3D.get_path())

func despawn_bullet_hole():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 24)
	tween.tween_callback(self.queue_free)
	
@rpc("any_peer", "call_local")
func play_impact_sound(audio_player_path : NodePath):
	get_node(audio_player_path).play()
