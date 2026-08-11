extends Node


var player : Player = null
var _current_level : BaseLevel

@onready var entity_root = %EntityRoot
@onready var effects_root = %EffectsRoot
@onready var level_root = %LevelRoot

@onready var level_1 = "res://src/levels/level_1.tscn"
func _ready() -> void:
	_init_player()
	load_level("res://src/levels/level_1.tscn")
	
	
func _init_player() -> void:
	var player_scene : PackedScene = ResourceLoader.load("res://src/gameplay/player/player.tscn")
	if player_scene == null:
		push_error("Error Opening the Player Scene",)
		return
	player = player_scene.instantiate() as Player
	if player == null:
		push_error("Loaded player doesnt work")
		return
	entity_root.add_child(player)

func load_level(level_scene : String) -> void:
	print(level_scene)
	_deferred_load_level.call_deferred(level_scene)
	
	
func _deferred_load_level(level_scene : String):
	if _current_level != null:
		_current_level.queue_free()
		_current_level = null
	await get_tree().process_frame
	var new_level : PackedScene = ResourceLoader.load(level_scene, "PackedScene") as PackedScene
	if new_level == null:
		push_error("Couldnt load new level")
		return
	_current_level = new_level.instantiate() as BaseLevel
	level_root.add_child(_current_level)
	if _current_level == null:
		push_error("Couldnt instantiate the current level")
		return
			
	await get_tree().process_frame
	_place_player_at_level_spawn()

func _place_player_at_level_spawn() -> void:
	if player == null:
		push_error("Cannot place player in level beacause is null")
		return
	if _current_level == null:
		push_error("Cannot place player in level because level is null")
		return
	player.global_position = _current_level.get_default_player_spawn()
