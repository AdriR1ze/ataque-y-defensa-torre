extends Node


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

@onready var entity_root: Node3D = %EntityRoot
@onready var effects_root: Node3D = %EffectsRoot
@onready var level_root: Node3D = %LevelRoot

@onready var trap_manager: TrapManager = $System/TrapManager
@onready var hud_layer: CanvasLayer = $HudLayer
@onready var hud_root: Control = $HudLayer/HudRoot


const TRAP_SELECTION_UI := preload("res://src/gameplay/traps/trap_ui/trap_selection_ui.tscn")
const PLAYER_HUD := preload("res://src/ui/player_hud.tscn")



var _selection_ui: TrapSelectionUI


func _ready() -> void:
	_init_player()
	_setup_player_hud()
	_show_trap_selection()


func _setup_player_hud() -> void:
	if player == null:
		return
	var hud := PLAYER_HUD.instantiate() as PlayerHUD
	hud_root.add_child(hud)
	hud.setup(player)


func _show_trap_selection() -> void:

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

	if _selection_ui != null:
		_selection_ui.queue_free()
		_selection_ui = null

	if player != null:
		player.process_mode = Node.PROCESS_MODE_PAUSABLE

	_capture_mouse.call_deferred()

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
		next_index = 0
	load_level(LEVELS[next_index])


func _on_level_completed() -> void:
	load_next_level()


func _deferred_load_level(
	level_scene: String
) -> void:

	if _current_level != null:

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

	_place_player_at_level_spawn()


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
