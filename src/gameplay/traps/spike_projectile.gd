extends CharacterBody3D
class_name SpikeProjectile

@export var speed := 20.0
@export var damage := 10.0

var _direction := Vector3.FORWARD
var _active := true


func setup(direction: Vector3) -> void:
	_direction = direction.normalized()
	var up := Vector3.UP
	if absf(_direction.dot(up)) > 0.99:
		up = Vector3.RIGHT
	global_transform = global_transform.looking_at(global_position + _direction, up)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	var collision := move_and_collide(_direction * speed * delta)
	if collision:
		var collider := collision.get_collider()
		if collider != null and collider.has_method("take_trap_damage"):
			collider.take_trap_damage(damage)
		queue_free()
