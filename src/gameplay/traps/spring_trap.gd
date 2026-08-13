extends Trap
class_name SpringTrap

@export var launch_force := 8.0
@export var cooldown := 1.2

var _cooldown := 0.0
var _overlapping: Array[Node3D] = []

@onready var spring_area: Area3D = $SpringArea


func _ready() -> void:
	spring_area.body_entered.connect(_on_body_entered)
	spring_area.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	for body in _overlapping:
		if is_instance_valid(body) and body.has_method("launch_up"):
			body.launch_up(launch_force)
			_cooldown = cooldown
			return


func _on_body_entered(body: Node3D) -> void:
	if body != null:
		_overlapping.append(body)


func _on_body_exited(body: Node3D) -> void:
	_overlapping.erase(body)


func set_active(new_active: bool) -> void:
	super(new_active)
	if spring_area:
		spring_area.monitoring = new_active
		_overlapping.clear()
