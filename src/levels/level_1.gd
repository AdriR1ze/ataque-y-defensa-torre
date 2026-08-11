extends BaseLevel

@export var player_spawn : Vector3
@export var nombre_level : String = "null"
func get_default_player_spawn():
	return player_spawn
	
	
func _to_string() -> String:
	return nombre_level
