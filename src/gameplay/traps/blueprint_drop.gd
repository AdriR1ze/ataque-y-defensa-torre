extends Node3D
class_name BlueprintDrop

signal dropped_on_ground

@onready var visual_root: Node3D = $VisualRoot
@onready var light: OmniLight3D = $OmniLight3D
@onready var particles: CPUParticles3D = $CPUParticles3D
@onready var sheet_mesh: MeshInstance3D = $VisualRoot/SheetMesh
@onready var holo_spikes: Node3D = $VisualRoot/HoloSpikes

var _target_ground_y := 0.0
var _is_hovering := false
var _hover_time := 0.0
var _base_y := 0.0


var _trap_data: TrapData


func _ready() -> void:
	if visual_root == null:
		visual_root = self
	if _trap_data != null:
		_setup_blueprint_texture()


func setup_trap_visual(trap_data: TrapData) -> void:
	_trap_data = trap_data
	_setup_blueprint_texture()

	if holo_spikes != null and trap_data != null and trap_data.scene != null:
		# Instanciar modelo de la trampa recibida como holograma 3D flotante
		for child in holo_spikes.get_children():
			child.queue_free()

		var holo := trap_data.scene.instantiate() as Node3D
		if holo != null:
			holo.process_mode = Node.PROCESS_MODE_DISABLED
			holo.scale = Vector3.ONE * 0.35
			holo.position = Vector3(0.0, 0.15, 0.0)
			holo_spikes.add_child(holo)


func _setup_blueprint_texture() -> void:
	if sheet_mesh == null:
		return

	var tex := _generate_blueprint_texture()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 1.3
	mat.roughness = 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sheet_mesh.material_override = mat


func drop_from(start_position: Vector3, floor_y: float = 0.1) -> void:
	global_position = start_position
	_target_ground_y = maxf(floor_y, 0.0)
	_base_y = maxf(start_position.y + 0.85, floor_y + 0.85)
	_is_hovering = false

	if visual_root != null:
		visual_root.scale = Vector2(0.4, 0.4).x * Vector3.ONE

	# Animación de arco y caída
	var tween := create_tween().set_parallel(true)

	# Arco vertical: sube majestuosamente y se posa en flotación elevada
	var pop_height := start_position.y + 1.8
	var v_tween := create_tween()
	v_tween.tween_property(self, "global_position:y", pop_height, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	v_tween.tween_property(self, "global_position:y", _base_y, 0.95).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# Desplazamiento horizontal hacia adelante
	var offset_x := randf_range(-0.4, 0.4)
	var offset_z := randf_range(1.0, 1.6)
	var target_x := global_position.x + offset_x
	var target_z := global_position.z + offset_z
	tween.tween_property(self, "global_position:x", target_x, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:z", target_z, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Expansión de escala mientras sube
	if visual_root != null:
		visual_root.rotation = Vector3(randf_range(-0.4, 0.4), 0.0, randf_range(-0.4, 0.4))
		tween.tween_property(visual_root, "scale", Vector3.ONE * 1.3, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_root, "rotation", Vector3(deg_to_rad(15.0), TAU, 0.0), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Brillo de luz
	if light != null:
		light.light_energy = 0.5
		tween.tween_property(light, "light_energy", 3.5, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await v_tween.finished
	_is_hovering = true
	dropped_on_ground.emit()


func _process(delta: float) -> void:
	if not _is_hovering:
		return

	_hover_time += delta
	# Flotación suave y oscilación
	global_position.y = _base_y + sin(_hover_time * 2.2) * 0.06
	if visual_root != null:
		visual_root.rotation.y += delta * 0.8
		visual_root.rotation.x = deg_to_rad(15.0) + sin(_hover_time * 1.8) * 0.04
		visual_root.rotation.z = cos(_hover_time * 1.5) * 0.04

	if holo_spikes != null:
		holo_spikes.rotation.y += delta * 1.6


func _generate_blueprint_texture() -> ImageTexture:
	var width := 512
	var height := 384
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)

	var bg_color := Color(0.06, 0.22, 0.48, 1.0)
	var grid_color := Color(0.12, 0.38, 0.72, 1.0)
	var line_color := Color(0.45, 0.90, 1.0, 1.0)
	var text_color := Color(0.9, 0.96, 1.0, 1.0)
	var gold_color := Color(1.0, 0.82, 0.3, 1.0)

	# Rellenar fondo
	img.fill(bg_color)

	# Dibujar cuadrícula técnica
	var grid_size := 16
	for x in range(0, width, grid_size):
		for y in range(height):
			img.set_pixel(x, y, grid_color)
	for y in range(0, height, grid_size):
		for x in range(width):
			img.set_pixel(x, y, grid_color)

	# Dibujar marco exterior doble
	_draw_rect_border(img, 12, 12, width - 24, height - 24, 2, line_color)
	_draw_rect_border(img, 18, 18, width - 36, height - 36, 1, grid_color)

	# Esquinas doradas decorativas
	_draw_rect_filled(img, 10, 10, 14, 4, gold_color)
	_draw_rect_filled(img, 10, 10, 4, 14, gold_color)
	_draw_rect_filled(img, width - 24, 10, 14, 4, gold_color)
	_draw_rect_filled(img, width - 14, 10, 4, 14, gold_color)
	_draw_rect_filled(img, 10, height - 14, 14, 4, gold_color)
	_draw_rect_filled(img, 10, height - 24, 4, 14, gold_color)
	_draw_rect_filled(img, width - 24, height - 14, 14, 4, gold_color)
	_draw_rect_filled(img, width - 14, height - 24, 4, 14, gold_color)

	# Dibujo técnico central: 4 pinchos en perspectiva isométrica
	var cx := width / 2
	var cy := height / 2 + 10

	# Base de la trampa
	_draw_rect_border(img, cx - 100, cy - 60, 200, 120, 2, line_color)
	_draw_rect_border(img, cx - 80, cy - 45, 160, 90, 1, line_color)

	# Conos de pinchos (triángulos técnicos)
	var spike_offsets := [
		Vector2i(cx - 50, cy - 25),
		Vector2i(cx + 50, cy - 25),
		Vector2i(cx - 50, cy + 25),
		Vector2i(cx + 50, cy + 25)
	]

	for pt in spike_offsets:
		_draw_triangle_spike(img, pt.x, pt.y, 22, 45, line_color, text_color)

	# Líneas de cota técnica y anotaciones
	_draw_line_h(img, cx - 115, cy - 60, 15, line_color)
	_draw_line_h(img, cx - 115, cy + 60, 15, line_color)
	_draw_line_v(img, cx - 110, cy - 60, 120, line_color)

	return ImageTexture.create_from_image(img)


func _draw_rect_border(img: Image, x: int, y: int, w: int, h: int, thickness: int, color: Color) -> void:
	for t in range(thickness):
		_draw_line_h(img, x, y + t, w, color)
		_draw_line_h(img, x, y + h - 1 - t, w, color)
		_draw_line_v(img, x + t, y, h, color)
		_draw_line_v(img, x + w - 1 - t, y, h, color)


func _draw_rect_filled(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, mini(x + w, img.get_width())):
		for py in range(y, mini(y + h, img.get_height())):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)


func _draw_line_h(img: Image, x: int, y: int, length: int, color: Color) -> void:
	if y < 0 or y >= img.get_height():
		return
	for px in range(maxi(x, 0), mini(x + length, img.get_width())):
		img.set_pixel(px, y, color)


func _draw_line_v(img: Image, x: int, y: int, length: int, color: Color) -> void:
	if x < 0 or x >= img.get_width():
		return
	for py in range(maxi(y, 0), mini(y + length, img.get_height())):
		img.set_pixel(x, py, color)


func _draw_triangle_spike(img: Image, cx: int, cy: int, base_w: int, spike_h: int, color: Color, tip_color: Color) -> void:
	var top_y := cy - spike_h
	for dy in range(spike_h):
		var curr_y := cy - dy
		if curr_y < 0 or curr_y >= img.get_height():
			continue
		var half_w := int(float(dy) / float(spike_h) * (base_w / 2.0))
		var left_x := cx - half_w
		var right_x := cx + half_w
		if left_x >= 0 and left_x < img.get_width():
			img.set_pixel(left_x, curr_y, color)
		if right_x >= 0 and right_x < img.get_width():
			img.set_pixel(right_x, curr_y, color)

	# Punta brillante
	if top_y >= 0 and top_y < img.get_height() and cx >= 0 and cx < img.get_width():
		img.set_pixel(cx, top_y, tip_color)
