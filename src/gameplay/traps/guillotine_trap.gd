extends Trap
class_name GuillotineTrap

@export var cycle_time := 2.5
@export var slam_time := 0.2
@export var retract_time := 0.8
@export var blade_length := 4.0
@export var damage := 50.0

var _timer := 0.0
var _blade_tween: Tween

@onready var blade: Node3D = $Blade
@onready var rail1: MeshInstance3D = $Rail1
@onready var rail2: MeshInstance3D = $Rail2
@onready var damage_area: DamageAreaComponent = $DamageArea


func _ready() -> void:
	damage_area.active = false
	damage_area.monitoring = true
	damage_area.set_damage_per_second(0.0)
	rail1.scale.y = blade_length
	rail1.position.y = blade_length * 0.5
	rail2.scale.y = blade_length
	rail2.position.y = blade_length * 0.5
	var col := damage_area.get_node("CollisionShape3D") as CollisionShape3D
	col.position.y = blade_length


func _physics_process(delta: float) -> void:
	if not active:
		return
	_timer += delta
	if _timer >= cycle_time:
		_timer = 0.0
		_slam()


func _slam() -> void:
	if _blade_tween:
		_blade_tween.kill()
	_blade_tween = create_tween()
	_blade_tween.tween_property(blade, "position:y", blade_length, slam_time)
	_blade_tween.tween_callback(_apply_slam_damage)
	_blade_tween.tween_interval(0.15)
	_blade_tween.tween_property(blade, "position:y", 0.0, retract_time)


func _apply_slam_damage() -> void:
	for body in damage_area.get_overlapping_bodies():
		if body != null and body.has_method("take_trap_damage"):
			body.take_trap_damage(damage)


func set_active(new_active: bool) -> void:
	super(new_active)
	if not new_active and _blade_tween:
		_blade_tween.kill()
		blade.position.y = 0.0
