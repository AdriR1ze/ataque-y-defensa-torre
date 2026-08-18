extends BaseLevel

@onready var player_spawn = $PlayerSpawner
@export var nombre_level : String = "null"

func _ready() -> void:
	super._ready()
	player_spawn = player_spawn.global_position

func get_default_player_spawn():
	return player_spawn


func _to_string() -> String:
	return nombre_level
