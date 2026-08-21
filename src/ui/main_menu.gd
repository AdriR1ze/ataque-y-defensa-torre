extends Control
class_name MainMenu

const MAIN_GAME_SCENE := "res://src/core/main_game/main_game.tscn"
const OPTIONS_MENU := preload("res://src/ui/options_menu.tscn")


var _debug_level_btn: Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Music.set_game_state(Music.State.MENU)
	Debug.debug_mode_changed.connect(_on_debug_mode_changed)
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.05, 0.05, 0.08, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 14)
	center.add_child(panel)

	var title := Label.new()
	title.text = "ATAQUE Y DEFENSA TORRE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	panel.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 12.0)
	panel.add_child(spacer)

	const LEVEL_EDITOR_SCENE := "res://src/ui/level_editor/level_editor.tscn"

	var play := Button.new()
	play.text = "Jugar"
	play.custom_minimum_size = Vector2(220.0, 48.0)
	play.pressed.connect(_on_play_pressed)
	panel.add_child(play)

	var editor_btn := Button.new()
	editor_btn.text = "Editor de Niveles"
	editor_btn.custom_minimum_size = Vector2(220.0, 48.0)
	editor_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	editor_btn.pressed.connect(func(): get_tree().change_scene_to_file(LEVEL_EDITOR_SCENE))
	panel.add_child(editor_btn)

	_debug_level_btn = Button.new()
	_debug_level_btn.text = "Selector de Niveles (DEBUG)"

	_debug_level_btn.custom_minimum_size = Vector2(220.0, 48.0)
	_debug_level_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_debug_level_btn.pressed.connect(_on_debug_level_selector_pressed)
	_debug_level_btn.visible = Debug.debug_enabled
	panel.add_child(_debug_level_btn)

	var options := Button.new()
	options.text = "Opciones"
	options.custom_minimum_size = Vector2(220.0, 48.0)
	options.pressed.connect(_on_options_pressed)
	panel.add_child(options)

	var quit := Button.new()
	quit.text = "Salir"
	quit.custom_minimum_size = Vector2(220.0, 48.0)
	quit.pressed.connect(_on_quit_pressed)
	panel.add_child(quit)


func _on_debug_mode_changed(enabled: bool) -> void:
	if _debug_level_btn != null:
		_debug_level_btn.visible = enabled


func _on_debug_level_selector_pressed() -> void:
	if Debug.debug_enabled:
		Debug.open_level_selector(self)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)


func _on_options_pressed() -> void:
	var options := OPTIONS_MENU.instantiate() as OptionsMenu
	options.closed.connect(options.queue_free)
	add_child(options)


func _on_quit_pressed() -> void:
	get_tree().quit()

