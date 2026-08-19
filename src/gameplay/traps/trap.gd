extends Node3D
class_name Trap

enum SurfaceOrientation {
	ANY,
	FLOOR,
	WALL,
	CEILING
}

@export var display_name := "Trampa"
@export var snap_rotation_degrees := 90.0
@export var allow_free_rotation := false
@export var min_normal_dot := 0.9
@export var surface_orientation := SurfaceOrientation.ANY
@export var footprint_radius := 0.5

var active := true
var cost := 0
var trap_id := 0
var damage_multiplier := 1.0
var area_multiplier := 1.0
var upgrade_levels := [0, 0]


func set_active(new_active: bool) -> void:
	active = new_active


func apply_upgrade(effect: Dictionary) -> void:
	if effect.has("damage_mult"):
		damage_multiplier *= effect["damage_mult"]
	if effect.has("area_mult"):
		area_multiplier *= effect["area_mult"]
	_on_upgraded(effect)


func _on_upgraded(_effect: Dictionary) -> void:
	pass


func is_surface_valid(normal: Vector3) -> bool:
	match surface_orientation:
		SurfaceOrientation.FLOOR:
			return normal.dot(Vector3.UP) >= min_normal_dot
		SurfaceOrientation.CEILING:
			return normal.dot(Vector3.DOWN) >= min_normal_dot
		SurfaceOrientation.WALL:
			return absf(normal.dot(Vector3.UP)) <= 1.0 - min_normal_dot
		SurfaceOrientation.ANY:
			return true
	return false
