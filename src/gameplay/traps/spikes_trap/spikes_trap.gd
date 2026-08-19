extends Trap
class_name SpikesTrap

@export var damage := 25.0

var _base_damage_per_second := 10.0
var _base_area_scale := 1.0

@onready var damage_area: DamageAreaComponent = $DamageArea
@onready var collision_shape: CollisionShape3D = $DamageArea/CollisionShape3D
@onready var spike_nodes: Array = [$Spike1, $Spike2, $Spike3, $Spike4]


func _ready() -> void:
	_base_damage_per_second = damage_area.damage_per_second
	_base_area_scale = collision_shape.scale.x


func _on_upgraded(effect: Dictionary) -> void:
	if effect.has("tint"):
		_apply_tint(effect["tint"])
	_apply_stats()


func _apply_stats() -> void:
	damage_area.set_damage_per_second(_base_damage_per_second * damage_multiplier)
	collision_shape.scale = Vector3.ONE * (_base_area_scale * area_multiplier)


func _apply_tint(color: Color) -> void:
	for spike in spike_nodes:
		if spike is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.emission = color
			mat.emission_energy_multiplier = 0.5
			spike.material_override = mat
