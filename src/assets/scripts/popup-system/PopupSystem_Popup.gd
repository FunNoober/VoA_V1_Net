extends Control

func initialize(duration, window_title : String, window_contents : String):
	var window : AcceptDialog = $ConfirmationDialog
	window.title = window_title
	window.dialog_text = window_contents
	window.visible = true
	
	$Timer.wait_time = duration
	$Timer.autostart = true
	$Timer.start()

func _on_timer_timeout() -> void:
	queue_free()
	
func _on_confirmation_dialog_confirmed() -> void:
	queue_free()
