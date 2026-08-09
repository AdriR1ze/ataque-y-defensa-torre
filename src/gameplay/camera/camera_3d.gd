```gdscriptextends CharacterBody3D

@export_category("Movement")
@export var speed: float = 5.0
@export var acceleration: float = 10.0
@export var gravity: float = 20.0

@export_category("Camera")
@export var mouse_sensitivity: float = 0.002
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

@onready var camera: Camera3D = $Camera3D

var pitch: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotación horizontal del jugador
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Rotación vertical de la cámara
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(
			pitch,
			deg_to_rad(min_pitch),
			deg_to_rad(max_pitch)
		)

		camera.rotation.x = pitch


	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_apply_gravity(delta)

	move_and_slide()


func _handle_movement(delta: float) -> void:
	var input := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction := (
		transform.basis * Vector3(
			input.x,
			0.0,
			input.y
		)
	).normalized()

	var target_velocity := direction * speed

	velocity.x = move_toward(
		velocity.x,
		target_velocity.x,
		acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		target_velocity.z,
		acceleration * delta
	)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
