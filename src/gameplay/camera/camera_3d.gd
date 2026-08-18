extends Node3D

@export var mouse_sensitivity := 0.002

var pitch := 0.0

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Girar el cuerpo horizontalmente
		get_parent().rotate_y(-event.relative.x * mouse_sensitivity)

		# Girar la cabeza verticalmente
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-89.0), deg_to_rad(89.0))

		rotation.x = pitch

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
