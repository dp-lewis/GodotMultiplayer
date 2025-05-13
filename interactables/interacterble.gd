extends Area2D

signal interacted()

@rpc("any_peer", "call_local", "reliable")
func interact() -> void:
	if multiplayer.is_server(): #only called when executed on and acting as the server
		interacted.emit()
	
