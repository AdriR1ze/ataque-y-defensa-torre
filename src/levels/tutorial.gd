extends BaseLevel

@onready var player_spawn: Marker3D = $PlayerSpawner


func _ready() -> void:
	super()


func get_default_player_spawn() -> Vector3:
	return player_spawn.global_position
