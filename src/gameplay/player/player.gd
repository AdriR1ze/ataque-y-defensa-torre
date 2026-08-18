extends CharacterBody3D
class_name Player

enum PlayerState {
	IDLE,
	WALKING,
	JUMPING,
	ATTACKING,
	DEAD
}
enum WeaponType {
	BOW,
	SWORD
}

signal died

var current_weapon := WeaponType.SWORD
var state: PlayerState = PlayerState.IDLE
var is_building := false

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	add_to_group("player")
	health_component.died.connect(_on_died)

func set_state(new_state: PlayerState) -> void:
	if state == new_state:
		return
	state = new_state

func take_damage(amount: float) -> void:
	if Debug.debug_enabled:
		return
	health_component.take_damage(amount)

func heal(amount: float) -> void:
	health_component.heal(amount)

func _on_died() -> void:
	set_state(PlayerState.DEAD)
	velocity = Vector3.ZERO
	died.emit()
