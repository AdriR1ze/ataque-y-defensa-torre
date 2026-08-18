extends PanelContainer
class_name TrapInfoPanel


const COLOR_PANEL := Color(0.10, 0.11, 0.15)
const COLOR_BORDER := Color(1.0, 1.0, 1.0, 0.07)
const COLOR_ACCENT := Color(0.94, 0.71, 0.27)
const COLOR_TEXT := Color(0.93, 0.95, 0.98)
const COLOR_TEXT_MUTED := Color(0.56, 0.60, 0.68)


var icon: TextureRect
var title_label: Label
var description_label: Label

var damage_label: Label
var cooldown_label: Label
var range_label: Label
var cost_label: Label

var details_box: VBoxContainer
var placeholder: Label

var stats_grid: GridContainer


func _ready() -> void:
	_build()


func _build() -> void:

	custom_minimum_size = Vector2(
		220,
		0
	)

	add_theme_stylebox_override(
		"panel",
		_make_style(
			COLOR_PANEL,
			12,
			COLOR_BORDER,
			1
		)
	)


	var margin := MarginContainer.new()

	margin.add_theme_constant_override(
		"margin_left",
		14
	)

	margin.add_theme_constant_override(
		"margin_right",
		14
	)

	margin.add_theme_constant_override(
		"margin_top",
		14
	)

	margin.add_theme_constant_override(
		"margin_bottom",
		14
	)

	add_child(margin)


	var root := VBoxContainer.new()

	margin.add_child(root)


	placeholder = Label.new()

	placeholder.text = (
		"Seleccioná una trampa\npara ver sus detalles"
	)

	placeholder.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	placeholder.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	placeholder.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	placeholder.add_theme_color_override(
		"font_color",
		COLOR_TEXT_MUTED
	)

	placeholder.add_theme_font_size_override(
		"font_size",
		14
	)

	root.add_child(placeholder)


	details_box = VBoxContainer.new()

	details_box.add_theme_constant_override(
		"separation",
		8
	)

	root.add_child(details_box)


	icon = TextureRect.new()

	icon.custom_minimum_size = Vector2(
		44,
		44
	)

	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	details_box.add_child(icon)


	title_label = Label.new()

	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title_label.add_theme_color_override(
		"font_color",
		COLOR_TEXT
	)

	title_label.add_theme_font_size_override(
		"font_size",
		18
	)

	details_box.add_child(title_label)


	description_label = Label.new()

	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	description_label.add_theme_color_override(
		"font_color",
		COLOR_TEXT_MUTED
	)

	description_label.add_theme_font_size_override(
		"font_size",
		13
	)

	details_box.add_child(description_label)


	var separator := HSeparator.new()

	details_box.add_child(separator)


	stats_grid = GridContainer.new()

	stats_grid.columns = 2

	stats_grid.add_theme_constant_override(
		"h_separation",
		10
	)

	stats_grid.add_theme_constant_override(
		"v_separation",
		6
	)

	details_box.add_child(stats_grid)


	damage_label = _stat_row()
	cooldown_label = _stat_row()
	range_label = _stat_row()
	cost_label = _stat_row()


	show_trap(null)


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


func _stat_row() -> Label:

	var row := HBoxContainer.new()

	row.add_theme_constant_override(
		"separation",
		6
	)

	stats_grid.add_child(row)


	var bullet := Label.new()

	bullet.text = "▪"

	bullet.add_theme_color_override(
		"font_color",
		COLOR_ACCENT
	)

	bullet.add_theme_font_size_override(
		"font_size",
		12
	)

	row.add_child(bullet)


	var label := Label.new()

	label.add_theme_color_override(
		"font_color",
		COLOR_TEXT
	)

	label.add_theme_font_size_override(
		"font_size",
		12
	)

	row.add_child(label)

	return label


func _stat_text(key: String, value: String) -> String:

	return "%s %s" % [key, value]


func show_trap(data: TrapData) -> void:

	if data == null:

		details_box.hide()
		placeholder.show()
		return

	placeholder.hide()
	details_box.show()

	icon.texture = data.icon

	title_label.text = data.trap_name

	description_label.text = data.description

	damage_label.text = _stat_text(
		"Daño",
		"%.0f" % data.damage
	)

	cooldown_label.text = _stat_text(
		"Recarga",
		"%.1fs" % data.cooldown
	)

	range_label.text = _stat_text(
		"Alcance",
		"%.1fm" % data.range
	)

	cost_label.text = _stat_text(
		"Costo",
		"%d" % data.cost
	)
