extends Node

@export var ui:Control
@export var level_container:Node
@export var level_scene:PackedScene
@export var ip_line_edit:LineEdit
@export var status_label:Label

@export var not_connected_hbox:HBoxContainer
@export var host_hbox:HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.connection_failed.connect(_on_connection_failure)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	

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


func _on_steaam_lobby_refresh_button_pressed() -> void:
	print("Requesting Lobby Refresh")
	Steam.requestLobbyList()
