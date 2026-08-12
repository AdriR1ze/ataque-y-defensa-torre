extends StaticBody3D


func _ready() -> void:
	add_to_group("base")


func take_damage(amount: float) -> void:
	var health := get_node_or_null("HealthComponent") as HealthComponent
	if health:
		health.take_damage(amount)
