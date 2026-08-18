extends Button
class_name TrapSlot


signal trap_dropped(
	slot: int,
	data: Dictionary
)


const COLOR_EMPTY := Color(0.09, 0.10, 0.13)
const COLOR_FILLED := Color(0.15, 0.14, 0.09)
const COLOR_BORDER := Color(1.0, 1.0, 1.0, 0.08)
const COLOR_ACCENT := Color(0.94, 0.71, 0.27)
const COLOR_TEXT := Color(0.93, 0.95, 0.98)
const COLOR_TEXT_MUTED := Color(0.56, 0.60, 0.68)


var slot: int
var trap_data: TrapData


var key_label: Label
var icon_: TextureRect
var name_label: Label

var _empty_style: StyleBoxFlat
var _filled_style: StyleBoxFlat


func setup(p_slot: int, key: String) -> void:

	slot = p_slot

	custom_minimum_size = Vector2(
		72,
		70
	)

	mouse_default_cursor_shape = Control.CURSOR_MOVE

	_build(key)


func _build(key: String) -> void:

	clip_contents = true


	_empty_style = _make_style(
		COLOR_EMPTY,
		12,
		COLOR_BORDER,
		1
	)

	_filled_style = _make_style(
		COLOR_FILLED,
		12,
		COLOR_ACCENT,
		1
	)

	add_theme_stylebox_override("normal", _empty_style)

	add_theme_stylebox_override(
		"hover",
		_make_style(
			Color(1.0, 1.0, 1.0, 0.04),
			12,
			COLOR_ACCENT,
			1
		)
	)

	add_theme_stylebox_override(
		"pressed",
		_make_style(
			Color(1.0, 1.0, 1.0, 0.08),
			12,
			COLOR_ACCENT,
			1
		)
	)


	var box := VBoxContainer.new()

	box.alignment = BoxContainer.ALIGNMENT_CENTER

	box.add_theme_constant_override(
		"separation",
		2
	)

	add_child(box)


	key_label = Label.new()

	key_label.text = key

	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	key_label.add_theme_color_override(
		"font_color",
		COLOR_ACCENT
	)

	key_label.add_theme_font_size_override(
		"font_size",
		10
	)

	box.add_child(key_label)


	icon_ = TextureRect.new()

	icon_.custom_minimum_size = Vector2(
		32,
		32
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
		9
	)

	box.add_child(name_label)


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


func set_trap(data: TrapData) -> void:

	trap_data = data

	if data == null:

		icon_.texture = null
		name_label.text = "Vacío"

		name_label.add_theme_color_override(
			"font_color",
			COLOR_TEXT_MUTED
		)

		add_theme_stylebox_override(
			"normal",
			_empty_style
		)

	else:

		icon_.texture = data.icon
		name_label.text = data.trap_name

		name_label.add_theme_color_override(
			"font_color",
			COLOR_TEXT
		)

		add_theme_stylebox_override(
			"normal",
			_filled_style
		)


func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:

	return (
		data is Dictionary
		and data.get("type", "") == "trap"
	)


func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:

	trap_dropped.emit(
		slot,
		data
	)


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
		"trap_id": trap_data.id,
		"from_slot": slot
	}
