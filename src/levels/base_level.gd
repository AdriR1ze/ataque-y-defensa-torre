extends Node3D
class_name BaseLevel

signal level_completed

const WORLD_MARKER := preload("res://src/ui/world_marker.tscn")

const BASE_MARKER_TEXTURE := "res://assets/arrow_down.svg"
const SPAWNER_MARKER_TEXTURE := "res://assets/skull.svg"


func get_default_player_spawn():
	return Vector3(10, 10, 10)


func _ready() -> void:
	add_to_group("current_level")
	_spawn_indicators()
	var wave_manager := get_node_or_null("WaveManager") as WaveManager
	if wave_manager != null:
		wave_manager.level_completed.connect(_on_level_completed)


func _spawn_indicators() -> void:
	var base := get_tree().get_first_node_in_group("base")
	if base != null:
		_add_marker(base, BASE_MARKER_TEXTURE)

	for spawner in get_tree().get_nodes_in_group("spawner"):
		_add_marker(spawner, SPAWNER_MARKER_TEXTURE)


func _add_marker(parent: Node, texture_path: String) -> void:
	var marker := WORLD_MARKER.instantiate() as WorldMarker
	marker.texture_path = texture_path
	parent.add_child(marker)


func _on_level_completed() -> void:
	level_completed.emit()
