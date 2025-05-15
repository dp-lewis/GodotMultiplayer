extends Node2D

@export var bridge_sprite:Sprite2D
@export var collider:CollisionShape2D
@export var required_activators := 2
@export var locked_open := false
var current_activators := 0

func _on_multiplayer_synchronizer_delta_synchronized() -> void:
	set_bridge_properties()

func set_bridge_properties() -> void:
	bridge_sprite.visible = locked_open
	collider.set_deferred("disabled", !locked_open)

func activate(state) -> void:
	if not multiplayer.is_server():
		return
	
	if locked_open:
		return
		
	if state:
		current_activators += 1
	else: 
		current_activators -= 1

	if current_activators >= required_activators:
		locked_open = true
		set_bridge_properties()
