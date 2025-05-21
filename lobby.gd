extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

signal steam_lobby_list(lobbies:Array)
signal steam_lobby_data_update(success: bool, lobby_id: int, lobby_name: String)
signal steam_lobby_joined(this_lobby_id: int, member_count: int, members:Array)
signal steam_lobby_created(connected:bool, lobby_id:int, lobby_name:String)



const PORT = 7000
const MAX_CONNECTIONS = 2


var players := {}

var player_info := {
	"name": "Missing Name"
}

func _ready() -> void:
	
	# Steam specifics
	var STEAM_APP_ID = 480
	OS.set_environment("SteamAppId", str(STEAM_APP_ID))
	OS.set_environment("SteamGameId", str(STEAM_APP_ID))
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)
	
	Steam.lobby_match_list.connect(
		func(lobbies:Array):
			steam_lobby_list.emit(lobbies)
			for lobby_id in lobbies:
				Steam.requestLobbyData(lobby_id) 
	)
	
	Steam.lobby_data_update.connect(
		func(success: bool, lobby_id: int, _member_id: int):
			if success:
				var lobby_name = Steam.getLobbyData(lobby_id, "name")
				if lobby_name.is_empty():
					lobby_name = "Lobby " + str(lobby_id)
				steam_lobby_data_update.emit(success, lobby_id, lobby_name)
	)
	
	Steam.lobby_created.connect(
		func(status: int, lobby_id: int):
			var lobby_name = "My Godot Lobby"
			
			if status == 1:
				print("Lobby created! Lobby ID: ", lobby_id)
				Steam.setLobbyData(lobby_id, "name", lobby_name)
				create_steam_socket()
			else:
				print("Failed to create lobby. Error code: ")



			steam_lobby_created.emit(status, lobby_id, lobby_name)
	)
	
	Steam.lobby_joined.connect(
		func(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
			if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
				# lobby_id = this_lobby_id
				var id = Steam.getLobbyOwner(this_lobby_id)
				if id != Steam.getSteamID():
					connect_steam_socket(id)
					# register_player.rpc(player_name)
					# players[multiplayer.get_unique_id()] = player_name

				var member_count = Steam.getNumLobbyMembers(this_lobby_id)
				var members = []

				for i in range(member_count):
					var member_steam_id := Steam.getLobbyMemberByIndex(this_lobby_id, i)
					var persona_name := Steam.getFriendPersonaName(member_steam_id)
	
					members.append({
						"persona_name": persona_name,
						"member_steam_id": member_steam_id
					})
				
				steam_lobby_joined.emit(this_lobby_id, member_count, members)
	)

	# General network signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	
	if error:
		return error
		
	multiplayer.multiplayer_peer = peer
	
	players[1] = player_info
	
	player_connected.emit(1, player_info)
	
func join_game(address):
	var peer = ENetMultiplayerPeer.new()
	
	var error = peer.create_client(address, PORT)
	if error:
		return error
		
	multiplayer.multiplayer_peer = peer
	


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


func join_steam_lobby(lobby_id:int):
	Steam.joinLobby(lobby_id)



func create_steam_lobby():
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 2)
	
func create_steam_socket():
	var peer = SteamMultiplayerPeer.new()
	var error = peer.create_host(0)
	
	multiplayer.multiplayer_peer = peer
	players[1] = player_info	
	player_connected.emit(1, player_info)
	
	print("creating steam socket ", error)


func connect_steam_socket(steam_id):

	var peer = SteamMultiplayerPeer.new()
	var error = peer.create_client(steam_id, 0)
	multiplayer.set_multiplayer_peer(peer)

	print("Connecting to lobby %s" % steam_id)
	print("error code: ", error)
