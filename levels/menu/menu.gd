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
@export var steam_setup_panel:VBoxContainer
@export var steam_client_panel:VBoxContainer
@export var steam_lobby_player_list:ItemList
@export var steam_refresh_players_list_button:Button
@export var steam_lobby_panel:VBoxContainer
@export var steam_start_button:Button

var steam_lobbies:Array
var steam_lobby_id_selected:int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.connection_failed.connect(_on_connection_failure)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	steam_name_label.text = Steam.getPersonaName()
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_created.connect(_on_steam_lobby_created)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.lobby_joined.connect(_on_steam_lobby_joined)

	steam_lobby_itemlist.item_selected.connect(_on_steam_lobby_selected)

	Lobby.steam_lobby_refresh()



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
		
		var itemlist_id = steam_lobby_itemlist.add_item(name + " (ID: " + str(lobby_id) + ")")
		
		steam_lobby_itemlist.set_item_metadata(itemlist_id, lobby_id)  # store the Steam lobby ID



func _on_steam_lobby_created(connect: bool, lobby_id: int):
	if connect:
		print("Lobby created! Lobby ID: ", lobby_id)
		# You can now set metadata or wait for others to join
		Steam.setLobbyData(lobby_id, "name", "Godot Multi Player")
		steam_start_button.visible = true
		# steam_lobby_panel.visible = true
		steam_setup_panel.visible = false
	else:
		print("Failed to create lobby. Error code: ")

func _on_steam_lobby_selected(index):
	steam_lobby_id_selected = steam_lobby_itemlist.get_item_metadata(index)

func _on_steam_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	steam_setup_panel.visible = false
	steam_lobby_panel.visible = true

	print("Entered lobby: ", this_lobby_id)

	var member_count := Steam.getNumLobbyMembers(this_lobby_id)
	print("Lobby has ", member_count, " members:")

	for i in range(member_count):
		var member_steam_id := Steam.getLobbyMemberByIndex(this_lobby_id, i)
		var name := Steam.getFriendPersonaName(member_steam_id)
		print(" - ", name, " (Steam ID: ", member_steam_id, ")")
		steam_lobby_player_list.add_item(name + " (ID: " + str(member_steam_id) + ")", null, false)

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


func _on_steam_host_button_pressed() -> void:
	Lobby.steam_create_lobby()


func _on_steam_refresh_lobbies_pressed() -> void:
	Lobby.steam_lobby_refresh()


func _on_steam_join_button_pressed() -> void:
	print(steam_lobby_id_selected)
	if steam_lobby_id_selected == null:
		return

	Steam.joinLobby(steam_lobby_id_selected)	


func _on_steam_refresh_player_list_button_pressed() -> void:
	Steam.requestLobbyList()
