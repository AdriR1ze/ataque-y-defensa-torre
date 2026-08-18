extends Node3D

@export var mouse_sensitivity := 0.002
@export var min_pitch := -89.0
@export var max_pitch := 89.0

@onready var player: CharacterBody3D = get_parent()
@onready var camera: Camera3D = $Camera3D

var pitch := 0.0


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotación horizontal
		player.rotate_y(-event.relative.x * mouse_sensitivity)

		# Rotación vertical
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(
			pitch,
			deg_to_rad(min_pitch),
			deg_to_rad(max_pitch)
		)

		camera.rotation.x = pitch

	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
