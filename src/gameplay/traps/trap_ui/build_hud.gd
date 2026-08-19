extends Control
class_name BuildHUD


const COLOR_BG := Color(0.02, 0.03, 0.05, 0.85)
const COLOR_EMPTY := Color(0.09, 0.10, 0.13)
const COLOR_FILLED := Color(0.15, 0.14, 0.09)
const COLOR_SELECTED := Color(0.22, 0.19, 0.10)
const COLOR_BORDER := Color(1.0, 1.0, 1.0, 0.08)
const COLOR_ACCENT := Color(0.94, 0.71, 0.27)
const COLOR_TEXT := Color(0.93, 0.95, 0.98)
const COLOR_TEXT_MUTED := Color(0.56, 0.60, 0.68)
const COLOR_UNAFFORDABLE := Color(1.0, 0.25, 0.25)


var trap_manager: TrapManager

var slot_nodes: Dictionary = {}


func setup(manager: TrapManager) -> void:
	trap_manager = manager
	_build_ui()
	_connect_manager()
	_refresh()


func _connect_manager() -> void:
	if trap_manager == null:
		return

	trap_manager.loadout_changed.connect(_refresh)
	trap_manager.selected_slot_changed.connect(_on_selected_slot_changed)
	Economy.money_changed.connect(_on_money_changed)


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()

	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	add_child(vbox)


	var spacer := Control.new()

	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	vbox.add_child(spacer)


	var center := CenterContainer.new()

	center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	vbox.add_child(center)


	var bar := PanelContainer.new()

	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	bar.add_theme_stylebox_override(
		"panel",
		_make_style(COLOR_BG, 14, COLOR_BORDER, 1)
	)

	center.add_child(bar)


	var margin := MarginContainer.new()

	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE

	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 8)

	bar.add_child(margin)


	var hbox := HBoxContainer.new()

	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	hbox.add_theme_constant_override("separation", 6)

	margin.add_child(hbox)


	var labels := trap_manager.get_slot_labels()

	for slot in range(1, trap_manager.get_slot_count() + 1):
		hbox.add_child(_build_slot(slot, labels[slot]))


func _build_slot(slot: int, key: String) -> PanelContainer:

	var panel := PanelContainer.new()

	panel.custom_minimum_size = Vector2(64, 64)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE


	var box := VBoxContainer.new()

	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	box.add_theme_constant_override("separation", 2)

	panel.add_child(box)


	var key_label := Label.new()

	key_label.text = key
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	key_label.add_theme_color_override(
		"font_color",
		COLOR_ACCENT
	)

	key_label.add_theme_font_size_override("font_size", 10)

	box.add_child(key_label)


	var icon := TextureRect.new()

	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	box.add_child(icon)


	var cost_label := Label.new()

	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	cost_label.add_theme_color_override(
		"font_color",
		COLOR_TEXT
	)

	cost_label.add_theme_font_size_override("font_size", 12)

	box.add_child(cost_label)


	slot_nodes[slot] = {
		"panel": panel,
		"icon": icon,
		"cost": cost_label,
	}

	return panel


func _refresh() -> void:
	if trap_manager == null:
		return

	for slot in slot_nodes:
		_refresh_slot(slot)


func _refresh_slot(slot: int) -> void:

	var nodes: Dictionary = slot_nodes[slot]

	var panel: PanelContainer = nodes["panel"]
	var icon: TextureRect = nodes["icon"]
	var cost_label: Label = nodes["cost"]

	var trap_id := trap_manager.get_slot_trap(slot)

	if trap_id == 0:
		icon.texture = null
		cost_label.text = ""

		panel.add_theme_stylebox_override(
			"panel",
			_make_style(COLOR_EMPTY, 12, COLOR_BORDER, 1)
		)
		return

	var data := trap_manager.get_trap(trap_id)

	icon.texture = data.icon
	cost_label.text = "$%d" % data.cost

	var selected := slot == trap_manager.selected_slot

	if selected:
		panel.add_theme_stylebox_override(
			"panel",
			_make_style(COLOR_SELECTED, 12, COLOR_ACCENT, 2)
		)
	else:
		panel.add_theme_stylebox_override(
			"panel",
			_make_style(COLOR_FILLED, 12, COLOR_BORDER, 1)
		)

	if Economy.can_afford(data.cost):
		cost_label.add_theme_color_override("font_color", COLOR_TEXT)
	else:
		cost_label.add_theme_color_override("font_color", COLOR_UNAFFORDABLE)


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


func _on_selected_slot_changed(_slot: int) -> void:
	_refresh()


func _on_money_changed(_current: int) -> void:
	_refresh()
