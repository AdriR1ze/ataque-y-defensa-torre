extends Node3D
class_name SwordWeapon

@export var damage := 25.0
@export var attack_duration := 0.3

@onready var area: Area3D = $Area3D
@onready var blade: MeshInstance3D = $Blade
@onready var debug_hitbox: MeshInstance3D = $Area3D/DebugHitbox

func _ready() -> void:
	if area == null:
		push_error("[Sword] No se encontro Area3D en $Area3D")
		return
	area.body_entered.connect(_on_area_body_entered)
	if debug_hitbox:
		debug_hitbox.visible = false

func attack() -> void:
	if blade:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.RED
		mat.emission = Color.RED
		mat.emission_energy_multiplier = 2.0
		blade.material_override = mat

	if debug_hitbox:
		debug_hitbox.visible = true

	area.monitoring = true
	await get_tree().create_timer(attack_duration).timeout
	area.monitoring = false

	if blade:
		blade.material_override = null

	if debug_hitbox:
		debug_hitbox.visible = false

func _on_area_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
