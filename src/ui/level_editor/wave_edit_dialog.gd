extends Control
class_name WaveEditDialog

signal wave_saved(wave_dict: Dictionary)

var wave_index := 0
var normal_count := 5
var fast_count := 0
var tank_count := 0
var boss_count := 0

var _normal_spin: SpinBox
var _fast_spin: SpinBox
var _tank_spin: SpinBox
var _boss_spin: SpinBox


func setup(idx: int, data: Dictionary) -> void:
	wave_index = idx
	normal_count = int(data.get("normal", 5))
	fast_count   = int(data.get("fast",   0))
	tank_count   = int(data.get("tank",   0))
	boss_count   = int(data.get("boss",   0))


func _ready() -> void:
	# Ocupa toda la pantalla del editor
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Fondo semitransparente
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.65)
	add_child(bg)

	# Panel centrado usando anchors al 50 % y offset negativo
	var panel := PanelContainer.new()
	panel.anchor_left   = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_bottom = 0.5
	var pw := 360.0
	var ph := 390.0
	panel.offset_left   = -pw / 2.0
	panel.offset_top    = -ph / 2.0
	panel.offset_right  =  pw / 2.0
	panel.offset_bottom =  ph / 2.0
	panel.custom_minimum_size = Vector2(pw, ph)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.97)
	style.corner_radius_top_left    = 8
	style.corner_radius_top_right   = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left   = 20
	style.content_margin_top    = 20
	style.content_margin_right  = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "✏️ EDITAR OLEADA #" + str(wave_index + 1)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	vbox.add_child(_create_label("🕷️ Enemigos Normales (Araña):"))
	_normal_spin = _create_spinbox(0, 100, normal_count)
	vbox.add_child(_normal_spin)

	vbox.add_child(_create_label("⚡ Enemigos Rápidos (Corredor):"))
	_fast_spin = _create_spinbox(0, 100, fast_count)
	vbox.add_child(_fast_spin)

	vbox.add_child(_create_label("🛡️ Enemigos Tanque (Esqueleto):"))
	_tank_spin = _create_spinbox(0, 100, tank_count)
	vbox.add_child(_tank_spin)

	vbox.add_child(_create_label("👑 Jefe Final (Boss):"))
	_boss_spin = _create_spinbox(0, 10, boss_count)
	vbox.add_child(_boss_spin)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.pressed.connect(queue_free)
	hbox.add_child(cancel_btn)

	var save_btn := Button.new()
	save_btn.text = "Guardar Cambios"
	save_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	save_btn.pressed.connect(_on_save_pressed)
	hbox.add_child(save_btn)


func _on_save_pressed() -> void:
	var result := {
		"normal": int(_normal_spin.value),
		"fast":   int(_fast_spin.value),
		"tank":   int(_tank_spin.value),
		"boss":   int(_boss_spin.value)
	}
	wave_saved.emit(result)
	queue_free()


func _create_label(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 12)
	return l


func _create_spinbox(min_val: float, max_val: float, val: float) -> SpinBox:
	var sb := SpinBox.new()
	sb.min_value = min_val
	sb.max_value = max_val
	sb.value = val
	sb.custom_minimum_size = Vector2(0, 32)
	var le := sb.get_line_edit()
	if le != null:
		le.context_menu_enabled = false
	return sb
