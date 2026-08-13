extends Trap
class_name ExplosiveMineTrap

enum MineState {
	ARMED,
	PRIMED,
	COOLDOWN
}

@export var fuse_time := 0.6
@export var respawn_time := 6.0
@export var explosion_radius := 2.5
@export var damage := 60.0
@export var knockback_force := 10.0

var _state := MineState.ARMED
var _timer := 0.0
var _explosion_material: StandardMaterial3D

@onready var trigger_area: Area3D = $TriggerArea
@onready var explosion_area: Area3D = $ExplosionArea
@onready var mine_mesh: Node3D = $MineMesh


func _ready() -> void:
	trigger_area.body_entered.connect(_on_body_entered)
	_explosion_material = StandardMaterial3D.new()
	_explosion_material.albedo_color = Color(1.0, 0.3, 0.1)
	_explosion_material.emission_enabled = true
	_explosion_material.emission = Color(1.0, 0.25, 0.05)
	_explosion_material.emission_energy_multiplier = 2.0


func _physics_process(delta: float) -> void:
	if not active:
		return
	match _state:
		MineState.PRIMED:
			_timer -= delta
			mine_mesh.scale = Vector3.ONE * (0.8 + 0.4 * sin(_timer * 30.0))
			if _timer <= 0.0:
				_explode()
		MineState.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				_state = MineState.ARMED
				mine_mesh.visible = true
				mine_mesh.scale = Vector3.ONE
				_apply_material_override(mine_mesh, null)


func _on_body_entered(_body: Node3D) -> void:
	if _state != MineState.ARMED:
		return
	_state = MineState.PRIMED
	_timer = fuse_time
	_apply_material_override(mine_mesh, _explosion_material)


func _explode() -> void:
	for body in explosion_area.get_overlapping_bodies():
		if body == null:
			continue
		if body.has_method("take_trap_damage"):
			body.take_trap_damage(damage)
		if body.has_method("knock_back"):
			var dir := body.global_position - global_position
			body.knock_back(dir, knockback_force)
	_state = MineState.COOLDOWN
	_timer = respawn_time
	mine_mesh.visible = false


func _apply_material_override(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_override(child, mat)


func set_active(new_active: bool) -> void:
	super(new_active)
	if trigger_area:
		trigger_area.monitoring = new_active
	if not new_active:
		_state = MineState.ARMED
		mine_mesh.visible = true
		mine_mesh.scale = Vector3.ONE
		_apply_material_override(mine_mesh, null)
