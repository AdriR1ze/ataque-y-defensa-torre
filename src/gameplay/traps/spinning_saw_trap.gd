extends Trap
class_name SpinningSawTrap

@export var rotation_speed := 6.0
@export var damage_per_second := 18.0

@onready var saw: Node3D = $Saw
@onready var damage_area: DamageAreaComponent = $DamageArea


func _physics_process(delta: float) -> void:
	if not active:
		return
	saw.rotate_object_local(Vector3.UP, rotation_speed * delta)


func set_active(new_active: bool) -> void:
	super(new_active)
	if damage_area:
		damage_area.active = new_active
		damage_area.monitoring = new_active
