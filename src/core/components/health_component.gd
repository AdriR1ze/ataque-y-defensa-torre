extends Node
class_name HealthComponent

signal health_changed(current: float, max_health: float)
signal damaged(amount: float)
signal healed(amount: float)
signal died

@export var max_health := 100.0

var current_health: float
var is_dead := false


func _ready() -> void:
	current_health = max_health


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die()


func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)


func die() -> void:
	if is_dead:
		return
	current_health = 0.0
	_die()


func reset() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)


func _die() -> void:
	is_dead = true
	died.emit()
