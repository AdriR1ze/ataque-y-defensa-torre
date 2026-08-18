extends Control
class_name TrapSelectionUI


signal selection_confirmed(selection: Dictionary)


const COLOR_BACKDROP := Color(0.02, 0.03, 0.05, 0.92)
const COLOR_SURFACE := Color(0.07, 0.08, 0.11)
const COLOR_SURFACE_ALT := Color(0.10, 0.11, 0.15)
const COLOR_ELEVATED := Color(0.13, 0.15, 0.20)
const COLOR_BORDER := Color(1.0, 1.0, 1.0, 0.08)
const COLOR_BORDER_STRONG := Color(1.0, 1.0, 1.0, 0.16)
const COLOR_ACCENT := Color(0.94, 0.71, 0.27)
const COLOR_ACCENT_HOVER := Color(1.0, 0.80, 0.40)
const COLOR_ACCENT_PRESSED := Color(0.72, 0.52, 0.16)
const COLOR_TEXT := Color(0.93, 0.95, 0.98)
const COLOR_TEXT_MUTED := Color(0.56, 0.60, 0.68)
const COLOR_TEXT_DARK := Color(0.10, 0.08, 0.04)


var trap_manager: TrapManager


var trap_cards_container: GridContainer
var slots_container: HBoxContainer

var info_panel: TrapInfoPanel

var confirm_button: Button
var clear_button: Button

var selected_card_id := 0

var slot_nodes: Dictionary = {}
var card_nodes: Dictionary = {}


func setup(manager: TrapManager) -> void:
	trap_manager = manager
	_build_ui()
	_connect_manager()
	_refresh()


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _connect_manager() -> void:

	if trap_manager == null:
		return

	if not trap_manager.loadout_changed.is_connected(
		_refresh
	):
		trap_manager.loadout_changed.connect(
			_refresh
		)


func _build_ui() -> void:

	mouse_filter = Control.MOUSE_FILTER_STOP

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	# ============================================================
	# BACKDROP
	# ============================================================

	var backdrop := ColorRect.new()

	backdrop.color = COLOR_BACKDROP

	backdrop.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	add_child(backdrop)


	# ============================================================
	# PANEL (fills screen with a small margin)
	# ============================================================

	var outer := MarginContainer.new()

	outer.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	outer.add_theme_constant_override("margin_left", 0)
	outer.add_theme_constant_override("margin_right", 0)
	outer.add_theme_constant_override("margin_top", 0)
	outer.add_theme_constant_override("margin_bottom", 0)

	add_child(outer)


	var panel := PanelContainer.new()

	panel.add_theme_stylebox_override(
		"panel",
		_make_style(
			COLOR_SURFACE,
			0,
			COLOR_BORDER,
			0
		)
	)

	outer.add_child(panel)


	var margin := MarginContainer.new()

	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)

	panel.add_child(margin)


	var main := VBoxContainer.new()

	main.add_theme_constant_override(
		"separation",
		10
	)

	margin.add_child(main)


	# ============================================================
	# HEADER
	# ============================================================

	var header := VBoxContainer.new()

	header.add_theme_constant_override(
		"separation",
		4
	)

	main.add_child(header)


	var title := Label.new()

	title.text = "PREPARACIÓN DE DEFENSA"

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_color_override(
		"font_color",
		COLOR_ACCENT
	)

	title.add_theme_font_size_override(
		"font_size",
		26
	)

	header.add_child(title)


	var subtitle := Label.new()

	subtitle.text = (
		"Arrastrá las trampas a los huecos para equiparlas"
	)

	subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	subtitle.add_theme_color_override(
		"font_color",
		COLOR_TEXT_MUTED
	)

	subtitle.add_theme_font_size_override(
		"font_size",
		14
	)

	header.add_child(subtitle)


	# ============================================================
	# CONTENT (traps + info)
	# ============================================================

	var content := HBoxContainer.new()

	content.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_theme_constant_override(
		"separation",
		14
	)

	main.add_child(content)


	var traps_panel := VBoxContainer.new()

	traps_panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	traps_panel.add_theme_constant_override(
		"separation",
		8
	)

	content.add_child(traps_panel)


	traps_panel.add_child(
		_section_label("TRAMPAS DISPONIBLES", false)
	)


	var scroll := ScrollContainer.new()

	scroll.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	scroll.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)

	traps_panel.add_child(scroll)


	trap_cards_container = GridContainer.new()

	trap_cards_container.columns = 4

	trap_cards_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	trap_cards_container.add_theme_constant_override(
		"h_separation",
		10
	)

	trap_cards_container.add_theme_constant_override(
		"v_separation",
		10
	)

	scroll.add_child(trap_cards_container)


	# ============================================================
	# INFO
	# ============================================================

	info_panel = TrapInfoPanel.new()

	content.add_child(info_panel)


	# ============================================================
	# LOADOUT
	# ============================================================

	main.add_child(
		_section_label("TRAMPAS EQUIPADAS", true)
	)


	slots_container = HBoxContainer.new()

	slots_container.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	slots_container.add_theme_constant_override(
		"separation",
		6
	)

	main.add_child(slots_container)


	# ============================================================
	# FOOTER
	# ============================================================

	var footer := HBoxContainer.new()

	footer.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	footer.add_theme_constant_override(
		"separation",
		16
	)

	main.add_child(footer)


	clear_button = Button.new()

	clear_button.text = "Limpiar"

	clear_button.custom_minimum_size = Vector2(
		130,
		40
	)

	clear_button.pressed.connect(
		_on_clear_pressed
	)

	_style_button(clear_button, false)

	footer.add_child(clear_button)


	confirm_button = Button.new()

	confirm_button.text = "COMENZAR →"

	confirm_button.custom_minimum_size = Vector2(
		200,
		46
	)

	confirm_button.pressed.connect(
		_on_confirm_pressed
	)

	_style_button(confirm_button, true)

	footer.add_child(confirm_button)


	_build_cards()
	_build_slots()


# ============================================================
# STYLE HELPERS
# ============================================================

func _make_style(
	bg: Color,
	radius: int,
	border: Color = Color.TRANSPARENT,
	border_width: int = 0
) -> StyleBoxFlat:

	var style := StyleBoxFlat.new()

	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(border_width)

	return style


func _section_label(text: String, centered: bool) -> HBoxContainer:

	var box := HBoxContainer.new()

	box.add_theme_constant_override(
		"separation",
		6
	)

	if centered:
		box.alignment = BoxContainer.ALIGNMENT_CENTER


	var bullet := Label.new()

	bullet.text = "▸"

	bullet.add_theme_color_override(
		"font_color",
		COLOR_ACCENT
	)

	bullet.add_theme_font_size_override(
		"font_size",
		13
	)

	box.add_child(bullet)


	var label := Label.new()

	label.text = text

	label.add_theme_color_override(
		"font_color",
		COLOR_TEXT_MUTED
	)

	label.add_theme_font_size_override(
		"font_size",
		13
	)

	box.add_child(label)

	return box


func _style_button(button: Button, primary: bool) -> void:

	if primary:

		button.add_theme_stylebox_override(
			"normal",
			_make_style(COLOR_ACCENT, 10)
		)

		button.add_theme_stylebox_override(
			"hover",
			_make_style(COLOR_ACCENT_HOVER, 10)
		)

		button.add_theme_stylebox_override(
			"pressed",
			_make_style(COLOR_ACCENT_PRESSED, 10)
		)

		button.add_theme_stylebox_override(
			"disabled",
			_make_style(Color(0.20, 0.21, 0.24), 10)
		)

		button.add_theme_stylebox_override(
			"focus",
			_make_style(
				Color.TRANSPARENT,
				10,
				COLOR_ACCENT,
				2
			)
		)

		button.add_theme_color_override(
			"font_color",
			COLOR_TEXT_DARK
		)

		button.add_theme_color_override(
			"font_hover_color",
			COLOR_TEXT_DARK
		)

		button.add_theme_color_override(
			"font_pressed_color",
			COLOR_TEXT_DARK
		)

		button.add_theme_color_override(
			"font_disabled_color",
			Color(0.50, 0.50, 0.53)
		)

		button.add_theme_color_override(
			"font_focus_color",
			COLOR_TEXT_DARK
		)

	else:

		button.add_theme_stylebox_override(
			"normal",
			_make_style(
				Color.TRANSPARENT,
				10,
				COLOR_BORDER_STRONG,
				1
			)
		)

		button.add_theme_stylebox_override(
			"hover",
			_make_style(
				Color(1.0, 1.0, 1.0, 0.04),
				10,
				COLOR_ACCENT,
				1
			)
		)

		button.add_theme_stylebox_override(
			"pressed",
			_make_style(
				Color(1.0, 1.0, 1.0, 0.08),
				10,
				COLOR_ACCENT,
				1
			)
		)

		button.add_theme_stylebox_override(
			"disabled",
			_make_style(
				Color.TRANSPARENT,
				10,
				COLOR_BORDER,
				1
			)
		)

		button.add_theme_stylebox_override(
			"focus",
			_make_style(
				Color.TRANSPARENT,
				10,
				COLOR_ACCENT,
				1
			)
		)

		button.add_theme_color_override(
			"font_color",
			COLOR_TEXT
		)

		button.add_theme_color_override(
			"font_hover_color",
			COLOR_ACCENT
		)

		button.add_theme_color_override(
			"font_pressed_color",
			COLOR_ACCENT
		)

		button.add_theme_color_override(
			"font_disabled_color",
			COLOR_TEXT_MUTED
		)

		button.add_theme_color_override(
			"font_focus_color",
			COLOR_TEXT
		)

	button.add_theme_font_size_override(
		"font_size",
		16
	)


# ============================================================
# CARDS
# ============================================================

func _build_cards() -> void:

	if trap_manager == null:
		return

	for child in trap_cards_container.get_children():
		child.queue_free()

	card_nodes.clear()

	for trap_id in trap_manager.get_trap_ids():

		var data := trap_manager.get_trap(trap_id)

		if data == null:
			continue

		var card := TrapCard.new()

		trap_cards_container.add_child(card)

		card.setup(data)

		card.trap_selected.connect(
			_on_trap_selected
		)

		card_nodes[trap_id] = card


func _build_slots() -> void:

	if trap_manager == null:
		return

	for child in slots_container.get_children():
		child.queue_free()

	slot_nodes.clear()

	var labels := trap_manager.get_slot_labels()

	for slot in range(
		1,
		trap_manager.get_slot_count() + 1
	):

		var slot_node := TrapSlot.new()

		slots_container.add_child(slot_node)

		slot_node.setup(
			slot,
			labels[slot]
		)

		slot_node.trap_dropped.connect(
			_on_slot_dropped
		)

		slot_node.pressed.connect(
			_on_slot_pressed.bind(slot)
		)

		slot_nodes[slot] = slot_node


# ============================================================
# HANDLERS
# ============================================================

func _on_trap_selected(trap_id: int) -> void:

	selected_card_id = trap_id

	for card_id in card_nodes:
		var card: TrapCard = card_nodes[card_id]
		card.set_selected(card_id == trap_id)

	var data := trap_manager.get_trap(
		trap_id
	)

	info_panel.show_trap(data)


func _on_slot_pressed(slot: int) -> void:

	if selected_card_id == 0:
		return

	trap_manager.set_slot_trap(
		slot,
		selected_card_id
	)

	_refresh()


func _on_slot_dropped(
	slot: int,
	data: Dictionary
) -> void:

	var trap_id: int = data.get(
		"trap_id",
		0
	)

	if trap_id == 0:
		return

	var from_slot: int = data.get(
		"from_slot",
		0
	)

	# Si ya existe en otro slot, la movemos.
	if from_slot != 0 and from_slot != slot:

		trap_manager.set_slot_trap(
			from_slot,
			0
		)

	trap_manager.set_slot_trap(
		slot,
		trap_id
	)

	_refresh()


func _on_clear_pressed() -> void:

	trap_manager.clear_selection()

	_refresh()


func _on_confirm_pressed() -> void:

	if not trap_manager.has_any_trap():
		return

	selection_confirmed.emit(
		trap_manager.get_selection()
	)


# ============================================================
# REFRESH
# ============================================================

func _refresh() -> void:

	if trap_manager == null:
		return

	_refresh_slots()

	_refresh_button()


func _refresh_slots() -> void:

	for slot in slot_nodes:

		var slot_node: TrapSlot = slot_nodes[slot]

		var trap_id := trap_manager.get_slot_trap(
			slot
		)

		if trap_id == 0:

			slot_node.set_trap(null)

		else:

			var data := trap_manager.get_trap(
				trap_id
			)

			slot_node.set_trap(data)


func _refresh_button() -> void:

	confirm_button.disabled = not trap_manager.has_any_trap()
