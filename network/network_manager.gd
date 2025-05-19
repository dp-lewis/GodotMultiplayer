extends Node

@export var enet_network:Node
@export var steam_network:Node

var network_active = false
var active_network

signal lobby_data_update(id, name)

func set_up_network():
	if network_active:
		return
	
	active_network = enet_network
	network_active = true

func create_game():
	set_up_network()
	return active_network.create_game()

func join_game(address):
	set_up_network()
	return active_network.join_game(address)

func list_lobbies():
	set_up_network()
	active_network.list_lobbies()
	active_network.lobby_data_update.connect(
		func(id, name):
			lobby_data_update.emit(id,name)
	)
