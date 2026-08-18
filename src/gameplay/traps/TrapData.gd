extends Resource
class_name TrapData


@export_category("Identity")
@export var id: int
@export var trap_name: String
@export_multiline var description: String
@export var icon: Texture2D

@export_category("Gameplay")
@export var cost: int = 0
@export var damage: float = 0.0
@export var cooldown: float = 0.0
@export var range: float = 0.0

@export_category("Scene")
@export var scene: PackedScene
