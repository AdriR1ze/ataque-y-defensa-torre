extends CharacterBody3D

@export var speed: float = 40.0            # Velocidad inicial de disparo (m/s)
@export var gravity: float = 9.8           # Fuerza de gravedad
@export var max_fall_speed: float = 60.0
@export var stick_on_hit: bool = true       # Si se clava al chocar
@export var damage : float
var _stuck: bool = false

func _ready() -> void:
	# Velocidad inicial en la dirección "adelante" del nodo (-Z por defecto en Godot)
	velocity = -global_transform.basis.z * speed

func _physics_process(delta: float) -> void:
	if _stuck:
		return

	# Aplicar gravedad
	velocity.y -= gravity * delta
	velocity.y = max(velocity.y, -max_fall_speed)

	# Rotar la flecha para que apunte hacia donde se mueve (efecto de caída realista)
	if velocity.length() > 0.01:
		look_at(global_position + velocity, Vector3.UP)

	var collision := move_and_collide(velocity * delta)
	if collision:
		_on_hit(collision)

func _on_hit(collision: KinematicCollision3D) -> void:
	if stick_on_hit:
		_stuck = true
		velocity = Vector3.ZERO
		# Opcional: emparentar la flecha al objeto golpeado para que se mueva con él
		var collider = collision.get_collider()
		if collider and collider is Node3D:
			var global_pos = global_position
			var global_basis = global_transform.basis
			get_parent().remove_child(self)
			collider.add_child(self)
			global_position = global_pos
			global_transform.basis = global_basis
	else:
		queue_free()
