extends Control

var progress : Array[float]

var text_states = ["<INITIALIZING>", "<<INITIALIZING>>", "<<<INITIALIZING>>>", "<<<<INITIALIZING>>>>", "<<<<<INITIALIZING>>>>>"]
var cur_text_state : int = 0
var has_started_loading : bool = false

func _ready() -> void:
	randomize()
	$Loading/LoadingBar.value = randf_range(5, 10)
	await get_tree().create_timer(randf_range(1, 2)).timeout
	
	ResourceLoader.load_threaded_request("res://assets/maps/game/game.tscn")
	has_started_loading = true

func _process(delta: float) -> void:
	if $Label.text != "It appears something has went wrong while loading":
		$Label.text = text_states[cur_text_state]
		
	if has_started_loading == false:
		return
		
	var loading_status = ResourceLoader.load_threaded_get_status("res://assets/maps/game/game.tscn", progress)
	
	if ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		$Loading/LoadingBar.value = progress[0] * 100
	if ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://assets/maps/game/game.tscn"))
		
	if ResourceLoader.THREAD_LOAD_FAILED:
		$Label.text = "It appears something has went wrong while loading"

func _on_timer_timeout() -> void:
	cur_text_state += 1
	if cur_text_state >= text_states.size():
		cur_text_state = 0
