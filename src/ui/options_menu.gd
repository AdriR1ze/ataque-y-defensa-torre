extends Control
class_name OptionsMenu

signal closed


const COLOR_BG := Color(0.02, 0.03, 0.05, 0.95)
const COLOR_BACKDROP := Color(0.0, 0.0, 0.0, 0.6)
const COLOR_BORDER := Color(1.0, 1.0, 1.0, 0.08)
const COLOR_ACCENT := Color(0.94, 0.71, 0.27)
const COLOR_TEXT := Color(0.93, 0.95, 0.98)
const COLOR_TEXT_MUTED := Color(0.56, 0.60, 0.68)


var _rebind_action := ""
var _rebind_button: Button
var _rebind_labels: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _rebind_action != "":
			var keycode: int = (event as InputEventKey).physical_keycode

			if keycode == KEY_ESCAPE:
				_cancel_rebind()
			else:
				_finish_rebind(keycode)

			get_viewport().set_input_as_handled()
			return

		if event.physical_keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func close() -> void:
	_cancel_rebind()
	closed.emit()


func _build_ui() -> void:
	add_child(_make_backdrop())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600.0, 500.0)
	panel.add_theme_stylebox_override(
		"panel",
		_make_style(COLOR_BG, 14, COLOR_BORDER, 1)
	)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "OPCIONES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tabs)

	tabs.add_child(_build_audio_tab())
	tabs.add_child(_build_video_tab())
	tabs.add_child(_build_controls_tab())

	var back := Button.new()
	back.text = "Volver"
	back.custom_minimum_size = Vector2(180.0, 40.0)
	back.pressed.connect(close)
	back.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(back)


func _make_backdrop() -> ColorRect:
	var backdrop := ColorRect.new()
	backdrop.color = COLOR_BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return backdrop


func _build_audio_tab() -> Control:
	var tab := _make_tab()

	tab.add_child(_make_slider_row("Volumen principal", Settings.master_volume, _on_master_volume_changed))
	tab.add_child(_make_slider_row("Volumen música", Settings.music_volume, _on_music_volume_changed))
	tab.add_child(_make_slider_row("Volumen efectos", Settings.sfx_volume, _on_sfx_volume_changed))

	tab.add_child(_make_check_row(
		"Música habilitada",
		Settings.music_enabled,
		_on_music_enabled_toggled
	))

	var track_row := HBoxContainer.new()
	track_row.add_theme_constant_override("separation", 8)
	tab.add_child(track_row)

	track_row.add_child(_make_label("Canción"))

	var track_option := OptionButton.new()
	track_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for track_name in Music.get_track_names():
		track_option.add_item(track_name)

	track_option.select(Settings.music_track_index)
	track_option.item_selected.connect(_on_track_selected)
	track_row.add_child(track_option)

	return tab


func _build_video_tab() -> Control:
	var tab := _make_tab()

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	tab.add_child(mode_row)

	mode_row.add_child(_make_label("Modo ventana"))

	var mode_option := OptionButton.new()
	mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_option.add_item("Ventana")
	mode_option.add_item("Pantalla completa")
	mode_option.select(1 if Settings.fullscreen else 0)
	mode_option.item_selected.connect(_on_window_mode_selected)
	mode_row.add_child(mode_option)

	var resolution_row := HBoxContainer.new()
	resolution_row.add_theme_constant_override("separation", 8)
	tab.add_child(resolution_row)

	resolution_row.add_child(_make_label("Resolución"))

	var resolution_option := OptionButton.new()
	resolution_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for label in Settings.RESOLUTION_LABELS:
		resolution_option.add_item(label)

	resolution_option.select(Settings.resolution_index)
	resolution_option.item_selected.connect(_on_resolution_selected)
	resolution_row.add_child(resolution_option)

	tab.add_child(_make_check_row(
		"VSync",
		Settings.vsync,
		_on_vsync_toggled
	))

	return tab


func _build_controls_tab() -> Control:
	var tab := _make_tab()

	for action in Settings.REMAPPABLE_ACTIONS:
		tab.add_child(_make_action_row(action))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 8.0)
	tab.add_child(spacer)

	var reset := Button.new()
	reset.text = "Restablecer controles"
	reset.pressed.connect(_on_reset_controls_pressed)
	tab.add_child(reset)

	return tab


func _make_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.add_theme_constant_override("separation", 10)
	return tab


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(150.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_font_size_override("font_size", 14)
	return label


func _make_slider_row(
	label_text: String,
	value: float,
	callback: Callable
) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_label(label_text))

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	row.add_child(slider)

	var percent := Label.new()
	percent.text = _percent_text(value)
	percent.custom_minimum_size = Vector2(40.0, 0.0)
	percent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	percent.add_theme_font_size_override("font_size", 13)

	slider.value_changed.connect(func(v: float) -> void: percent.text = _percent_text(v))
	row.add_child(percent)

	return row


func _percent_text(value: float) -> String:
	return "%d%%" % int(round(value * 100.0))


func _make_check_row(
	label_text: String,
	value: bool,
	callback: Callable
) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_label(label_text))

	var check := CheckBox.new()
	check.button_pressed = value
	check.toggled.connect(callback)
	row.add_child(check)

	return row


func _make_action_row(action: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	row.add_child(_make_label(Settings.ACTION_LABELS[action]))

	var button := Button.new()
	button.text = Settings.get_action_display(action)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_start_rebind.bind(action, button))
	row.add_child(button)

	_rebind_labels[action] = button

	var reset := Button.new()
	reset.text = "X"
	reset.tooltip_text = "Restablecer %s" % Settings.ACTION_LABELS[action]
	reset.custom_minimum_size = Vector2(32.0, 0.0)
	reset.pressed.connect(_on_reset_action_pressed.bind(action))
	row.add_child(reset)

	return row


func _start_rebind(action: String, button: Button) -> void:
	if _rebind_action != "":
		_cancel_rebind()

	_rebind_action = action
	_rebind_button = button
	button.text = "Presiona una tecla..."


func _finish_rebind(keycode: int) -> void:
	var action := _rebind_action

	Settings.rebind_action(action, keycode)

	_cancel_rebind()
	_rebind_labels[action].text = Settings.get_action_display(action)


func _cancel_rebind() -> void:
	if _rebind_button != null:
		_rebind_button.text = Settings.get_action_display(_rebind_action)

	_rebind_action = ""
	_rebind_button = null


func _on_reset_action_pressed(action: String) -> void:
	Settings.reset_action(action)
	_rebind_labels[action].text = Settings.get_action_display(action)


func _on_reset_controls_pressed() -> void:
	Settings.reset_all_controls()

	for action in _rebind_labels:
		_rebind_labels[action].text = Settings.get_action_display(action)


func _on_master_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)


func _on_music_volume_changed(value: float) -> void:
	Settings.set_music_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	Settings.set_sfx_volume(value)


func _on_music_enabled_toggled(value: bool) -> void:
	Settings.set_music_enabled(value)


func _on_track_selected(index: int) -> void:
	Settings.set_music_track(index)


func _on_window_mode_selected(index: int) -> void:
	Settings.set_fullscreen(index == 1)


func _on_resolution_selected(index: int) -> void:
	Settings.set_resolution_index(index)


func _on_vsync_toggled(value: bool) -> void:
	Settings.set_vsync(value)


func _make_style(
	bg: Color,
	radius: int,
	border: Color,
	border_width: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(border_width)
	return style
