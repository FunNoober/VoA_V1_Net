extends HBoxContainer

var host : String = ""
var hash : String = ""
var map : String = ""
var server_name : String = ""

signal join_server(ip_adress)

func initialize(set_host, set_hash, set_name, set_map):
	host = set_host
	hash = set_hash
	server_name = set_name
	map = set_map
	$VBoxContainer/HostLabel.text = "Host: " + host
	$VBoxContainer/NameLabel.text = server_name
	$VBoxContainer/MapLabel.text = "Map: " + map

func _on_connect_button_pressed() -> void:
	join_server.emit(hash)
