extends Node3D
class_name EnemyRoute


var _waypoints: Array[Marker3D] = []


func _ready() -> void:
	add_to_group("enemy_routes")
	_collect_waypoints()


func _collect_waypoints() -> void:
	_waypoints.clear()
	for child in get_children():
		if child is Marker3D:
			_waypoints.append(child)


func get_waypoints() -> PackedVector3Array:
	if _waypoints.is_empty():
		_collect_waypoints()
	var points := PackedVector3Array()
	for waypoint in _waypoints:
		points.append(waypoint.global_position)
	return points


func get_start_position() -> Vector3:
	var points := get_waypoints()
	if points.is_empty():
		return global_position
	return points[0]


func get_end_position() -> Vector3:
	var points := get_waypoints()
	if points.is_empty():
		return global_position
	return points[points.size() - 1]
