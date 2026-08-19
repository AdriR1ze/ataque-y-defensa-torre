extends StaticBody3D


signal destroyed


func _ready() -> void:
	add_to_group("base")
	var health := get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.died.connect(func() -> void: destroyed.emit())


func take_damage(amount: float) -> void:
	var health := get_node_or_null("HealthComponent") as HealthComponent
	if health:
		health.take_damage(amount)
