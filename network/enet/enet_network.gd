extends Node

const PORT = 7000
const MAX_CONNECTIONS = 2

signal lobby_data_update(id, name)

func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		print(error)
	return peer

func join_game(location):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(location, PORT)
	if error:
		print(error)
	return peer

func list_lobbies():
	pass
