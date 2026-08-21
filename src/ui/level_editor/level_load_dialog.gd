extends Control
class_name LevelLoadDialog

signal level_loaded(file_name: String)
signal cancelled

var _item_list: ItemList
var _status_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_refresh_list()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.7)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 360)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.95)
	style.border_color = Color(0.3, 0.9, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "CARGAR NIVEL PERSONALIZADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6))
	vbox.add_child(title)

	_item_list = ItemList.new()
	_item_list.custom_minimum_size = Vector2(0, 180)
	_item_list.item_activated.connect(func(_idx): _on_load_pressed())
	vbox.add_child(_item_list)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	var delete_btn := Button.new()
	delete_btn.text = "Eliminar"
	delete_btn.custom_minimum_size = Vector2(90, 36)
	delete_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	delete_btn.pressed.connect(_on_delete_pressed)
	hbox.add_child(delete_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(90, 36)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	hbox.add_child(cancel_btn)

	var load_btn := Button.new()
	load_btn.text = "Cargar"
	load_btn.custom_minimum_size = Vector2(100, 36)
	load_btn.pressed.connect(_on_load_pressed)
	hbox.add_child(load_btn)


func _refresh_list() -> void:
	_item_list.clear()
	var levels := CustomLevelManager.list_custom_levels()
	for lvl in levels:
		_item_list.add_item(lvl)
	if levels.is_empty():
		_status_label.text = "No hay niveles guardados."
	else:
		_status_label.text = ""


func _on_load_pressed() -> void:
	var selected := _item_list.get_selected_items()
	if selected.is_empty():
		_status_label.text = "Selecciona un nivel de la lista."
		return
	var level_name := _item_list.get_item_text(selected[0])
	level_loaded.emit(level_name)
	queue_free()


func _on_delete_pressed() -> void:
	var selected := _item_list.get_selected_items()
	if selected.is_empty():
		_status_label.text = "Selecciona un nivel para eliminar."
		return
	var level_name := _item_list.get_item_text(selected[0])
	CustomLevelManager.delete_level(level_name)
	_refresh_list()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()
