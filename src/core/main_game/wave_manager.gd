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
@export var money_per_enemy := -1
@export var wave_trap_unlocks: Dictionary = {}
@export var waves_data: Array = []
@export var unlock_trap_id := 0
@export var boss_level := false


const WAVE_UI_SCENE := preload("res://src/ui/wave_ui.tscn")
const ENEMY_SCENE := preload("res://src/gameplay/enemies/enemy.tscn")
const BOSS_SCENE := preload("res://src/gameplay/enemies/boss_enemy.tscn")
const BLUEPRINT_CUTSCENE_SCENE := preload("res://src/ui/blueprint_unlock_cutscene.tscn")
const SPIKES_TRAP_DATA := preload("res://src/gameplay/traps/spikes_trap/spikes_trap.tres")

@onready var level_root: Node3D = get_parent()
@onready var level_spawner: Node3D = $"../Spawner"

var _wave_ui: WaveUI
var _wave_number := 0
var _running := false
var _total_waves := 0
var is_wave_active := false
var _cutscene_enemy: Enemy = null


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
		var is_final := (Debug.debug_enabled or wave_number >= total_waves)
		await _wait_all_enemies_dead(is_final)
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

	# Check wave trap unlocks
	var str_w := str(wave_number)
	var unlock_id := 0
	if wave_trap_unlocks.has(str_w):
		unlock_id = int(wave_trap_unlocks[str_w])
	elif wave_trap_unlocks.has(wave_number):
		unlock_id = int(wave_trap_unlocks[wave_number])

	if unlock_id > 0:
		Progress.unlock_blueprint(unlock_id)

	var has_custom_wave: bool = wave_number <= waves_data.size() and waves_data[wave_number - 1] is Dictionary

	if has_custom_wave:
		var w_cfg: Dictionary = waves_data[wave_number - 1]
		var is_boss_w := bool(w_cfg.get("boss", 0) > 0)
		if is_boss_w or (boss_level and wave_number == _total_waves):
			Music.set_game_state(Music.State.BOSS)
		else:
			Music.set_game_state(Music.State.COMBAT)

		var n_count: int = int(w_cfg.get("normal", 0))
		var f_count: int = int(w_cfg.get("fast", 0))
		var t_count: int = int(w_cfg.get("tank", 0))
		var b_count: int = int(w_cfg.get("boss", 0))

		for i in range(n_count):
			_spawn_enemy(enemies[0])
		for i in range(f_count):
			_spawn_enemy(enemies[1])
		for i in range(t_count):
			_spawn_enemy(enemies[2])
		for i in range(b_count):
			_spawn_enemy(BOSS_SCENE)
	else:
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

	if money_per_enemy >= 0:
		enemy.reward = money_per_enemy

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


func get_level_unlock_trap_id() -> int:
	if unlock_trap_id > 0:
		return unlock_trap_id

	if level_root == null:
		return 0

	var scene_path := level_root.scene_file_path.to_lower()
	var level_name := level_root.name.to_lower()

	var regex := RegEx.new()
	regex.compile("level_?(\\d+)")
	var result := regex.search(scene_path)
	if result == null:
		result = regex.search(level_name)

	if result != null:
		var num := result.get_string(1).to_int()
		if TrapManager.ALL_TRAPS.has(num):
			return num

	return 0


func _should_play_level_unlock() -> bool:
	var trap_id := get_level_unlock_trap_id()
	if trap_id <= 0:
		return false
	return not Progress.has_blueprint(trap_id)


func should_intercept_enemy_death(enemy: Enemy) -> bool:
	if not _should_play_level_unlock():
		return false
	var is_final := (Debug.debug_enabled or _wave_number >= _total_waves)
	if not is_final:
		return false

	var active_enemies := get_tree().get_nodes_in_group("enemies")
	var alive_count := 0
	for e in active_enemies:
		if is_instance_valid(e) and not e.is_cinematic_death:
			alive_count += 1

	if alive_count <= 1:
		_cutscene_enemy = enemy
		return true

	return false


func _wait_all_enemies_dead(is_final_wave: bool = false) -> void:
	while _running and is_inside_tree():
		if get_tree().get_nodes_in_group("enemies").is_empty():
			if is_final_wave and _should_play_level_unlock():
				var trap_id := get_level_unlock_trap_id()
				if _cutscene_enemy != null and is_instance_valid(_cutscene_enemy):
					await _execute_blueprint_cutscene(_cutscene_enemy)
					_cutscene_enemy = null
				elif not Progress.has_blueprint(trap_id):
					await _execute_fallback_cutscene(level_spawner.global_position if level_spawner != null else Vector3.ZERO)
			return

		await get_tree().process_frame


func _execute_blueprint_cutscene(enemy: Enemy) -> void:
	var trap_id := get_level_unlock_trap_id()
	var trap_data := TrapManager.ALL_TRAPS.get(trap_id) as TrapData

	var player := get_tree().get_first_node_in_group("player") as Player
	var cutscene: CanvasLayer = BLUEPRINT_CUTSCENE_SCENE.instantiate() as CanvasLayer
	get_tree().current_scene.add_child(cutscene)
	if cutscene.has_method("play"):
		cutscene.play(enemy, player, trap_data)
	if cutscene.has_signal("cutscene_finished"):
		await cutscene.cutscene_finished
	if is_instance_valid(enemy):
		await enemy.finish_cinematic_death()


func _execute_fallback_cutscene(fallback_pos: Vector3) -> void:
	var trap_id := get_level_unlock_trap_id()
	var trap_data := TrapManager.ALL_TRAPS.get(trap_id) as TrapData

	var player := get_tree().get_first_node_in_group("player") as Player
	var dummy_enemy := Enemy.new()
	level_root.add_child(dummy_enemy)
	dummy_enemy.is_cutscene_target = true
	dummy_enemy.set_physics_process(false)
	dummy_enemy.set_state(Enemy.EnemyState.DEAD)
	if dummy_enemy.is_in_group("enemies"):
		dummy_enemy.remove_from_group("enemies")

	if fallback_pos != Vector3.ZERO:
		dummy_enemy.global_position = fallback_pos
	elif player != null and is_instance_valid(player):
		dummy_enemy.global_position = player.global_position + (-player.global_transform.basis.z * 3.5)
	dummy_enemy.global_position.y = 1.0

	var cutscene: CanvasLayer = BLUEPRINT_CUTSCENE_SCENE.instantiate() as CanvasLayer
	get_tree().current_scene.add_child(cutscene)
	if cutscene.has_method("play"):
		cutscene.play(dummy_enemy, player, trap_data)
	if cutscene.has_signal("cutscene_finished"):
		await cutscene.cutscene_finished
	if is_instance_valid(dummy_enemy):
		dummy_enemy.queue_free()
