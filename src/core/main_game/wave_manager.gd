extends Node
class_name WaveManager

@export var enemies: Array[PackedScene] = [
	preload("res://src/gameplay/enemies/enemy.tscn")
]

@export var wave_amount_enemies := 10

@onready var level_root: Node3D = get_parent()
@onready var level_spawner: Node3D = $"../Spawner"


func _ready() -> void:
	call_deferred("spawn_enemies", level_spawner)
	await get_tree().create_timer(4.0).timeout
	call_deferred("spawn_enemies", level_spawner)


func spawn_enemies(spawner) -> void:
	for i in range(wave_amount_enemies):
		_spawn_enemy(enemies.pick_random(), spawner)


func _spawn_enemy(enemy_scene: PackedScene, spawner) -> void:
	var enemy := enemy_scene.instantiate() as Enemy

	level_root.add_child(enemy)

	var spawn_position := level_spawner.global_position + Vector3(
		randf_range(-5.0, 5.0),
		0.0,
		randf_range(-5.0, 5.0)
	)

	var navigation := get_tree().get_first_node_in_group("navigation") as NavigationGrid
	if navigation != null:
		spawn_position = navigation.snap_to_walkable_world(spawn_position)

	spawn_position.y = 1.0
	enemy.global_position = spawn_position
