extends Node

var STEAM_APP_ID = 480	#Too Many Sheep: 2410820

signal lobby_data_update(id, name)

func _ready():
	OS.set_environment("SteamAppId", str(STEAM_APP_ID))
	OS.set_environment("SteamGameId", str(STEAM_APP_ID))
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)	

	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_created.connect(_on_steam_lobby_created)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.lobby_joined.connect(_on_steam_lobby_joined)

func _process(delta: float) -> void:
	Steam.run_callbacks()

func create_game():
	print("Creating Lobby")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 2)
	pass

func join_game(lobby_id):
	Steam.joinLobby(lobby_id)	

func list_lobbies():
	Steam.requestLobbyList()

func _on_lobby_match_list(lobbies: Array):
	print("Received ", lobbies.size(), " lobbies.")
	for lobby_id in lobbies:
		# Request data for each lobby (name, metadata, etc.)
		Steam.requestLobbyData(lobby_id)


func _on_lobby_data_update(success: bool, lobby_id: int, member_id: int):
	if success:
		var name = Steam.getLobbyData(lobby_id, "name")
		if name.is_empty():
			name = "Lobby " + str(lobby_id)
		
		lobby_data_update.emit(lobby_id, name)
		#var itemlist_id = steam_lobby_itemlist.add_item(name + " (ID: " + str(lobby_id) + ")")
		
		#steam_lobby_itemlist.set_item_metadata(itemlist_id, lobby_id)  # store the Steam lobby ID
	

func _lobby_refresh() -> void:
	print("Requestion Lobby Refresh")
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_CLOSE)
	Steam.requestLobbyList()	



func _on_steam_lobby_created(connect: bool, lobby_id: int):
	if connect:
		print("Lobby created! Lobby ID: ", lobby_id)
		# You can now set metadata or wait for others to join
		Steam.setLobbyData(lobby_id, "name", "Godot Multi Player")
		#steam_start_button.visible = true
		# steam_lobby_panel.visible = true
		#steam_setup_panel.visible = false
	else:
		print("Failed to create lobby. Error code: ")

func _on_steam_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	# steam_setup_panel.visible = false
	# steam_lobby_panel.visible = true

	print("Entered lobby: ", this_lobby_id)

	var member_count := Steam.getNumLobbyMembers(this_lobby_id)
	print("Lobby has ", member_count, " members:")

	for i in range(member_count):
		var member_steam_id := Steam.getLobbyMemberByIndex(this_lobby_id, i)
		var name := Steam.getFriendPersonaName(member_steam_id)
		print(" - ", name, " (Steam ID: ", member_steam_id, ")")
		# steam_lobby_player_list.add_item(name + " (ID: " + str(member_steam_id) + ")", null, false)
