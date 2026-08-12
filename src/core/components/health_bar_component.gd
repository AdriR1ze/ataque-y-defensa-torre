extends Node3D
class_name HealthBarComponent

@export var offset_y := 2.2
@export var bar_width := 1.2
@export var bar_height := 0.12

var _background: MeshInstance3D
var _fill: MeshInstance3D
var _health: HealthComponent


func _ready() -> void:
	_health = get_parent().get_node("HealthComponent")
	if _health == null:
		push_error("[HealthBar] No se encontro HealthComponent en el padre")
		return

	position.y = offset_y
	_build_bar()

	_health.health_changed.connect(_update_bar)
	_health.died.connect(_on_died)
	_update_bar(_health.current_health, _health.max_health)


func _build_bar() -> void:
	_background = _create_quad(Color(0.08, 0.08, 0.08, 0.85), bar_width + 0.04, bar_height + 0.03)
	add_child(_background)

	_fill = _create_quad(Color(0.25, 0.8, 0.3, 1.0), bar_width, bar_height)
	_fill.position.z = 0.01
	add_child(_fill)


func _create_quad(color: Color, w: float, h: float) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(w, h)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.disable_receive_shadows = true

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _update_bar(current: float, max_health: float) -> void:
	if _fill == null:
		return

	var fraction := 0.0
	if max_health > 0.0:
		fraction = clampf(current / max_health, 0.0, 1.0)

	_fill.scale.x = fraction
	_fill.position.x = bar_width * 0.5 * (fraction - 1.0)

	var fill_mat := _fill.material_override as StandardMaterial3D
	if fill_mat:
		fill_mat.albedo_color = Color(0.25, 0.8, 0.3).lerp(Color(0.9, 0.2, 0.2), 1.0 - fraction)


func _on_died() -> void:
	visible = false
