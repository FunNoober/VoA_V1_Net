class_name TextChat extends VBoxContainer

var chat_entry_visible : bool = false
var text_is_in_focus : bool = false
@export var game_manager : GameManager
@onready var word_blacklist : WordBlackist = preload("res://assets/data/blacklist.tres")

var hud_on : bool = true

func _ready():
	TextChatApi.active_chat = self

func _process(delta):
	$Display.modulate.a = lerp($Display.modulate.a, 0.0, delta * 5)
	if Input.is_action_just_pressed("control_textchat") and text_is_in_focus == false:
		show_chat()
		text_is_in_focus = true
		EventBus.toggle_text_chat.emit($TextEntry.visible)
		
	if Input.is_action_just_pressed("ui_cancel"):
		text_is_in_focus = false
		$TextEntry.visible = false
		chat_entry_visible = false
		EventBus.toggle_text_chat.emit($TextEntry.visible)
		text_is_in_focus = false
		
	if Input.is_action_just_pressed("ui_accept"):
		var message : String = $TextEntry.text
		if message.contains("/"):
			message = message.to_lower()
			message = message.erase(0)
			if message == "toggle_hud":
				hud_on = !hud_on
				EventBus.toggle_hud.emit(hud_on)
			if message == "toggle_fps":
				var fps_toggle_status = LoadComponent.new().load("settings", "fps_counter", true)
				EventBus.toggle_fpscounter.emit(!fps_toggle_status)
				var save = SaveComponent.new().save("settings", "fps_counter", !fps_toggle_status)
		else:
			send_message.rpc(game_manager.username, message)
		$TextEntry.text = ""
		$TextEntry.visible = false
		EventBus.toggle_text_chat.emit($TextEntry.visible)
		chat_entry_visible = false
		text_is_in_focus = false
		
	if chat_entry_visible == true or text_is_in_focus == true:
		$Display.modulate.a = 255

func show_chat():
	if chat_entry_visible == false:
		$TextEntry.visible = true
		$TextEntry.grab_focus()
		chat_entry_visible = true
		return
	else:
		$TextEntry.visible = false
		chat_entry_visible = false

@rpc("call_local", "any_peer")
func send_message(username : String, contents : String):
	if contents.is_empty() == false:
		$Display.modulate.a = 255
		for word in word_blacklist.words:
			if contents.to_lower().contains(word):
				contents = contents.replace(word, "[color=red][RETRACTED][/color]")
		$Display.text = $Display.text + "\n[" + username + "] " + contents
