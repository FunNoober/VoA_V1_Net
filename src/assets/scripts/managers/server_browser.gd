extends Node

@export var server_list_request : HTTPRequest
@export var server_data_post : HTTPRequest
@export var server_list : VBoxContainer
@export var host_server_button : Button
@export var join_server_button : Button
@export var refresh_button : Button
@onready var SERVER_BROWSER_IP : String = ProjectSettings.get_setting("global/server_browser_ip", "http://127.0.0.1")
@onready var SERVER_BROWSER_SERVER : String = "http://" + SERVER_BROWSER_IP + ":8066/"

signal ready_to_join_server(ip)

var username : String
var serv_name : String
var map_name : String
var ip_address : String

const REFRESH_TEXT = "Refresh"
const REFRESHING_TEXT = "Refreshing"

var uid : String

var is_processing_request : bool = false

var udpConnected : bool = false
var udpClient : PacketPeerUDP = PacketPeerUDP.new()

var active_server : bool = false

func _ready() -> void:
	var err = udpClient.connect_to_host("192.168.1.78", 8067)
	
	server_list_request.request(SERVER_BROWSER_SERVER + "servers-list")
	refresh_button.text = REFRESHING_TEXT
	server_list_request.connect("request_completed", got_server_list)
	is_processing_request = true
	$AutoRefreshTimer.start()
	$ServerHeartbeat.start()

func got_server_list(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if get_parent().in_game == true: return
	if result != HTTPRequest.RESULT_SUCCESS:
		PopupSystem.new_popup(25, "Multiplayer Error", "Error fetching server list [Press enter to dismiss]")
		host_server_button.disabled = false
		join_server_button.disabled = false
		refresh_button.text = REFRESH_TEXT
		return
	process_server_list(body)
	is_processing_request = false
		
func process_server_list(body: PackedByteArray):
	for node in server_list.get_children():
		node.queue_free()
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var server_data = json.get_data()
	var server_card_prefab : PackedScene = load("res://assets/prefabs/ui/server_card.tscn")
	for server_key in server_data.servers:
		var server_card : HBoxContainer = server_card_prefab.instantiate()
		server_list.add_child(server_card)
		var server = server_data.servers[server_key]
		server_card.initialize(server.Host, server.Hash, server.ServerName, server.MapName)
		server_card.connect("join_server", join_server_pressed)
	host_server_button.disabled = false
	join_server_button.disabled = false
	refresh_button.text = REFRESH_TEXT
		
func join_server_pressed(hash):
	var request : HTTPRequest = HTTPRequest.new()
	add_child(request)
	request.request(SERVER_BROWSER_SERVER + "ip-from-hash", [], HTTPClient.METHOD_GET, hash)
	request.connect("request_completed", ip_from_hash)
	
func ip_from_hash(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	ready_to_join_server.emit(body.get_string_from_utf8())

func _on_game_hosted_server(playername : String, servername : String, mapname : String) -> void:
	username = playername
	serv_name = servername
	map_name = mapname
	var ip_request : HTTPRequest = HTTPRequest.new()
	add_child(ip_request)
	ip_request.request("https://api.ipify.org")
	ip_request.connect("request_completed", ip_got)
	
func ip_got(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	uid = str(str(Time.get_ticks_msec()) + username + serv_name + str(randf_range(0, 1024)) + str(Time.get_unix_time_from_system())).sha256_text()
	var contents = {"Ip": body.get_string_from_utf8(), "Host": username, "ServerName": serv_name, "MapName": map_name, "Uid": uid, "TimeSinceHeartbeat": 0}
	ip_address = body.get_string_from_utf8()
	var message = JSON.stringify(contents)
	server_data_post.request(SERVER_BROWSER_SERVER + "add-server", [], HTTPClient.METHOD_POST, message)
	udpClient.put_packet(uid.to_utf8_buffer())
	active_server = true

func _on_game_closed_server() -> void:
	var shutting_down : HTTPRequest = HTTPRequest.new()
	add_child(shutting_down)
	shutting_down.request(SERVER_BROWSER_SERVER + "close-server", [], HTTPClient.METHOD_POST, JSON.stringify({"Uid": uid}))
	active_server = false

func _on_game_refresh_server_list() -> void:
	server_list_request.request(SERVER_BROWSER_SERVER + "servers-list")
	host_server_button.disabled = true
	join_server_button.disabled = true
	refresh_button.text = REFRESHING_TEXT

func _on_auto_refresh_timer_timeout():
	if is_processing_request:
		return
	if active_server:
		return
	server_list_request.request(SERVER_BROWSER_SERVER + "servers-list")
	refresh_button.text = REFRESHING_TEXT
	is_processing_request = true

func _on_server_heartbeat_timeout():
	if active_server:
		udpClient.put_packet(uid.to_utf8_buffer())
