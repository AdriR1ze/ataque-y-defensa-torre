extends CanvasLayer
class_name RespawnScreen

var _timer_label: Label
var _seconds_left := 3.0


func _ready() -> void:
	layer = 10

	# Root control que ocupa TODO el viewport (necesario para que los hijos
	# tengan referencia de tamaño correcta con stretch=canvas_items)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Overlay oscuro rojo
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.35, 0.0, 0.0, 0.72)
	root.add_child(bg)

	# VBox centrada usando anchors al 50% + offset negativo de la mitad del tamaño
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	var vbox_w := 500.0
	var vbox_h := 220.0
	vbox.anchor_left   = 0.5
	vbox.anchor_top    = 0.5
	vbox.anchor_right  = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left   = -vbox_w / 2.0
	vbox.offset_top    = -vbox_h / 2.0
	vbox.offset_right  =  vbox_w / 2.0
	vbox.offset_bottom =  vbox_h / 2.0
	root.add_child(vbox)

	# Título
	var title := Label.new()
	title.text = "HAS MUERTO"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title)

	# Subtítulo
	var sub := Label.new()
	sub.text = "Reapareciendo cerca de la base..."
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.85, 0.75, 0.75))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(sub)

	# Cuenta regresiva
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 44)
	_timer_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_timer_label)

	_update_timer_label()


func _process(delta: float) -> void:
	_seconds_left = maxf(0.0, _seconds_left - delta)
	_update_timer_label()


func _update_timer_label() -> void:
	if _timer_label != null:
		_timer_label.text = str(ceili(_seconds_left))
