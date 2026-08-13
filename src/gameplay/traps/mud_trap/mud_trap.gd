extends Trap
class_name MudTrap

@export var slow_factor := 0.4

var _slow_id := ""
var _area: Area3D


func _ready() -> void:
	_slow_id = "mud_" + str(get_instance_id())
	_area = $MudArea
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not active or body == null:
		return
	if body.has_method("apply_speed_modifier"):
		body.apply_speed_modifier(_slow_id, slow_factor)


func _on_body_exited(body: Node3D) -> void:
	if body != null and is_instance_valid(body) and body.has_method("remove_speed_modifier"):
		body.remove_speed_modifier(_slow_id)


func set_active(new_active: bool) -> void:
	super(new_active)
	if _area:
		if not new_active:
			var bodies := _area.get_overlapping_bodies()
			_area.monitoring = false
			for body in bodies:
				if body != null and body.has_method("remove_speed_modifier"):
					body.remove_speed_modifier(_slow_id)
		else:
			_area.monitoring = true
