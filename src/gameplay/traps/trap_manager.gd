extends Node
class_name TrapManager

const TRAP_SCENES := {
	1: preload("res://src/gameplay/traps/spikes_trap.tscn"),
	2: preload("res://src/gameplay/traps/spike_launcher_trap.tscn"),
}

const GROUP_COLOCABLE := "colocable"
const GROUP_TRAPS := "traps"
const COLLISION_MASK := 9
const RAY_DISTANCE := 100.0
const FREE_ROTATION_STEP := 15.0
const OVERLAP_MARGIN := 0.05

var build_mode := false
var selected_slot := 0

var _yaw := 0.0
var _preview: Node3D
var _preview_valid := false

var _material_valid: StandardMaterial3D
var _material_invalid: StandardMaterial3D

@onready var entity_root: Node3D = get_node("%EntityRoot")

func _ready() -> void:
	_material_valid = _make_preview_material(Color(0.0, 1.0, 0.0, 0.4))
	_material_invalid = _make_preview_material(Color(1.0, 0.0, 0.0, 0.4))

func _make_preview_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			toggle_build_mode()
			get_viewport().set_input_as_handled()
			return
		if build_mode and event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var slot := int(event.keycode) - int(KEY_1) + 1
			if TRAP_SCENES.has(slot):
				select_trap(slot)
				get_viewport().set_input_as_handled()
			return
	if not build_mode:
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_rotate_preview(1)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				_rotate_preview(-1)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_LEFT:
				try_place_trap()
				get_viewport().set_input_as_handled()

func toggle_build_mode() -> void:
	build_mode = not build_mode
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.is_building = build_mode
	if build_mode:
		if selected_slot == 0:
			select_trap(1)
		else:
			_create_preview()
	else:
		_destroy_preview()

func select_trap(slot: int) -> void:
	if not TRAP_SCENES.has(slot):
		return
	selected_slot = slot
	_yaw = 0.0
	_create_preview()

func _create_preview() -> void:
	_destroy_preview()
	if not build_mode or not TRAP_SCENES.has(selected_slot):
		return
	_preview = TRAP_SCENES[selected_slot].instantiate()
	entity_root.add_child(_preview)
	_preview.visible = false
	_apply_material_override(_preview, _material_valid)
	_set_trap_active(_preview, false)

func _set_trap_active(node: Node, value: bool) -> void:
	if node is Area3D and node.has_method("deactivate"):
		node.deactivate()
	if node is Trap:
		node.set_active(value)
	for child in node.get_children():
		_set_trap_active(child, value)

func _destroy_preview() -> void:
	if _preview:
		_preview.queue_free()
		_preview = null
	_preview_valid = false

func _apply_material_override(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_override(child, mat)

func _rotate_preview(dir: int) -> void:
	if _preview == null:
		return
	var trap := _preview as Trap
	if trap == null:
		return
	if trap.allow_free_rotation:
		_yaw += deg_to_rad(FREE_ROTATION_STEP) * dir
	else:
		_yaw += deg_to_rad(trap.snap_rotation_degrees) * dir

func _physics_process(_delta: float) -> void:
	if build_mode and _preview != null:
		_update_preview()

func _update_preview() -> void:
	var camera := _get_camera()
	if camera == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var from := camera.project_ray_origin(viewport_size * 0.5)
	var to := from + camera.project_ray_normal(viewport_size * 0.5) * RAY_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = COLLISION_MASK
	var result := get_viewport().get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		_preview.visible = false
		_preview_valid = false
		return

	var collider := result.get("collider") as Node
	if collider == null or not _is_colocable(collider):
		_preview.visible = false
		_preview_valid = false
		return

	var normal := result.get("normal") as Vector3
	var trap := _preview as Trap
	var valid := true
	if trap != null:
		valid = trap.is_surface_valid(normal)

	var transform := _compute_preview_transform(result.get("position") as Vector3, normal)
	_preview.global_transform = transform
	_preview.visible = true
	if valid and _overlaps_existing(transform.origin, normal):
		valid = false
	_preview_valid = valid
	_apply_material_override(_preview, _material_valid if valid else _material_invalid)

func _overlaps_existing(position: Vector3, normal: Vector3) -> bool:
	var trap := _preview as Trap
	if trap == null:
		return false
	for placed in get_tree().get_nodes_in_group(GROUP_TRAPS):
		var placed_trap := placed as Trap
		if placed_trap == null:
			continue
		var offset = placed.global_position - position
		var flat = offset - normal * offset.dot(normal)
		var min_distance := trap.footprint_radius + placed_trap.footprint_radius + OVERLAP_MARGIN
		if flat.length() < min_distance:
			return true
	return false

func _compute_preview_transform(hit_position: Vector3, normal: Vector3) -> Transform3D:
	var y := normal.normalized()
	var reference := Vector3.FORWARD
	if absf(y.dot(reference)) > 0.99:
		reference = Vector3.RIGHT
	var z := reference - y * reference.dot(y)
	z = z.normalized()
	var x := y.cross(z).normalized()
	var basis := Basis(x, y, z)
	basis = basis.rotated(y, _yaw)
	return Transform3D(basis, hit_position)

func _is_colocable(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group(GROUP_COLOCABLE):
			return true
		current = current.get_parent()
	return false

func _get_camera() -> Camera3D:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return null
	return player.get_node_or_null("CameraComponent/Camera3D") as Camera3D

func try_place_trap() -> void:
	if not build_mode or _preview == null or not _preview_valid:
		return
	if not TRAP_SCENES.has(selected_slot):
		return
	var trap: Node3D = (TRAP_SCENES[selected_slot] as PackedScene).instantiate()
	entity_root.add_child(trap)
	trap.global_transform = _preview.global_transform
	trap.add_to_group(GROUP_TRAPS)
