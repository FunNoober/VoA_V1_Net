extends LineEdit

var console : LineEdit = self
var hud_on : bool = true

func _ready():
	console.text_submitted.connect(cmd_entered)

func _process(delta):
	if Input.is_action_just_pressed("control_openconsole"):
		console.visible = !console.visible
		console.text = ""
		console.grab_focus()

func cmd_entered(new_text : String) -> void:
	var text_entered = new_text.to_lower()
	if text_entered == "toggle_hud":
		hud_on = !hud_on
		EventBus.toggle_hud.emit(hud_on)
	if text_entered == "toggle_fps":
		var fps_toggle_status = LoadComponent.new().load("settings", "fps_counter", true)
		EventBus.toggle_fpscounter.emit(!fps_toggle_status)
		var save = SaveComponent.new().save("settings", "fps_counter", !fps_toggle_status)
	console.text = ""
