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
	steam_lobby_itemlist.item_selected.connect(_on_steam_lobby_selected)

func _on_steam_lobby_selected(index):
	steam_lobby_id_selected = steam_lobby_itemlist.get_item_metadata(index)

func _on_host_button_pressed() -> void:
	not_connected_hbox.hide()
	host_hbox.show()
	%Lobby.create_game()
	status_label.text = "Hosting"

func _on_join_button_pressed() -> void:
	not_connected_hbox.hide()
	%Lobby.join_game(ip_line_edit.text)
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
	%Lobby.steam_create_lobby()


func _on_steam_refresh_lobbies_pressed() -> void:
	%Lobby.steam_lobby_refresh()


func _on_steam_join_button_pressed() -> void:
	print(steam_lobby_id_selected)
	if steam_lobby_id_selected == null:
		return
