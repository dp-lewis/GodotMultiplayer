extends Node2D

class_name KeyDoor

signal all_players_finished()

@export var is_open := false

@export var door_open:Sprite2D
@export var door_closed:Sprite2D

@export var exit_area:Area2D

var finished_players := 0

func update_properties() -> void: 
	door_open.visible = is_open
	door_closed.visible = !is_open


# The use of the .is_server seems to be linked to when 
# you want to sync variables.
# if it's a synced variable, ensure it's the server
# that is setting it, then hook it up to the 
# delta syncroniser to update all the clients

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not multiplayer.is_server():
		return

	if is_open:
		return

	area.get_owner().queue_free()
	is_open = true
	exit_area.monitoring = true
	update_properties()


func _on_multiplayer_synchronizer_delta_synchronized() -> void:
	update_properties()


func _on_exit_area_body_entered(body: Node2D) -> void:
	finished_players += 1
	body.queue_free()
	
	if finished_players > len(multiplayer.get_peers()):
		all_players_finished.emit()
