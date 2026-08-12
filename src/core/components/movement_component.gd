extends Node
class_name MovementComponent

@export var speed := 5.0
@export var gravity := 20.0
@export var jump_force := 8.0

@onready var player: Player = get_parent()


func _physics_process(delta: float) -> void:
	if player.state == Player.PlayerState.DEAD:
		return

	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()

	player.move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0.0


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = jump_force
		player.set_state(Player.PlayerState.JUMPING)


func _handle_movement() -> void:
	var input := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction := Vector3(input.x, 0.0, input.y)

	direction = player.transform.basis * direction
	direction.y = 0.0

	if direction.length() > 0.0:
		direction = direction.normalized()

	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed

	if player.is_on_floor():
		if direction.length() > 0.0:
			player.set_state(Player.PlayerState.WALKING)
		else:
			player.set_state(Player.PlayerState.IDLE)
