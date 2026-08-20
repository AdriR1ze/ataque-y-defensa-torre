extends Trap
class_name SpikesTrap

@export var damage := 25.0

@onready var damage_area: DamageAreaComponent = $DamageArea
@onready var collision_shape: CollisionShape3D = $DamageArea/CollisionShape3D
