extends Trap
class_name SpikeLauncherTrap

const PROJECTILE_SCENE := preload("res://src/gameplay/traps/spike_projectile.tscn")

@export var fire_interval := 1.5
@export var range := 20.0
@export var firing_cone_degrees := 60.0
@export var projectile_speed := 20.0
@export var projectile_damage := 10.0

@onready var muzzle: Node3D = $Muzzle

var _cooldown := 0.0


func _physics_process(delta: float) -> void:
	if not active:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := _find_target_enemy()
	if target == null:
		return
	_cooldown = fire_interval
	_fire_at(target)


func _find_target_enemy() -> Node3D:
	var forward := global_basis.y.normalized()
	var best: Node3D = null
	var best_score := -1.0
	var cone_threshold := cos(deg_to_rad(firing_cone_degrees) * 0.5)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null:
			continue
		var enemy3d := enemy as Node3D
		if enemy3d == null:
			continue
		var offset := enemy3d.global_position - global_position
		var distance := offset.length()
		if distance > range or distance < 0.001:
			continue
		var alignment := offset.normalized().dot(forward)
		if alignment < cone_threshold:
			continue
		var score := alignment / maxf(distance, 0.1)
		if score > best_score:
			best = enemy3d
			best_score = score
	return best


func _fire_at(target: Node3D) -> void:
	if muzzle == null:
		return
	var projectile := PROJECTILE_SCENE.instantiate() as SpikeProjectile
	get_parent().add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.setup((target.global_position - muzzle.global_position).normalized())
