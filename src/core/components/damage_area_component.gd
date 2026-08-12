extends Area3D
class_name DamageAreaComponent

@export var damage_per_second := 10.0
@export var tick_interval := 0.5
@export var active := true

var _bodies: Dictionary = {}
var _tick_timer := 0.0


func _ready() -> void:
	monitoring = active
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_tick_timer -= delta
	if _tick_timer > 0.0:
		return
	_tick_timer = tick_interval
	for body in _bodies.keys():
		if not is_instance_valid(body):
			_bodies.erase(body)
			continue
		if body.has_method("take_trap_damage"):
			body.take_trap_damage(damage_per_second * tick_interval)
		elif body.has_method("take_damage"):
			body.take_damage(damage_per_second * tick_interval)
		else:
			_bodies.erase(body)


func _on_body_entered(body: Node3D) -> void:
	if not active or body == null:
		return
	_bodies[body] = true


func _on_body_exited(body: Node3D) -> void:
	_bodies.erase(body)


func activate() -> void:
	active = true
	monitoring = true


func deactivate() -> void:
	active = false
	monitoring = false


func set_damage_per_second(new_damage: float) -> void:
	damage_per_second = new_damage
