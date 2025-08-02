class_name GameManager extends Node

@onready var menu_main = $CanvasLayer/menu_main
@onready var control_hud = $CanvasLayer/control_hud
@onready var hud = $CanvasLayer/control_hud
@onready var player_spawn = $PlayerSpawn

@onready var hud_elements : Dictionary = {
	"reticle": $CanvasLayer/control_hud/reticle,
	"hurt_graphic": $CanvasLayer/control_hud/hurt_graphic,
	"interact_label": $CanvasLayer/control_hud/interact_label,
	"console": $CanvasLayer/control_hud/console
}

@export var map_data : Array[MapData]
var map_index : int = 0
var currently_selected_map : MapData
var map : Map

@export var World_Env : Environment
@export var lineedit_username : LineEdit
@export var lineedit_address : LineEdit
@export var server_name : LineEdit
@export var console : LineEdit

const PLAYER = preload("res://assets/prefabs/player/player.tscn")
const PORT = 6788
var enet_peer = ENetMultiplayerPeer.new()

var player_settings = ConfigFile.new()

var players = []
var factions = [[],[]]
var faction_points = [0, 0]

var username : String = "Jayeater69"
var hostname : String = "Jayeater69"

var in_game : bool = false

signal hosted_server(playername : String, servername : String)
signal closed_server
signal refresh_server_list

var time_of_build = "7:59 PM 6/22/2024"
var author = "Noober Developments"
var version = "0.0.2"

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	multiplayer.connected_to_server.connect(self_connected)
	#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
func _on_button_host_pressed() -> void:
	if lineedit_username.text.is_empty():
		PopupSystem.new_popup(25, "Multiplayer Error", "You cannot have an empty username")
		return
	if server_name.text.is_empty():
		PopupSystem.new_popup(25, "Multiplayer Error", "Your server name can not be empty")
		return
	menu_main.hide()
	control_hud.show()
	$CanvasLayer/menu_main/AudioStreamPlayer.stop()
	$CanvasLayer/menu_main/CasseteSound.stop()
	username = lineedit_username.text
	
	enet_peer.create_server(PORT, 26)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(player_connected_to_server)
	multiplayer.peer_disconnected.connect(player_disconnected_from_server)
	
	player_connected_to_server(multiplayer.get_unique_id())
	in_game = true
	currently_selected_map = map_data[map_index]
	var created_map = currently_selected_map.map_scene.instantiate()
	$Map.add_child(created_map)
	map = created_map
	map.spawn_point = $PlayerSpawn
	$ControlPoint.move_points = map.control_points
	$ControlPoint.global_position = map.control_points[0].global_position
	if $CanvasLayer/menu_main/MarginContainer/TabContainer/Multiplayer/TopbarMargain/TopbarContainer/button_hideserver.button_pressed == false:
		hosted_server.emit(username, server_name.text, currently_selected_map.map_name)
	if map.sky_overide != null:
		$Graphics/WorldEnvironment.environment.sky = map.sky_overide

func _on_button_join_pressed() -> void:
	join_server(lineedit_address.text)

func player_connected_to_server(peer_id):
	var players_in_pmc = factions[0].size()
	var players_in_cartel = factions[1].size()
	var faction = 0
	if players_in_pmc == players_in_cartel:
		factions[0].append(peer_id)
		faction = 0
	elif players_in_cartel > players_in_pmc:
		factions[0].append(peer_id)
		faction = 0
	elif players_in_pmc > players_in_cartel:
		factions[1].append(peer_id)
		faction = 1
	var player = PLAYER.instantiate()
	player.name = str(peer_id)
	player.position = $PlayerSpawn.position
	player.rotation = $PlayerSpawn.rotation
	add_child(player)
	player.set_multiplayer_authority(str(peer_id).to_int())
	player.initialize_player.rpc_id(peer_id, get_node("BulletHoles").get_path(), faction)
	players.append(peer_id)
	update_host_name.rpc_id(peer_id, username.to_upper())
	sync_score.rpc_id(peer_id, faction_points)
	if peer_id != multiplayer.get_unique_id():
		sync_map.rpc_id(peer_id, map_index)
	send_message_on_join.rpc_id(peer_id)
	
@rpc("call_local")
func send_message_on_join():
	TextChatApi.active_chat.send_message.rpc(username, "has joined")

@rpc("any_peer")
func sync_map(map_indice):
	currently_selected_map = map_data[map_indice]
	var created_map = currently_selected_map.map_scene.instantiate()
	$Map.add_child(created_map)
	map = created_map
	map.spawn_point = $PlayerSpawn
	$ControlPoint.move_points = map.control_points
	if map.sky_overide != null:
		$World_Env.envirionment.sky = map.sky_overide

func player_disconnected_from_server(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		for i in len(players):
			if players[i] == peer_id:
				players.remove_at(i)
		for x in len(factions):
			for y in len(factions[x]):
				if factions[x][y] == peer_id:
					factions[x].remove_at(y)
		TextChatApi.active_chat.send_message.rpc(str(peer_id), "has left")
		
func disconnect_self(player_id):
	player_disconnected_from_server(player_id)
	multiplayer.multiplayer_peer = null
	enet_peer.disconnect_peer(player_id)
	enet_peer = ENetMultiplayerPeer.new()
	control_hud.hide()
	menu_main.show()
	$CanvasLayer/menu_main/AudioStreamPlayer.play()
	$CanvasLayer/menu_main/CasseteSound.play()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$CanvasLayer/control_hud/TextChat/Display.text = ""
	for child in $Map.get_children():
		child.queue_free()

func disconnect_self_as_server():
	for i in len(players):
		if players[i] != 1:
			disconnect_player_from_server.rpc_id(players[i], players[i])
	players = []
	var disconnect_timer : Timer = Timer.new()
	add_child(disconnect_timer)
	disconnect_timer.wait_time = 0.4
	disconnect_timer.autostart = true
	disconnect_timer.one_shot = true
	disconnect_timer.start()
	disconnect_timer.connect("timeout", server_host_disconnect)
	for i in $BulletHoles.get_children():
		i.queue_free()
	for i in $SpawnedPickups.get_children():
		i.queue_free()
	closed_server.emit()
	in_game = false
	faction_points[0] = 0
	faction_points[1] = 0
	
@rpc
func disconnect_player_from_server(peer_id):
	disconnect_self(peer_id)

func server_host_disconnect():
	disconnect_self(1)

func _process(delta: float) -> void:	
	$CanvasLayer/menu_main/MarginContainer/TabContainer/Settings/columns/column_1_margain/column_1/label_fov_normal.text = "FOV (Normal) " + str($CanvasLayer/menu_main/MarginContainer/TabContainer/Settings/columns/column_2_margain/column_2/slider_fov_normal.value)
	$CanvasLayer/menu_main/MarginContainer/TabContainer/Settings/columns/column_1_margain/column_1/label_fov_ads.text = "FOV (Aiming) " + str($CanvasLayer/menu_main/MarginContainer/TabContainer/Settings/columns/column_2_margain/column_2/slider_fov_ads.value)
	
	if Input.is_action_just_pressed("control_utility"):
		RenderingServer.set_debug_generate_wireframes(true)
		#get_viewport().debug_draw = (get_viewport().debug_draw + 1) % 27
		match get_viewport().debug_draw:
			0:
				get_viewport().debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
			Viewport.DEBUG_DRAW_OVERDRAW:
				get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
			Viewport.DEBUG_DRAW_WIREFRAME:
				get_viewport().debug_draw = 0

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	pass

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		disconnect_self_as_server()
		get_tree().quit()

func _on_insert_interact_interacted_with(data : Dictionary) -> void:
	var player : CharacterBody3D = get_node(data.path)
	randomize()
	if player.faction == 0:
		var spawn = randi_range(0, map.insertion_points_pmc.size() - 1)
		player.position = map.insertion_points_pmc[spawn].global_position
		player.rotation = map.insertion_points_pmc[spawn].rotation
	if player.faction == 1:
		var spawn = randi_range(0,  map.insertion_points_cartel.size() - 1)
		player.position =  map.insertion_points_cartel[spawn].global_position
		player.rotation = map.insertion_points_cartel[spawn].rotation
	player.player_health = 100

@rpc("call_local")
func update_host_name(host_name : String):
	hostname = host_name
	$ReadyRoom/InsertRoom/HostLabel.text = "Host: " + host_name
	username = lineedit_username.text

func _on_button_refresh_pressed() -> void:
	refresh_server_list.emit()

func join_server(ip):
	if lineedit_username.text.is_empty():
		PopupSystem.new_popup(25, "Multiplayer Error", "You cannot have an empty username")
		return
	var error = enet_peer.create_client(ip, PORT)
	if error:
		PopupSystem.new_popup(25, "Multiplayer Error", "You can not connect to that server")
		return
	menu_main.hide()
	$CanvasLayer/menu_main/AudioStreamPlayer.stop()
	$CanvasLayer/menu_main/CasseteSound.stop()
	control_hud.show()
	multiplayer.multiplayer_peer = enet_peer
	in_game = true
	
func self_connected():
	check_if_game_info_is_valid.rpc_id(1, {"build_time": time_of_build, "author": author, "version": version})

func _on_server_browser_manager_ready_to_join_server(ip: Variant) -> void:
	join_server(ip)

@rpc("any_peer", "call_local")
func check_if_game_info_is_valid(data : Dictionary):
	if multiplayer.is_server():
		var build_data = {"build_time": time_of_build, "author": author, "version": version}
		if build_data != data:
			player_disconnected_from_server(multiplayer.get_remote_sender_id())
			kicked_from_server.rpc_id(multiplayer.get_remote_sender_id(), "Mismatched game version")
			await get_tree().create_timer(0.5).timeout
			enet_peer.disconnect_peer(multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_local")
func kicked_from_server(message : String):
	multiplayer.multiplayer_peer = null
	enet_peer = ENetMultiplayerPeer.new()
	control_hud.hide()
	menu_main.show()
	$CanvasLayer/menu_main/AudioStreamPlayer.play()
	$CanvasLayer/menu_main/CasseteSound.play()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$CanvasLayer/control_hud/TextChat/Display.text = ""
	for child in $Map.get_children():
		child.queue_free()
	PopupSystem.new_popup(5, "Kicked", message)

@rpc("any_peer", "call_local")
func update_score(data: Dictionary):
	if data.faction_to_add == 0:
		faction_points[0] += 1
	if data.faction_to_add == 1:
		faction_points[1] += 1
	#$CanvasLayer/control_hud/label_score.text = "   PMC " + str(faction_points[0]) + " | " + str(faction_points[1]) + " Cartel"
	$CanvasLayer/control_hud/score_ui/ColorRect/HBoxContainer/ScoreLabel.text = str(faction_points[0])
	$CanvasLayer/control_hud/score_ui/ColorRect2/HBoxContainer/ScoreLabel.text = str(faction_points[1])

@rpc("any_peer", "call_local")
func sync_score(score):
	if multiplayer.get_remote_sender_id() == 1:
		faction_points = score
		$CanvasLayer/control_hud/score_ui/ColorRect/HBoxContainer/ScoreLabel.text = str(faction_points[0])
		$CanvasLayer/control_hud/score_ui/ColorRect2/HBoxContainer/ScoreLabel.text = str(faction_points[1])

func _on_control_point_interacted(data: Dictionary) -> void:
	var player_interacted = get_node(data.path)
	var faction_to_add : int = 0
	if player_interacted.faction == 0:
		faction_to_add = 0
	if player_interacted.faction == 1:
		faction_to_add = 1
	update_score.rpc({"faction_to_add" : faction_to_add})
	var aud_player = AudioStreamPlayer.new()
	aud_player.stream = load("res://assets/sounds/ui/control_point_interact.mp3")
	add_child(aud_player)
	aud_player.play()
	await aud_player.finished
	aud_player.queue_free()

func _on_map_option_item_selected(index):
	map_index = index

func _on_button_pressed():
	get_tree().change_scene_to_file("res://assets_sp/scenes/menus/sp_mainmenu.tscn")
