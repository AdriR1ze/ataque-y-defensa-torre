extends Node3D
class_name BaseLevel

signal level_completed

const WORLD_MARKER := preload("res://src/ui/world_marker.tscn")

const BASE_MARKER_TEXTURE := "res://assets/arrow_down.svg"
const SPAWNER_MARKER_TEXTURE := "res://assets/skull.svg"

const TYRANT_ENVIRONMENT := preload("res://src/resources/environment_tyrant.tres")


func get_default_player_spawn() -> Vector3:
	var spawner := get_node_or_null("PlayerSpawner") as Node3D
	if spawner != null:
		return spawner.global_position
	return Vector3(10, 10, 10)



func _ready() -> void:
	add_to_group("current_level")
	_setup_lighting()
	_spawn_indicators()
	var wave_manager: Node = get_node_or_null("WaveManager")
	if wave_manager != null and wave_manager.has_signal("level_completed"):
		wave_manager.level_completed.connect(_on_level_completed)



func _setup_lighting() -> void:
	var custom_light := find_child("WorldEnvironment", false, false)
	if custom_light != null:
		return
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = TYRANT_ENVIRONMENT
	add_child(world_env)
	_add_directional_light(world_env)
	_add_omni_light()


func _add_directional_light(parent: Node) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "TyrantSun"
	sun.transform = Transform3D(
		Basis(
			Vector3(1, 0, 0),
			Vector3(0, 0.48830837, 0.8726713),
			Vector3(0, -0.8726713, 0.48830837)
		),
		Vector3(0, 6, 8)
	)
	sun.light_energy = 0.55
	sun.light_color = Color(0.65, 0.7, 0.85)
	sun.shadow_enabled = true
	sun.light_volumetric_fog_energy = 3.0
	parent.add_child(sun)


func _add_omni_light() -> void:
	var glow := OmniLight3D.new()
	glow.name = "TyrantGlow"
	glow.position = Vector3(0, 3.5, 0)
	glow.light_color = Color(1, 0.3, 0.32)
	glow.light_energy = 2.4
	glow.omni_range = 24.0
	add_child(glow)


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
