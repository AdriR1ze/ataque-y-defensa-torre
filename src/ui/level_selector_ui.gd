extends Control
class_name LevelSelectorUI

signal closed
signal level_selected(index: int, level_path: String)

const LEVELS: Array[String] = [
	"res://src/levels/tutorial.tscn",
	"res://src/levels/level_1.tscn",
	"res://src/levels/level_2.tscn",
	"res://src/levels/level_3.tscn",
	"res://src/levels/level_4.tscn",
	"res://src/levels/level_5.tscn",
	"res://src/levels/level_6.tscn",
	"res://src/levels/level_7.tscn",
	"res://src/levels/level_8.tscn",
	"res://src/levels/level_9.tscn",
	"res://src/levels/level_10.tscn"
]

const LEVEL_NAMES: Array[String] = [
	"Tutorial",
	"Nivel 1",
	"Nivel 2",
	"Nivel 3",
	"Nivel 4",
	"Nivel 5",
	"Nivel 6",
	"Nivel 7",
	"Nivel 8",
	"Nivel 9",
	"Nivel 10"
]

const MAIN_GAME_SCENE := "res://src/core/main_game/main_game.tscn"

var current_level_index: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Strict debug mode check
	if not Debug.debug_enabled:
		queue_free()
		return

	Debug.debug_mode_changed.connect(_on_debug_mode_changed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_build_ui()


func _on_debug_mode_changed(enabled: bool) -> void:
	if not enabled:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.75)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var main_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.95)
	style.border_color = Color(0.95, 0.75, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 24
	style.content_margin_top = 20
	style.content_margin_right = 24
	style.content_margin_bottom = 20
	main_panel.add_theme_stylebox_override("panel", style)
	center.add_child(main_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	main_panel.add_child(vbox)

	# Header Title
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = "SELECTOR DE NIVELES [DEBUG]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Selecciona un nivel para cargar directamente"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	title_box.add_child(subtitle)

	vbox.add_child(title_box)

	# Grid of level buttons
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	# Determine current active level if in MainGame
	var main_game := get_tree().get_first_node_in_group("main_game") as Node
	if main_game != null and main_game.get("_current_level_index") != null:
		current_level_index = main_game._current_level_index

	for i in range(LEVELS.size()):
		var btn := Button.new()
		btn.text = LEVEL_NAMES[i]
		btn.custom_minimum_size = Vector2(130.0, 42.0)

		if i == current_level_index:
			btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			btn.text += " (Actual)"

		var index := i
		btn.pressed.connect(func() -> void: _on_level_selected(index))
		grid.add_child(btn)

	# Custom Levels Section
	var custom_levels := CustomLevelManager.list_custom_levels()
	if not custom_levels.is_empty():
		var custom_title := Label.new()
		custom_title.text = "Niveles Personalizados:"
		custom_title.add_theme_font_size_override("font_size", 14)
		custom_title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		vbox.add_child(custom_title)

		var custom_grid := GridContainer.new()
		custom_grid.columns = 3
		custom_grid.add_theme_constant_override("h_separation", 10)
		custom_grid.add_theme_constant_override("v_separation", 10)
		vbox.add_child(custom_grid)

		for c_name in custom_levels:
			var btn := Button.new()
			btn.text = "🛠️ " + c_name
			btn.custom_minimum_size = Vector2(130.0, 42.0)
			var lvl_name := c_name
			btn.pressed.connect(func(): _on_custom_level_selected(lvl_name))
			custom_grid.add_child(btn)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Cerrar"
	close_btn.custom_minimum_size = Vector2(160.0, 40.0)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)


func _on_custom_level_selected(lvl_name: String) -> void:
	var data := CustomLevelManager.load_level(lvl_name)
	if data.is_empty():
		return
	Debug.active_custom_level_data = data
	get_tree().paused = false

	var main_game := get_tree().get_first_node_in_group("main_game") as Node
	if main_game != null and main_game.has_method("load_custom_level"):
		main_game.load_custom_level(data)
	else:
		get_tree().change_scene_to_file(MAIN_GAME_SCENE)
	close()



func _on_level_selected(index: int) -> void:
	if not Debug.debug_enabled:
		close()
		return

	level_selected.emit(index, LEVELS[index])

	var main_game := get_tree().get_first_node_in_group("main_game") as Node
	if main_game != null and main_game.has_method("load_level_by_index"):
		main_game.load_level_by_index(index)
	else:
		Debug.selected_level_index = index
		get_tree().paused = false
		get_tree().change_scene_to_file(MAIN_GAME_SCENE)

	close()


func close() -> void:
	closed.emit()
	queue_free()
