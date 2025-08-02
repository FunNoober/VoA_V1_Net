extends Node

func _ready():
	var tim : Timer = Timer.new()
	tim.wait_time = 1
	add_child(tim)
	tim.one_shot = true
	tim.start()
	await tim.timeout
	for button in get_tree().get_nodes_in_group("button"):
		var but : Button = button
		but.button_up.connect(button_pressed)

func button_pressed():
	var aud_player = AudioStreamPlayer.new()
	aud_player.volume_db = -4
	add_child(aud_player)
	aud_player.stream = load("res://assets/sounds/ui/confirmation_001.ogg")
	aud_player.play()
