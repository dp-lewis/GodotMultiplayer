extends CharacterBody2D

@export var player_sprite:AnimatedSprite2D
@export var player_camera:PackedScene

@export var player_finder:Node2D

@export var camera_height := -132.0

@export var movement_speed := 300
@export var gravity := 30
@export var jump_strength := 600
@export var max_jumps := 3
@export var push_force := 10.0

@onready var initial_sprite_scale := player_sprite.scale

@export var target_position := Vector2.INF

var owner_id := 1
var jump_count := 0
var camera_instance

var state = PlayerStates.IDLE

var current_interactable:Area2D

enum PlayerStates {
	IDLE,
	WALKING,
	JUMP_STARTED,
	JUMPING,
	DOUBLE_JUMPING,
	FALLING
}

func _enter_tree() -> void:
	owner_id = name.to_int()
	set_multiplayer_authority(owner_id)
	
	if owner_id != multiplayer.get_unique_id():
		return
		
	set_up_camera()
	
func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null:
		return

	if owner_id != multiplayer.get_unique_id():
		global_position = HelperFunctions.ClientInterpolate(
			global_position,
			target_position,
			delta
		)
		return
	update_camera_pos()

func _physics_process(_delta: float) -> void:
	if owner_id != multiplayer.get_unique_id():
		return	
	var horizontal_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	velocity.x = horizontal_input * movement_speed
	velocity.y += gravity

	handle_movement_state()
	
	if Input.is_action_just_pressed("interact"):
		if current_interactable:
			current_interactable.interact.rpc_id(1)
		
	move_and_slide()
	target_position = global_position
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var pushable = collision.get_collider() as PushableObject
		if pushable == null:
			continue
			
		var point = collision.get_position()
			
		pushable.push(-collision.get_normal() * push_force, point - pushable.global_position)
	
	face_movement_direction(horizontal_input)

func handle_movement_state():
	# Decide State
	if Input.is_action_just_pressed("jump") and is_on_floor():
		state = PlayerStates.JUMP_STARTED
	elif is_on_floor() and is_zero_approx(velocity.x):
		state = PlayerStates.IDLE
	elif not is_zero_approx(velocity.x) and is_on_floor():
		state = PlayerStates.WALKING
	else:
		state = PlayerStates.JUMPING
		
	if velocity.y > 0.0 and not is_on_floor():
		if Input.is_action_just_pressed("jump"):
			state = PlayerStates.DOUBLE_JUMPING
		else:
			state = PlayerStates.FALLING
		
	# Processing state
	match state:
		PlayerStates.IDLE: 
			player_sprite.play("idle")
			jump_count = 0
		PlayerStates.JUMP_STARTED:
			player_sprite.play("jump_start")
			jump_count += 1
			velocity.y = -jump_strength
		PlayerStates.DOUBLE_JUMPING:
			player_sprite.play("double_jump_start")
			jump_count += 1
			if jump_count <= max_jumps:
				velocity.y = -jump_strength
		PlayerStates.WALKING:
			player_sprite.play("walk")
			jump_count = 0
		PlayerStates.FALLING:
			player_sprite.play("fall")

	# Jump cancelling
	if Input.is_action_just_released("jump") and velocity.y < 0.0: 
		velocity.y = 0.0

func face_movement_direction(horizontal_input):
	if not is_zero_approx(horizontal_input):
		if horizontal_input < 0:
			player_sprite.scale = Vector2(-initial_sprite_scale.x, initial_sprite_scale.y)
		else:
			player_sprite.scale = initial_sprite_scale	


func _on_animated_sprite_2d_animation_finished() -> void:
	if state == PlayerStates.JUMPING:
		player_sprite.play("jump")

func set_up_camera():
	camera_instance = player_camera.instantiate()
	camera_instance.global_position.y = camera_height
	get_parent().add_child.call_deferred(camera_instance)


func update_camera_pos():
	camera_instance.global_position.x = global_position.x


func _on_area_2d_area_entered(area: Area2D) -> void:
	current_interactable = area


func _on_area_2d_area_exited(area: Area2D) -> void:
	if current_interactable == area:
		current_interactable = null


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	player_finder.visible = false


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	player_finder.visible = true
