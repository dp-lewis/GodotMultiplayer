extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

var players := {}

var player_info := {
	"name": "Missing Name"
}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_game():		
	multiplayer.multiplayer_peer = %NetworkManager.create_game()
	players[1] = player_info
	player_connected.emit(1, player_info)

func join_game(address):
	multiplayer.multiplayer_peer = %NetworkManager.join_game(address)

func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)
	
@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

func _on_server_disconnected(): 
	multiplayer.multiplayer_peer = null

func _on_connection_failed():
	multiplayer.multiplayer_peer = null
	players = {}
	server_disconnected.emit()
