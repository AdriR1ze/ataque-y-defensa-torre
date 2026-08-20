extends Node
class_name WaveManager

signal level_completed
signal wave_started(wave_number: int)
signal wave_cleared

@export var enemies: Array[PackedScene] = [
	preload("res://src/gameplay/enemies/enemy.tscn"),
	preload("res://src/gameplay/enemies/enemy_fast.tscn"),
	preload("res://src/gameplay/enemies/enemy_tank.tscn")
]

@export var countdown_duration := 10.0
@export var max_waves := 10
@export var debug_mode := false
@export var base_enemies_per_wave := 5
@export var enemies_per_wave_increment := 2
@export var wave_reward := 100
@export var wave_reward_increment := 25
@export var boss_level := false

const WAVE_UI_SCENE := preload("res://src/ui/wave_ui.tscn")
const BOSS_SCENE := preload("res://src/gameplay/enemies/boss_enemy.tscn")

@onready var level_root: Node3D = get_parent()
@onready var level_spawner: Node3D = $"../Spawner"

var _wave_ui: WaveUI
var _wave_number := 0
var _running := false
var _total_waves := 0
var is_wave_active := false


func _ready() -> void:
	debug_mode = debug_mode or Debug.debug_enabled
	add_to_group("wave_manager")
	_wave_ui = WAVE_UI_SCENE.instantiate() as WaveUI
	add_child(_wave_ui)
	_run_wave_loop()


func stop() -> void:
	_running = false


func _run_wave_loop() -> void:
	_running = true
	var total_waves := 1 if debug_mode else max_waves
	_total_waves = total_waves
	var wave_number := 1
	while _running and is_inside_tree():
		_wave_number = wave_number
		Music.set_game_state(Music.State.PLANNING)
		_wave_ui.start_countdown(int(countdown_duration))
		await _wave_ui.finished
		if not _running or not is_inside_tree():
			return
		_spawn_wave(wave_number)
		await _wait_all_enemies_dead()
		if not _running or not is_inside_tree():
			return
		is_wave_active = false
		Economy.add_money(wave_reward + (wave_number - 1) * wave_reward_increment)
		wave_cleared.emit()

		if Debug.debug_enabled or wave_number >= total_waves:
			Music.set_game_state(Music.State.MENU)
			level_completed.emit()
			return

		wave_number += 1


func _spawn_wave(wave_number: int) -> void:
	is_wave_active = true
	wave_started.emit(wave_number)
	if boss_level and wave_number == _total_waves:
		Music.set_game_state(Music.State.BOSS)
	else:
		Music.set_game_state(Music.State.COMBAT)

	var amount := base_enemies_per_wave + (wave_number - 1) * enemies_per_wave_increment
	for i in range(amount):
		_spawn_enemy(_pick_enemy_scene(wave_number))
	if boss_level and wave_number == _total_waves:
		_spawn_enemy(BOSS_SCENE)


func _pick_enemy_scene(wave_number: int) -> PackedScene:
	var fast_chance := 0.0
	var tank_chance := 0.0
	if wave_number >= 2:
		fast_chance = 0.3 + wave_number * 0.02
	if wave_number >= 3:
		tank_chance = 0.1 + wave_number * 0.02

	var roll := randf()
	if roll < tank_chance:
		return enemies[2]
	if roll < tank_chance + fast_chance:
		return enemies[1]
	return enemies[0]


func _spawn_enemy(enemy_scene: PackedScene) -> void:
	var enemy := enemy_scene.instantiate() as Enemy

	level_root.add_child(enemy)

	var spawn_position := level_spawner.global_position + Vector3(
		randf_range(-5.0, 5.0),
		0.0,
		randf_range(-5.0, 5.0)
	)

	var routes := get_tree().get_nodes_in_group("enemy_routes")
	if not routes.is_empty():
		var route := routes.pick_random() as EnemyRoute
		enemy.set_route(route)
		spawn_position = route.get_start_position() + Vector3(
			randf_range(-2.0, 2.0),
			0.0,
			randf_range(-2.0, 2.0)
		)

	var navigation := get_tree().get_first_node_in_group("navigation") as NavigationGrid
	if navigation != null:
		spawn_position = navigation.snap_to_walkable_world(spawn_position)

	spawn_position.y = 1.0
	enemy.global_position = spawn_position


func _wait_all_enemies_dead() -> void:
	while _running and is_inside_tree():
		if get_tree().get_nodes_in_group("enemies").is_empty():
			return
		await get_tree().process_frame
