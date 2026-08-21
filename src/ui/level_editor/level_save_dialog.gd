extends Control
class_name LevelSaveDialog

signal level_saved(file_name: String)
signal cancelled

var _line_edit: LineEdit
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
	panel.custom_minimum_size = Vector2(400, 350)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.95)
	style.border_color = Color(0.3, 0.7, 1.0)
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
	title.text = "GUARDAR NIVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(title)

	var label := Label.new()
	label.text = "Nombre del archivo:"
	label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(label)

	_line_edit = LineEdit.new()
	_line_edit.placeholder_text = "mi_nivel_custom"
	_line_edit.custom_minimum_size = Vector2(0, 36)
	_line_edit.text_submitted.connect(func(_t): _on_save_pressed())
	vbox.add_child(_line_edit)

	var overwrite_label := Label.new()
	overwrite_label.text = "Niveles existentes (haz clic para sobrescribir):"
	overwrite_label.add_theme_font_size_override("font_size", 12)
	overwrite_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(overwrite_label)

	_item_list = ItemList.new()
	_item_list.custom_minimum_size = Vector2(0, 120)
	_item_list.item_selected.connect(_on_item_selected)
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

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(100, 36)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	hbox.add_child(cancel_btn)

	var save_btn := Button.new()
	save_btn.text = "Guardar"
	save_btn.custom_minimum_size = Vector2(110, 36)
	save_btn.pressed.connect(_on_save_pressed)
	hbox.add_child(save_btn)


func set_default_name(default_name: String) -> void:
	if _line_edit != null:
		_line_edit.text = CustomLevelManager.sanitize_filename(default_name)


func _refresh_list() -> void:
	_item_list.clear()
	var levels := CustomLevelManager.list_custom_levels()
	for lvl in levels:
		_item_list.add_item(lvl)


func _on_item_selected(index: int) -> void:
	if index >= 0 and index < _item_list.item_count:
		_line_edit.text = _item_list.get_item_text(index)


func _on_save_pressed() -> void:
	var name_text := _line_edit.text.strip_edges()
	if name_text.is_empty():
		_status_label.text = "Por favor ingresa un nombre válido."
		return
	level_saved.emit(name_text)
	queue_free()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()
