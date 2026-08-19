extends Control
class_name MainMenu

const MAIN_GAME_SCENE := "res://src/core/main_game/main_game.tscn"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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

	var play := Button.new()
	play.text = "Jugar"
	play.custom_minimum_size = Vector2(220.0, 48.0)
	play.pressed.connect(_on_play_pressed)
	panel.add_child(play)

	var quit := Button.new()
	quit.text = "Salir"
	quit.custom_minimum_size = Vector2(220.0, 48.0)
	quit.pressed.connect(_on_quit_pressed)
	panel.add_child(quit)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
