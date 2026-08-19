extends Control
class_name EndScreen

signal restart_pressed
signal main_menu_pressed

var _title_label: Label
var _info_label: Label


func _ready() -> void:
	visible = false
	_build_ui()


func setup(is_victory: bool, info: String) -> void:
	_title_label.text = "¡VICTORIA!" if is_victory else "DERROTA"
	_info_label.text = info
	visible = true


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.75)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 14)
	center.add_child(panel)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 40)
	panel.add_child(_title_label)

	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(_info_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 8.0)
	panel.add_child(spacer)

	var restart := Button.new()
	restart.text = "Reintentar"
	restart.custom_minimum_size = Vector2(220.0, 44.0)
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	panel.add_child(restart)

	var main_menu := Button.new()
	main_menu.text = "Menú principal"
	main_menu.custom_minimum_size = Vector2(220.0, 44.0)
	main_menu.pressed.connect(func() -> void: main_menu_pressed.emit())
	panel.add_child(main_menu)
