extends Trap
class_name WindGustTrap

@export var gust_interval := 2.0
@export var gust_duration := 0.8
@export var push_force := 14.0
@export var gust_range := 6.0
@export var gust_width := 3.0

var _gust_active := false
var _timer := 0.0
var _gust_timer := 0.0
var _overlapping := {}

@onready var gust_area: Area3D = $GustArea
@onready var visual: Node3D = $Visual


func _ready() -> void:
	gust_area.body_entered.connect(_on_body_entered)
	gust_area.body_exited.connect(_on_body_exited)
	visual.visible = false
	var shape := BoxShape3D.new()
	shape.size = Vector3(gust_width, gust_range, gust_width)
	var col := gust_area.get_node("CollisionShape3D") as CollisionShape3D
	col.shape = shape
	col.position = Vector3(0.0, gust_range * 0.5, 0.0)
	var gust_mesh := visual.get_node("GustMesh") as MeshInstance3D
	gust_mesh.scale.y = gust_range
	gust_mesh.position.y = gust_range * 0.5


func _physics_process(delta: float) -> void:
	if not active:
		return
	_timer -= delta
	if _timer <= 0.0 and not _gust_active:
		_timer = gust_interval
		_gust_active = true
		_gust_timer = gust_duration
		visual.visible = true
	if _gust_active:
		_gust_timer -= delta
		if _gust_timer <= 0.0:
			_gust_active = false
			visual.visible = false
		else:
			_push_enemies()


func _push_enemies() -> void:
	var forward := global_basis.y.normalized()
	for body in _overlapping.keys():
		if not is_instance_valid(body):
			_overlapping.erase(body)
			continue
		if body.has_method("push"):
			body.push(forward, push_force)


func _on_body_entered(body: Node3D) -> void:
	if body != null:
		_overlapping[body] = true


func _on_body_exited(body: Node3D) -> void:
	_overlapping.erase(body)


func set_active(new_active: bool) -> void:
	super(new_active)
	if gust_area:
		gust_area.monitoring = new_active
	if not new_active:
		_gust_active = false
		visual.visible = false
