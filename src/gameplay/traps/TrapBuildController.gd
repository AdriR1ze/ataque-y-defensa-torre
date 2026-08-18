extends Node
class_name TrapBuildController


signal build_mode_changed(enabled: bool)
signal preview_changed(valid: bool)


const GROUP_COLOCABLE := "colocable"
const GROUP_TRAPS := "traps"

const COLLISION_MASK := 9
const RAY_DISTANCE := 100.0
const FREE_ROTATION_STEP := 15.0
const OVERLAP_MARGIN := 0.05


@onready var trap_manager: TrapManager = $"../TrapManager"

var input_enabled := true
var build_mode := false

var _yaw := 0.0
var _preview: Node3D
var _preview_valid := false

var _material_valid: StandardMaterial3D
var _material_invalid: StandardMaterial3D


@onready var entity_root: Node3D = get_node("%EntityRoot")


func _ready() -> void:
	_material_valid = _make_preview_material(
		Color(0.0, 1.0, 0.0, 0.4)
	)

	_material_invalid = _make_preview_material(
		Color(1.0, 0.0, 0.0, 0.4)
	)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return

	if event is InputEventKey and event.pressed and not event.echo:

		if event.keycode == KEY_Q:
			toggle_build_mode()
			get_viewport().set_input_as_handled()
			return

		if build_mode:
			var slot := _slot_for_key(event.keycode)

			if slot != 0:
				trap_manager.select_slot(slot)
				_create_preview()

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


func _physics_process(_delta: float) -> void:
	if build_mode and _preview != null:
		_update_preview()


func toggle_build_mode() -> void:
	build_mode = not build_mode

	var player := get_tree().get_first_node_in_group("player") as Player

	if player:
		player.is_building = build_mode

	if build_mode:

		if trap_manager.selected_slot == 0:
			var first_slot := _first_available_slot()

			if first_slot != 0:
				trap_manager.select_slot(first_slot)

		_create_preview()

	else:
		_destroy_preview()

	build_mode_changed.emit(build_mode)


func _first_available_slot() -> int:
	for slot in range(1, trap_manager.get_slot_count() + 1):

		var trap_id := trap_manager.get_slot_trap(slot)

		if trap_id != 0:
			return slot

	return 0


func _slot_for_key(keycode: int) -> int:
	for slot in trap_manager.SLOT_KEYS:
		if trap_manager.SLOT_KEYS[slot] == keycode:
			return slot

	return 0


func _create_preview() -> void:
	_destroy_preview()

	if not build_mode:
		return

	var trap_data := trap_manager.get_selected_trap()

	if trap_data == null:
		return

	if trap_data.scene == null:
		return

	_preview = trap_data.scene.instantiate()

	entity_root.add_child(_preview)

	_preview.visible = false

	_apply_material_override(
		_preview,
		_material_valid
	)

	_set_trap_active(_preview, false)


func _destroy_preview() -> void:
	if _preview:
		_preview.queue_free()
		_preview = null

	_preview_valid = false

	preview_changed.emit(false)


func _set_trap_active(node: Node, value: bool) -> void:

	if node is Area3D and node.has_method("deactivate"):
		node.deactivate()

	if node is Trap:
		node.set_active(value)

	for child in node.get_children():
		_set_trap_active(child, value)


func _make_preview_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()

	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	return mat


func _apply_material_override(
	node: Node,
	mat: StandardMaterial3D
) -> void:

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


func _update_preview() -> void:

	var camera := _get_camera()

	if camera == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size

	var from := camera.project_ray_origin(
		viewport_size * 0.5
	)

	var to := from + camera.project_ray_normal(
		viewport_size * 0.5
	) * RAY_DISTANCE

	var query := PhysicsRayQueryParameters3D.create(
		from,
		to
	)

	query.collision_mask = COLLISION_MASK

	var result := get_viewport().get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		_preview.visible = false
		_set_preview_valid(false)
		return

	var collider := result.get("collider") as Node

	if collider == null or not _is_colocable(collider):
		_preview.visible = false
		_set_preview_valid(false)
		return

	var normal := result.get("normal") as Vector3

	var trap := _preview as Trap

	var valid := true

	if trap != null:
		valid = trap.is_surface_valid(normal)

	var transform := _compute_preview_transform(
		result.get("position") as Vector3,
		normal
	)

	_preview.global_transform = transform
	_preview.visible = true

	if valid and _overlaps_existing(
		transform.origin,
		normal
	):
		valid = false

	_set_preview_valid(valid)

	_apply_material_override(
		_preview,
		_material_valid if valid else _material_invalid
	)


func _set_preview_valid(valid: bool) -> void:

	if _preview_valid == valid:
		return

	_preview_valid = valid
	preview_changed.emit(valid)


func _overlaps_existing(
	position: Vector3,
	normal: Vector3
) -> bool:

	var trap := _preview as Trap

	if trap == null:
		return false

	for placed in get_tree().get_nodes_in_group(GROUP_TRAPS):

		var placed_trap := placed as Trap

		if placed_trap == null:
			continue

		var offset := placed_trap.global_position - position

		var flat := offset - normal * offset.dot(normal)

		var min_distance := (
			trap.footprint_radius
			+ placed_trap.footprint_radius
			+ OVERLAP_MARGIN
		)

		if flat.length() < min_distance:
			return true

	return false


func _compute_preview_transform(
	hit_position: Vector3,
	normal: Vector3
) -> Transform3D:

	var y := normal.normalized()

	var reference := Vector3.FORWARD

	if absf(y.dot(reference)) > 0.99:
		reference = Vector3.RIGHT

	var z := reference - y * reference.dot(y)

	z = z.normalized()

	var x := y.cross(z).normalized()

	var basis := Basis(x, y, z)

	basis = basis.rotated(y, _yaw)

	return Transform3D(
		basis,
		hit_position
	)


func _is_colocable(node: Node) -> bool:

	var current: Node = node

	while current != null:

		if current.is_in_group(GROUP_COLOCABLE):
			return true

		if current is GridMap:
			return true

		current = current.get_parent()

	return false


func _get_camera() -> Camera3D:

	var player := get_tree().get_first_node_in_group(
		"player"
	) as Node3D

	if player == null:
		return null

	return player.get_node_or_null(
		"CameraComponent/Camera3D"
	) as Camera3D


func try_place_trap() -> void:

	if not build_mode:
		return

	if _preview == null:
		return

	if not _preview_valid:
		return

	var trap_data := trap_manager.get_selected_trap()

	if trap_data == null:
		return

	if trap_data.scene == null:
		return

	var trap: Node3D = trap_data.scene.instantiate()

	entity_root.add_child(trap)

	trap.global_transform = _preview.global_transform

	trap.add_to_group(GROUP_TRAPS)
