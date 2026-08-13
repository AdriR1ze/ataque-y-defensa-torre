extends StaticBody3D
class_name GhostBallTrower

const PROJECTILE_SCENE := preload("res://src/gameplay/traps/ghost_ball_projectile.tscn")

@export var projectile_speed := 18.0
@export var projectile_damage := 12.0

@onready var muzzle: Node3D = $Muzzle


func _on_cooldown_timeout() -> void:
	_fire_forward()


func _fire_forward() -> void:
	if muzzle == null:
		return
	var projectile := PROJECTILE_SCENE.instantiate() as GhostBallProjectile
	get_parent().add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.setup(-muzzle.global_basis.z.normalized())
