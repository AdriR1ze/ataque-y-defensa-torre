extends Control
class_name PauseMenu

signal resume_pressed
signal restart_pressed
signal main_menu_pressed
signal quit_pressed


const OPTIONS_MENU := preload("res://src/ui/options_menu.tscn")


var _debug_level_btn: Button


func _ready() -> void:
	visible = false
	Debug.debug_mode_changed.connect(_on_debug_mode_changed)
	_build_ui()


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.65)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 12)
	center.add_child(panel)

	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	panel.add_child(title)

	panel.add_child(_make_button("Reanudar", _on_resume_pressed))
	panel.add_child(_make_button("Reiniciar nivel", _on_restart_pressed))

	_debug_level_btn = _make_button("Selector de Niveles (DEBUG)", _on_debug_level_selector_pressed)
	_debug_level_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_debug_level_btn.visible = Debug.debug_enabled
	panel.add_child(_debug_level_btn)

	panel.add_child(_make_button("Opciones", _on_options_pressed))
	panel.add_child(_make_button("Menú principal", _on_main_menu_pressed))
	panel.add_child(_make_button("Salir", _on_quit_pressed))


func _on_debug_mode_changed(enabled: bool) -> void:
	if _debug_level_btn != null:
		_debug_level_btn.visible = enabled


func _on_debug_level_selector_pressed() -> void:
	if Debug.debug_enabled:
		Debug.open_level_selector(self)



func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220.0, 44.0)
	button.pressed.connect(callback)
	return button


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_restart_pressed() -> void:
	restart_pressed.emit()


func _on_options_pressed() -> void:
	var options := OPTIONS_MENU.instantiate() as OptionsMenu
	options.closed.connect(options.queue_free)
	add_child(options)


func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()
