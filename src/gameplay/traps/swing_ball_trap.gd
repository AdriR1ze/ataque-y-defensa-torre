extends Trap
class_name SwingBallTrap

@export var rotation_speed := 2.5
@export var arm_length := 3.0
@export var damage_per_second := 15.0
@export var knockback_force := 6.0

@onready var pivot: Node3D = $Pivot
@onready var arm: MeshInstance3D = $Pivot/Arm
@onready var ball: MeshInstance3D = $Pivot/Ball
@onready var damage_area: DamageAreaComponent = $Pivot/DamageArea


func _ready() -> void:
	_setup_arm()
	damage_area.set_damage_per_second(damage_per_second)
	damage_area.body_entered.connect(_on_ball_hit)


func _setup_arm() -> void:
	arm.scale.y = arm_length
	arm.position.y = arm_length * 0.5
	ball.position.y = arm_length
	damage_area.position.y = arm_length


func _physics_process(delta: float) -> void:
	if not active:
		return
	pivot.rotate_object_local(Vector3.RIGHT, rotation_speed * delta)


func _on_ball_hit(body: Node3D) -> void:
	if body != null and body.has_method("knock_back"):
		var dir := body.global_position - global_position
		body.knock_back(dir, knockback_force)


func set_active(new_active: bool) -> void:
	super(new_active)
	if damage_area:
		damage_area.active = new_active
		damage_area.monitoring = new_active
