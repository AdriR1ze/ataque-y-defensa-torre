extends Trap
class_name WebTrap

@export var root_duration := 2.5

var _root_id := ""
var _overlapping := {}
var _root_timers := {}

@onready var web_area: Area3D = $WebArea


func _ready() -> void:
	_root_id = "web_" + str(get_instance_id())
	web_area.body_entered.connect(_on_body_entered)
	web_area.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if not active:
		_clear_roots()
		return
	for body in _overlapping.keys():
		if not is_instance_valid(body):
			_overlapping.erase(body)
			continue
		if body.has_method("apply_speed_modifier"):
			body.apply_speed_modifier(_root_id, 0.0)
			_root_timers[body] = root_duration
	for body in _root_timers.keys():
		if not is_instance_valid(body) or not _overlapping.has(body):
			if is_instance_valid(body) and body.has_method("remove_speed_modifier"):
				body.remove_speed_modifier(_root_id)
			_root_timers.erase(body)
			continue
		_root_timers[body] -= delta
		if _root_timers[body] <= 0.0:
			body.remove_speed_modifier(_root_id)
			_root_timers.erase(body)


func _on_body_entered(body: Node3D) -> void:
	if body != null:
		_overlapping[body] = true


func _on_body_exited(body: Node3D) -> void:
	_overlapping.erase(body)


func _clear_roots() -> void:
	for body in _root_timers.keys():
		if is_instance_valid(body) and body.has_method("remove_speed_modifier"):
			body.remove_speed_modifier(_root_id)
	_root_timers.clear()


func set_active(new_active: bool) -> void:
	super(new_active)
	if web_area:
		web_area.monitoring = new_active
	if not new_active:
		_clear_roots()
