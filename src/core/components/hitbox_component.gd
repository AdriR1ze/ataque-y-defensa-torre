extends Area3D
class_name HitboxComponent

signal hit_target(target: Node)

@export var damage := 1.0
@export var active := false
@export var hit_once := true

var _already_hit: Dictionary = {}


func _ready() -> void:
	monitoring = active
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not active or body == null:
		return

	if hit_once and _already_hit.has(body):
		return
	if hit_once:
		_already_hit[body] = true

	if body.has_method("take_damage"):
		body.take_damage(damage)
		hit_target.emit(body)


func activate(new_damage: float = -1.0) -> void:
	if new_damage >= 0.0:
		damage = new_damage
	_already_hit.clear()
	active = true
	monitoring = true


func deactivate() -> void:
	active = false
	monitoring = false


func set_damage(new_damage: float) -> void:
	damage = new_damage
