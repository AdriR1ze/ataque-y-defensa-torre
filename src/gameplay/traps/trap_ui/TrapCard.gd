extends Button
class_name TrapCard


signal trap_selected(trap_id: int)


const COLOR_CARD := Color(0.13, 0.15, 0.20)
const COLOR_CARD_HOVER := Color(0.17, 0.19, 0.25)
const COLOR_CARD_PRESSED := Color(0.10, 0.11, 0.15)
const COLOR_CARD_SELECTED := Color(0.17, 0.15, 0.10)
const COLOR_BORDER := Color(1.0, 1.0, 1.0, 0.07)
const COLOR_ACCENT := Color(0.94, 0.71, 0.27)
const COLOR_TEXT := Color(0.93, 0.95, 0.98)
const COLOR_TEXT_MUTED := Color(0.56, 0.60, 0.68)


var trap_data: TrapData


var icon_: TextureRect
var name_label: Label
var cost_label: Label

var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _pressed_style: StyleBoxFlat
var _selected_style: StyleBoxFlat


func setup(data: TrapData) -> void:

	trap_data = data

	_build()

	_refresh()


func _build() -> void:

	custom_minimum_size = Vector2(130, 170)

	mouse_default_cursor_shape = Control.CURSOR_DRAG

	clip_contents = true


	_normal_style = _make_style(
		COLOR_CARD,
		12,
		COLOR_BORDER,
		1
	)

	_hover_style = _make_style(
		COLOR_CARD_HOVER,
		12,
		COLOR_ACCENT,
		1
	)

	_pressed_style = _make_style(
		COLOR_CARD_PRESSED,
		12,
		COLOR_ACCENT,
		1
	)

	_selected_style = _make_style(
		COLOR_CARD_SELECTED,
		12,
		COLOR_ACCENT,
		2
	)

	add_theme_stylebox_override("normal", _normal_style)
	add_theme_stylebox_override("hover", _hover_style)
	add_theme_stylebox_override("pressed", _pressed_style)
	add_theme_stylebox_override(
		"focus",
		_make_style(
			Color.TRANSPARENT,
			12,
			COLOR_ACCENT,
			1
		)
	)


	var margin := MarginContainer.new()

	margin.add_theme_constant_override(
		"margin_left",
		10
	)

	margin.add_theme_constant_override(
		"margin_right",
		10
	)

	margin.add_theme_constant_override(
		"margin_top",
		10
	)

	margin.add_theme_constant_override(
		"margin_bottom",
		10
	)

	add_child(margin)


	var box := VBoxContainer.new()

	box.alignment = BoxContainer.ALIGNMENT_CENTER

	box.add_theme_constant_override(
		"separation",
		6
	)

	margin.add_child(box)


	icon_ = TextureRect.new()

	icon_.custom_minimum_size = Vector2(
		72,
		72
	)

	icon_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	box.add_child(icon_)


	name_label = Label.new()

	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	name_label.add_theme_color_override(
		"font_color",
		COLOR_TEXT
	)

	name_label.add_theme_font_size_override(
		"font_size",
		15
	)

	box.add_child(name_label)


	cost_label = Label.new()

	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	cost_label.add_theme_color_override(
		"font_color",
		COLOR_ACCENT
	)

	cost_label.add_theme_font_size_override(
		"font_size",
		14
	)

	box.add_child(cost_label)


	pressed.connect(_on_pressed)


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


func _refresh() -> void:

	if trap_data == null:
		return

	name_label.text = trap_data.trap_name

	icon_.texture = trap_data.icon

	if trap_data.cost > 0:
		cost_label.text = "%d 🪙" % trap_data.cost
	else:
		cost_label.text = ""


func set_selected(selected: bool) -> void:

	add_theme_stylebox_override(
		"normal",
		_selected_style if selected else _normal_style
	)


func _on_pressed() -> void:

	if trap_data == null:
		return

	trap_selected.emit(trap_data.id)


func _get_drag_data(
	_at_position: Vector2
) -> Variant:

	if trap_data == null:
		return null

	var preview := Label.new()

	preview.text = trap_data.trap_name

	preview.add_theme_color_override(
		"font_color",
		COLOR_ACCENT
	)

	preview.add_theme_font_size_override(
		"font_size",
		18
	)

	set_drag_preview(preview)

	return {
		"type": "trap",
		"trap_id": trap_data.id
	}
