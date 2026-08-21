extends CanvasLayer
class_name BlueprintUnlockCutscene

signal cutscene_finished

const BLUEPRINT_DROP_SCENE := preload("res://src/gameplay/traps/blueprint_drop.tscn")

var _camera: Camera3D
var _prev_camera: Camera3D
var _player: Player
var _enemy: Enemy
var _trap_data: TrapData
var _blueprint_drop: Node3D
var _audio_player: AudioStreamPlayer

# UI Elements
var _letterbox_top: ColorRect
var _letterbox_bottom: ColorRect
var _content_panel: CenterContainer
var _card_panel: PanelContainer
var _continue_btn: Button
var _can_continue := false

# Orbiting camera state in close-up
var _is_orbiting := false
var _orbit_center := Vector3.ZERO
var _orbit_angle := 0.0
var _orbit_radius := 1.8
var _orbit_height := 0.95


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func play(target_enemy: Enemy, player_ref: Player, trap_data: TrapData) -> void:
	_enemy = target_enemy
	_player = player_ref
	_trap_data = trap_data

	# 1. Bloquear controles del jugador
	if _player != null and is_instance_valid(_player):
		_player.velocity = Vector3.ZERO
		_player.process_mode = Node.PROCESS_MODE_DISABLED

	# 2. Configurar cámara cinemática 3D
	_setup_cinematic_camera()

	# 3. Animar bandas de cine
	_animate_letterbox(true)

	var enemy_pos := _enemy.global_position if is_instance_valid(_enemy) else Vector3.ZERO
	var target_look := enemy_pos + Vector3.UP * 0.8

	if _player != null and is_instance_valid(_player) and is_instance_valid(_enemy):
		var dir_to_player := (_player.global_position - enemy_pos).normalized()
		if dir_to_player.length() < 0.1:
			dir_to_player = Vector3.BACK

		var desired_start := enemy_pos + dir_to_player * 3.8 + Vector3.UP * 2.2 + Vector3(-1.2, 0.0, 0.8)
		var cam_start_pos := _get_valid_cam_pos(target_look, desired_start)
		_camera.global_position = cam_start_pos
		_camera.look_at(target_look, Vector3.UP)

	# 4. Breve cámara lenta mientras el enemigo cae
	Engine.time_scale = 0.4
	await get_tree().create_timer(0.4).timeout
	Engine.time_scale = 1.0

	# 5. Crear y soltar el plano 3D desde el cuerpo del enemigo
	_blueprint_drop = BLUEPRINT_DROP_SCENE.instantiate() as Node3D
	if _blueprint_drop.has_method("setup_trap_visual") and _trap_data != null:
		_blueprint_drop.setup_trap_visual(_trap_data)
	get_tree().current_scene.add_child(_blueprint_drop)

	var drop_origin := enemy_pos + Vector3.UP * 1.0
	if _blueprint_drop.has_method("drop_from"):
		_blueprint_drop.drop_from(drop_origin, 0.08)

	# Seguimiento de cámara hacia el plano que cae libre de paredes
	var desired_mid := enemy_pos + Vector3(1.6, 1.6, 1.8)
	var cam_mid_pos := _get_valid_cam_pos(enemy_pos + Vector3.UP * 0.5, desired_mid)
	var cam_tween := create_tween().set_parallel(true)
	cam_tween.tween_property(_camera, "global_position", cam_mid_pos, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 6. Esperar a que el plano toque tierra y comience a brillar
	if _blueprint_drop.has_signal("dropped_on_ground"):
		await _blueprint_drop.dropped_on_ground
	else:
		await get_tree().create_timer(1.6).timeout

	# 7. Primer plano (Hero Close-up) enfocado en el plano 3D
	var blueprint_pos := _blueprint_drop.global_position if is_instance_valid(_blueprint_drop) else enemy_pos
	_orbit_center = blueprint_pos + Vector3.UP * 0.2
	_orbit_angle = atan2(_camera.global_position.z - _orbit_center.z, _camera.global_position.x - _orbit_center.x)

	# Posición del primer plano libre de muros
	var desired_closeup := _orbit_center + Vector3(cos(_orbit_angle) * _orbit_radius, _orbit_height, sin(_orbit_angle) * _orbit_radius)
	var closeup_pos := _get_valid_cam_pos(_orbit_center, desired_closeup)

	var zoom_tween := create_tween().set_parallel(true)
	zoom_tween.tween_property(_camera, "global_position", closeup_pos, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var look_tween := create_tween()
	look_tween.tween_method(func(pos: Vector3) -> void:
		if is_instance_valid(_camera):
			_camera.look_at(pos, Vector3.UP)
	, enemy_pos + Vector3.UP * 0.5, _orbit_center, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await zoom_tween.finished
	_is_orbiting = true

	# 8. Desbloquear en el sistema de progreso y reproducir fanfarria
	if _trap_data != null:
		Progress.unlock_blueprint(_trap_data.id)

	_play_unlock_fanfare()

	# 9. Dejar que el jugador aprecie el plano durante 2.5s
	await get_tree().create_timer(2.5).timeout

	# 10. Desplegar la tarjeta de desbloqueo UI
	_show_unlock_card()


func _get_valid_cam_pos(target: Vector3, desired: Vector3) -> Vector3:
	var space_state := get_viewport().find_world_3d().direct_space_state
	if space_state == null:
		return desired

	var query := PhysicsRayQueryParameters3D.create(target, desired, 1) # Layer 1 = World/Walls
	var result := space_state.intersect_ray(query)

	if not result.is_empty():
		var hit_pos: Vector3 = result.get("position", desired)
		var dist := hit_pos.distance_to(target)
		if dist < 0.9:
			# Si la pared está muy pegada, elevar la cámara para un encuadre cenital impecable
			return target + Vector3(0.2, 2.6, 0.4)

		var dir := (target - hit_pos).normalized()
		return hit_pos + dir * 0.45

	return desired


func _process(delta: float) -> void:
	if _is_orbiting and is_instance_valid(_camera):
		_orbit_angle += delta * 0.22
		var desired_pos := _orbit_center + Vector3(
			cos(_orbit_angle) * _orbit_radius,
			_orbit_height + sin(_orbit_angle * 1.5) * 0.08,
			sin(_orbit_angle) * _orbit_radius
		)
		var safe_pos := _get_valid_cam_pos(_orbit_center, desired_pos)
		_camera.global_position = safe_pos
		_camera.look_at(_orbit_center, Vector3.UP)


func _setup_cinematic_camera() -> void:
	var viewport := get_viewport()
	_prev_camera = viewport.get_camera_3d()

	_camera = Camera3D.new()
	_camera.name = "CinematicCutsceneCamera"
	_camera.fov = 50.0
	_camera.near = 0.05
	_camera.current = true
	get_tree().current_scene.add_child(_camera)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Letterbox Bars
	_letterbox_top = ColorRect.new()
	_letterbox_top.color = Color(0.02, 0.02, 0.03, 1.0)
	_letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_letterbox_top.offset_bottom = 0.0
	root.add_child(_letterbox_top)

	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.color = Color(0.02, 0.02, 0.03, 1.0)
	_letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_letterbox_bottom.offset_top = 0.0
	root.add_child(_letterbox_bottom)

	# Contenedor central para la tarjeta
	_content_panel = CenterContainer.new()
	_content_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_panel.modulate = Color(1, 1, 1, 0)
	_content_panel.scale = Vector2(0.9, 0.9)
	_content_panel.pivot_offset = Vector2(480, 270)
	root.add_child(_content_panel)


func _show_unlock_card() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_card_panel = PanelContainer.new()
	_card_panel.custom_minimum_size = Vector2(460, 340)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15, 0.92)
	style.border_color = Color(0.25, 0.75, 1.0, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	style.shadow_color = Color(0.1, 0.55, 0.95, 0.4)
	style.shadow_size = 22
	_card_panel.add_theme_stylebox_override("panel", style)
	_content_panel.add_child(_card_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_card_panel.add_child(vbox)

	# Encabezado
	var header := Label.new()
	header.text = "✦ ¡NUEVO PLANO DESBLOQUEADO! ✦"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	vbox.add_child(header)

	var trap_name := _trap_data.trap_name if _trap_data != null else "Pinchos"
	var title := Label.new()
	title.text = trap_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(title)

	var separator := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.2, 0.6, 0.9, 0.4)
	sep_style.thickness = 1
	separator.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(separator)

	# Stats grid
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 36)
	vbox.add_child(stats)

	var cost_val := str(_trap_data.cost) if _trap_data != null else "50"
	var dmg_val := str(_trap_data.damage) if _trap_data != null else "25.0"

	stats.add_child(_make_stat_badge("Coste", cost_val + " 💰", Color(1.0, 0.85, 0.3)))
	stats.add_child(_make_stat_badge("Daño", dmg_val + " ⚔", Color(1.0, 0.35, 0.35)))
	stats.add_child(_make_stat_badge("Tipo", "Suelo", Color(0.4, 0.8, 1.0)))

	# Descripción
	var desc := Label.new()
	desc.text = _trap_data.description if _trap_data != null else "Daña a los enemigos que pasan por encima."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
	vbox.add_child(desc)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)

	# Botón Continuar
	_continue_btn = Button.new()
	_continue_btn.text = "CONTINUAR [ESPACIO] →"
	_continue_btn.custom_minimum_size = Vector2(240, 46)
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.55, 0.95)
	btn_style.set_corner_radius_all(8)
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.25, 0.68, 1.0)
	btn_hover.set_corner_radius_all(8)
	_continue_btn.add_theme_stylebox_override("normal", btn_style)
	_continue_btn.add_theme_stylebox_override("hover", btn_hover)
	_continue_btn.add_theme_stylebox_override("pressed", btn_style)
	_continue_btn.add_theme_font_size_override("font_size", 15)
	_continue_btn.add_theme_color_override("font_color", Color.WHITE)
	_continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_btn)

	# Animación de entrada
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_content_panel, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_content_panel, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished
	_can_continue = true
	_continue_btn.grab_focus()


func _make_stat_badge(label_text: String, value_text: String, val_color: Color) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	box.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", 16)
	val.add_theme_color_override("font_color", val_color)
	box.add_child(val)

	return box


func _animate_letterbox(open: bool) -> void:
	var target_h := 65.0 if open else 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_letterbox_top, "offset_bottom", target_h, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_letterbox_bottom, "offset_top", -target_h, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_continue:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER:
			get_viewport().set_input_as_handled()
			_on_continue_pressed()


func _on_continue_pressed() -> void:
	if not _can_continue:
		return
	_can_continue = false
	_is_orbiting = false

	Engine.time_scale = 1.0

	# Animación de salida
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_content_panel, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_animate_letterbox(false)

	await tween.finished

	# Restaurar cámara y jugador
	if _prev_camera != null and is_instance_valid(_prev_camera):
		_prev_camera.current = true

	if _player != null and is_instance_valid(_player):
		_player.process_mode = Node.PROCESS_MODE_PAUSABLE

	if _camera != null and is_instance_valid(_camera):
		_camera.queue_free()

	if _blueprint_drop != null and is_instance_valid(_blueprint_drop):
		_blueprint_drop.queue_free()

	cutscene_finished.emit()
	queue_free()


func _play_unlock_fanfare() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "Master"
	add_child(_audio_player)

	var stream := _generate_fanfare_audio()
	if stream != null:
		_audio_player.stream = stream
		_audio_player.play()


func _generate_fanfare_audio() -> AudioStreamWAV:
	var sample_rate := 22050
	var notes: Array[float] = [261.63, 329.63, 392.0, 523.25, 659.25, 783.99]
	var note_duration := 0.16
	var final_duration := 1.2
	var total_duration := (notes.size() - 1) * note_duration + final_duration
	var sample_count := int(total_duration * sample_rate)

	var buffer := PackedFloat32Array()
	buffer.resize(sample_count)

	for i in range(notes.size()):
		var freq: float = notes[i]
		var start_time := i * note_duration
		var dur := final_duration if i == notes.size() - 1 else note_duration * 1.6
		var start_sample := int(start_time * sample_rate)
		var note_samples := int(dur * sample_rate)

		for s in range(note_samples):
			var idx := start_sample + s
			if idx >= sample_count:
				break
			var t := float(s) / note_samples
			var env := pow(1.0 - t, 1.6) * minf(1.0, float(s) / 250.0)
			var phase := TAU * freq * s / sample_rate
			var sample_val := (sin(phase) + 0.45 * sin(phase * 2.0) + 0.25 * sin(phase * 3.0) + 0.1 * sin(phase * 4.0)) * env * 0.35
			buffer[idx] += sample_val

	# Normalizar
	var peak := 0.0
	for val in buffer:
		if absf(val) > peak:
			peak = absf(val)
	if peak > 0.0:
		for j in range(buffer.size()):
			buffer[j] = (buffer[j] / peak) * 0.75

	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for k in range(sample_count):
		var s16 := clampi(int(buffer[k] * 32767.0), -32768, 32767)
		pcm.encode_s16(k * 2, s16)

	var audio_stream := AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = sample_rate
	audio_stream.stereo = false
	audio_stream.data = pcm
	return audio_stream
