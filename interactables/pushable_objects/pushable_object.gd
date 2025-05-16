extends RigidBody2D

class_name PushableObject

var requested_authority = false

@export var target_position := Vector2.INF

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not multiplayer.is_server():
		freeze = true
	
func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	
	if is_multiplayer_authority():
		target_position = global_position
	else: 
		global_position = HelperFunctions.ClientInterpolate(
			global_position,
			target_position,
			delta)

@rpc("any_peer", "call_remote", "reliable")
func request_authority(id) -> void: 
	set_pushable_owner.rpc(id)

@rpc("authority", "call_local", "reliable")
func set_pushable_owner(id) -> void:
	requested_authority = false
	set_multiplayer_authority(id)
	set_deferred("freeze", multiplayer.get_unique_id() != id)

func push(impulse, point) -> void: 
	if is_multiplayer_authority():
		apply_impulse(impulse, point)
	else: 
		if not requested_authority:
			request_authority.rpc_id(
				get_multiplayer_authority(), 
				multiplayer.get_unique_id())
			requested_authority = true
		
