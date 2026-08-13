extends Trap
class_name LaserTrap

@export var damage_per_second := 40.0
@export var beam_length := 8.0
@export var hitbox_radius := 0.45

@onready var beam: MeshInstance3D = $Beam
@onready var beam_glow: MeshInstance3D = $BeamGlow
@onready var damage_area: DamageAreaComponent = $DamageArea
@onready var collision_shape: CollisionShape3D = $DamageArea/CollisionShape3D


func _ready() -> void:
	_setup_beam()
	damage_area.set_damage_per_second(damage_per_second)


func _setup_beam() -> void:
	var half := beam_length * 0.5
	beam.scale = Vector3(1.0, beam_length, 1.0)
	beam.position = Vector3(0.0, half, 0.0)
	beam_glow.scale = Vector3(1.0, beam_length, 1.0)
	beam_glow.position = Vector3(0.0, half, 0.0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(hitbox_radius * 2.0, beam_length, hitbox_radius * 2.0)
	collision_shape.shape = shape
	collision_shape.position = Vector3(0.0, half, 0.0)


func set_active(new_active: bool) -> void:
	super(new_active)
	if damage_area:
		damage_area.active = new_active
		damage_area.monitoring = new_active
