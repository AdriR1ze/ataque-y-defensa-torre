extends Trap
class_name SuctionTrap

@export var pull_force := 7.0
@export var pull_radius := 6.0
@export var damage_per_second := 12.0

var _overlapping := {}

@onready var pull_area: Area3D = $PullArea
@onready var damage_area: DamageAreaComponent = $DamageArea


func _ready() -> void:
	pull_area.body_entered.connect(_on_body_entered)
	pull_area.body_exited.connect(_on_body_exited)
	damage_area.set_damage_per_second(damage_per_second)


func _physics_process(delta: float) -> void:
	if not active:
		return
	for body in _overlapping.keys():
		if not is_instance_valid(body):
			_overlapping.erase(body)
			continue
		var offset: Vector3 = global_position - body.global_position
		offset.y = 0.0
		if offset.length() < 0.01:
			continue
		if body.has_method("push"):
			body.push(offset.normalized(), pull_force)


func _on_body_entered(body: Node3D) -> void:
	if body != null:
		_overlapping[body] = true


func _on_body_exited(body: Node3D) -> void:
	_overlapping.erase(body)


func set_active(new_active: bool) -> void:
	super(new_active)
	if pull_area:
		pull_area.monitoring = new_active
	if damage_area:
		damage_area.active = new_active
		damage_area.monitoring = new_active
