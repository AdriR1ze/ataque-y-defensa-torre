extends Node
class_name MovementComponent
@export var speed := 5.0
@export var gravity := 20.0

@onready var player: CharacterBody3D = get_parent()


func _physics_process(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0.0

	var input := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction := Vector3(input.x, 0.0, input.y)

	# Movimiento relativo a la orientación del Player
	direction = player.transform.basis * direction
	direction.y = 0.0
	direction = direction.normalized()

	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed

	player.move_and_slide()
