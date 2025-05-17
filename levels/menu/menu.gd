extends Node

@export var ui:Control
@export var level_container:Node
@export var level_scene:PackedScene
@export var ip_line_edit:LineEdit
@export var status_label:Label

@export var not_connected_hbox:VBoxContainer
@export var host_hbox:VBoxContainer

@export var steam_name_label:Label
@export var steam_refresh_lobbies_button:Button
@export var steam_lobby_itemlist:ItemList

var STEAM_APP_ID = 480

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.connection_failed.connect(_on_connection_failure)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

	#Too Many Sheep: 2410820
	OS.set_environment("SteamAppId", str(STEAM_APP_ID))
	OS.set_environment("SteamGameId", str(STEAM_APP_ID))
	
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)
	
	steam_name_label.text = Steam.getPersonaName()
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_data_update.connect(_on_lobby_data_update)

	
func _process(delta: float) -> void:
	Steam.run_callbacks()

func steam_create_lobby() -> void: 
	print("Creating Lobby")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 2)

func steam_lobby_refresh() -> void:
	print("Requestion Lobby Refresh")
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_CLOSE)
	Steam.requestLobbyList()	

func _on_lobby_match_list(lobbies: Array):
	steam_lobby_itemlist.clear()
	print("Received ", lobbies.size(), " lobbies.")
	for lobby_id in lobbies:
		# Request data for each lobby (name, metadata, etc.)
		Steam.requestLobbyData(lobby_id)

func _on_lobby_data_update(success: bool, lobby_id: int, member_id: int):
	if success:
		var name = Steam.getLobbyData(lobby_id, "name")
		if name.is_empty():
			name = "Lobby " + str(lobby_id)
		steam_lobby_itemlist.add_item(name + " (ID: " + str(lobby_id) + ")", null, false)


func _on_lobby_created(connect: bool, lobby_id: int):
	if connect:
		print("Lobby created! Lobby ID: ", lobby_id)
		# You can now set metadata or wait for others to join
		Steam.setLobbyData(lobby_id, "name", "My Godot Lobby")
	else:
		print("Failed to create lobby. Error code: ")


func _on_host_button_pressed() -> void:
	not_connected_hbox.hide()
	host_hbox.show()
	Lobby.create_game()
	status_label.text = "Hosting"

func _on_join_button_pressed() -> void:
	not_connected_hbox.hide()
	Lobby.join_game(ip_line_edit.text)
	status_label.text = "Connecting..."


func _on_play_button_pressed() -> void:
	hide_menu.rpc()
	change_level.call_deferred(level_scene)


func change_level(scene:PackedScene):
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.level_complete.disconnect(_on_level_complete)
		child.queue_free()
		
	var new_level = scene.instantiate()
	level_container.add_child(new_level)
	new_level.level_complete.connect(_on_level_complete)

func _on_connection_failure():
	not_connected_hbox.show()
	status_label.text = "Failed to connect"

func _on_connected_to_server():
	status_label.text = "Connected"

# RPC will be called on connected clients and on the host, but 
# can only be called by the host
@rpc("call_local", "authority", "reliable")
func hide_menu():
	ui.hide()


func _on_level_complete():
	call_deferred("change_level", level_scene)
