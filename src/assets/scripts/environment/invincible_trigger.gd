extends Area3D

func _process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player:
			var player : Player = body
			player.player_health = 100
