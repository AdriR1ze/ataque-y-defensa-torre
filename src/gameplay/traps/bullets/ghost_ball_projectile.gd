extends CharacterBody3D
class_name GhostBallProjectile

@export var speed := 18.0
@export var damage := 12.0
@export var lifetime := 4.0
@export var hit_radius := 0.7

var _direction := Vector3.FORWARD
var _active := true
var _lifetime_timer := 0.0
var _hit_enemies: Dictionary = {}


func setup(direction: Vector3) -> void:
	_direction = direction.normalized()
	var up := Vector3.UP
	if absf(_direction.dot(up)) > 0.99:
		up = Vector3.RIGHT
	global_transform = global_transform.looking_at(global_position + _direction, up)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()
		return
	global_position += _direction * speed * delta
	_damage_enemies_in_radius()


func _damage_enemies_in_radius() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if _hit_enemies.has(enemy):
			continue
		var enemy3d := enemy as Node3D
		if enemy3d == null:
			continue
		if enemy3d.global_position.distance_to(global_position) > hit_radius:
			continue
		_hit_enemies[enemy] = true
		if enemy3d.has_method("take_trap_damage"):
			enemy3d.take_trap_damage(damage)
