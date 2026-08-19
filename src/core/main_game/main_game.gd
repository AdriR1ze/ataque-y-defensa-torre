extends Node


enum GameState {
	PREPARING,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}


const INITIAL_MONEY := 100


var player: Player = null
var _current_level: BaseLevel

const LEVELS := [
	"res://src/levels/level_1.tscn",
	"res://src/levels/level_2.tscn",
	"res://src/levels/level_3.tscn",
	"res://src/levels/level_4.tscn",
	"res://src/levels/level_5.tscn",
	"res://src/levels/level_6.tscn",
	"res://src/levels/level_7.tscn",
	"res://src/levels/level_8.tscn",
	"res://src/levels/level_9.tscn",
	"res://src/levels/level_10.tscn"
]

var _current_level_index := 0
var _state := GameState.PREPARING

@onready var entity_root: Node3D = %EntityRoot
@onready var effects_root: Node3D = %EffectsRoot
@onready var level_root: Node3D = %LevelRoot

@onready var trap_manager: TrapManager = $System/TrapManager
@onready var hud_layer: CanvasLayer = $HudLayer
@onready var hud_root: Control = $HudLayer/HudRoot
@onready var pause_root: Control = %PauseRoot
@onready var transition_root: Control = %TransitionRoot


const TRAP_SELECTION_UI := preload("res://src/gameplay/traps/trap_ui/trap_selection_ui.tscn")
const PLAYER_HUD := preload("res://src/ui/player_hud.tscn")
const PAUSE_MENU := preload("res://src/ui/pause_menu.tscn")
const END_SCREEN := preload("res://src/ui/end_screen.tscn")

const MAIN_MENU_SCENE := "res://src/ui/main_menu.tscn"


var _selection_ui: TrapSelectionUI
var _pause_menu: PauseMenu
var _end_screen: EndScreen
var _build_hud: BuildHUD


func _ready() -> void:
	_init_player()
	_setup_player_hud()
	_setup_build_hud()
	_setup_pause_menu()
	_setup_end_screen()
	_show_trap_selection()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if _state == GameState.PLAYING:
			_pause_game()
		elif _state == GameState.PAUSED:
			_resume_game()


func _setup_player_hud() -> void:
	if player == null:
		return
	var hud := PLAYER_HUD.instantiate() as PlayerHUD
	hud_root.add_child(hud)
	hud.setup(player)


func _setup_build_hud() -> void:
	_build_hud = BuildHUD.new()
	hud_root.add_child(_build_hud)
	_build_hud.setup(trap_manager)


func _setup_pause_menu() -> void:
	_pause_menu = PAUSE_MENU.instantiate() as PauseMenu
	pause_root.add_child(_pause_menu)
	_pause_menu.resume_pressed.connect(_resume_game)
	_pause_menu.restart_pressed.connect(_restart_level)
	_pause_menu.main_menu_pressed.connect(_go_to_main_menu)
	_pause_menu.quit_pressed.connect(func() -> void: get_tree().quit())


func _setup_end_screen() -> void:
	_end_screen = END_SCREEN.instantiate() as EndScreen
	transition_root.add_child(_end_screen)
	_end_screen.restart_pressed.connect(_restart_level)
	_end_screen.main_menu_pressed.connect(_go_to_main_menu)


func _show_trap_selection() -> void:
	_state = GameState.PREPARING

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED

	_selection_ui = TRAP_SELECTION_UI.instantiate() as TrapSelectionUI

	if _selection_ui == null:
		push_error("Could not instantiate TrapSelectionUI")
		return

	_selection_ui.setup(trap_manager)

	_selection_ui.selection_confirmed.connect(
		_on_trap_selection_confirmed
	)

	hud_root.add_child(_selection_ui)


func _on_trap_selection_confirmed(
	selection: Dictionary
) -> void:

	trap_manager.apply_selection(selection)

	_grant_initial_money()

	if _selection_ui != null:
		_selection_ui.queue_free()
		_selection_ui = null

	if player != null:
		player.process_mode = Node.PROCESS_MODE_PAUSABLE

	_capture_mouse.call_deferred()

	_state = GameState.PLAYING

	load_level(LEVELS[0])


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _init_player() -> void:

	var player_scene: PackedScene = ResourceLoader.load(
		"res://src/gameplay/player/player.tscn"
	)

	if player_scene == null:
		push_error("Error opening the Player Scene")
		return

	player = player_scene.instantiate() as Player

	if player == null:
		push_error("Loaded player doesn't work")
		return

	player.died.connect(_on_player_died)

	entity_root.add_child(player)


func load_level(level_scene: String) -> void:
	print(level_scene)
	_current_level_index = LEVELS.find(level_scene)
	_deferred_load_level.call_deferred(
		level_scene
	)


func load_next_level() -> void:
	var next_index := _current_level_index + 1
	if next_index >= LEVELS.size():
		_on_victory()
		return
	load_level(LEVELS[next_index])


func _on_level_completed() -> void:
	if _state != GameState.PLAYING:
		return
	_clear_traps()
	_grant_initial_money()
	load_next_level()


func _deferred_load_level(
	level_scene: String
) -> void:

	if _current_level != null:
		_stop_current_level()
		_current_level.queue_free()
		_current_level = null

	await get_tree().process_frame

	var new_level: PackedScene = ResourceLoader.load(
		level_scene,
		"PackedScene"
	) as PackedScene

	if new_level == null:
		push_error("Couldn't load new level")
		return

	_current_level = new_level.instantiate() as BaseLevel

	if _current_level == null:
		push_error("Couldn't instantiate the current level")
		return

	_current_level.level_completed.connect(_on_level_completed)

	level_root.add_child(_current_level)

	await get_tree().process_frame

	_connect_base_destroyed()

	_place_player_at_level_spawn()


func _connect_base_destroyed() -> void:
	var base := get_tree().get_first_node_in_group("base")
	if base == null:
		return
	if not base.has_signal("destroyed"):
		return
	if base.is_connected("destroyed", _on_base_destroyed):
		return
	base.connect("destroyed", _on_base_destroyed)


func _stop_current_level() -> void:
	if _current_level == null:
		return
	var wave_manager := _current_level.get_node_or_null("WaveManager") as WaveManager
	if wave_manager != null:
		wave_manager.stop()


func _place_player_at_level_spawn() -> void:

	if player == null:
		push_error(
			"Cannot place player in level because player is null"
		)
		return

	if _current_level == null:
		push_error(
			"Cannot place player in level because level is null"
		)
		return

	player.global_position = (
		_current_level.get_default_player_spawn()
	)


func _pause_game() -> void:
	_state = GameState.PAUSED
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pause_menu.visible = true


func _resume_game() -> void:
	_state = GameState.PLAYING
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_pause_menu.visible = false


func _on_player_died() -> void:
	_trigger_defeat("Has muerto")


func _on_base_destroyed() -> void:
	_trigger_defeat("La torre fue destruida")


func _trigger_defeat(message: String) -> void:
	if _state == GameState.GAME_OVER or _state == GameState.VICTORY:
		return
	_state = GameState.GAME_OVER
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_end_screen.setup(false, message)


func _on_victory() -> void:
	if _state == GameState.GAME_OVER or _state == GameState.VICTORY:
		return
	_state = GameState.VICTORY
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_end_screen.setup(true, "Completaste todos los niveles")


func _restart_level() -> void:
	_state = GameState.PLAYING
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_pause_menu.visible = false
	_end_screen.visible = false

	_stop_current_level()
	_clear_run_state()
	_reset_player()
	_grant_initial_money()

	load_level(LEVELS[_current_level_index])


func _go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _clear_run_state() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	_clear_traps()


func _clear_traps() -> void:
	for trap in get_tree().get_nodes_in_group("traps"):
		trap.queue_free()


func _grant_initial_money() -> void:
	Economy.reset()
	Economy.add_money(INITIAL_MONEY)


func _reset_player() -> void:
	if player == null:
		return
	player.health_component.reset()
	player.set_state(Player.PlayerState.IDLE)
	player.velocity = Vector3.ZERO
