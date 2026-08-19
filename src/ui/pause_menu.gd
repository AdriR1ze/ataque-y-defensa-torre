extends Control
class_name PauseMenu

signal resume_pressed
signal restart_pressed
signal main_menu_pressed
signal quit_pressed


func _ready() -> void:
	visible = false
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
	panel.add_child(_make_button("Menú principal", _on_main_menu_pressed))
	panel.add_child(_make_button("Salir", _on_quit_pressed))


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


func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()
