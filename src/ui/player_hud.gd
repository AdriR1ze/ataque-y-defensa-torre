extends Control
class_name PlayerHUD

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var money_label: Label = %MoneyLabel


func _ready() -> void:
	Economy.money_changed.connect(_on_money_changed)
	_update_money(Economy.money)


func setup(player: Player) -> void:
	var health := player.health_component
	health_bar.max_value = health.max_health
	health_bar.value = health.current_health
	_update_label(health.current_health, health.max_health)
	health.health_changed.connect(_on_health_changed)


func _on_health_changed(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	_update_label(current, max_health)


func _on_money_changed(current: int) -> void:
	_update_money(current)


func _update_money(current: int) -> void:
	money_label.text = "$%d" % current


func _update_label(current: float, max_health: float) -> void:
	health_label.text = "HP %d / %d" % [int(current), int(max_health)]
