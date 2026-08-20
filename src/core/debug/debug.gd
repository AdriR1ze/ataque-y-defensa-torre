extends Node

signal debug_mode_changed(enabled: bool)

var debug_enabled := false
var selected_level_index: int = -1

const LEVEL_SELECTOR_SCENE := preload("res://src/ui/level_selector_ui.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_MINUS or event.physical_keycode == KEY_KP_SUBTRACT:
			toggle_debug()


func toggle_debug() -> void:
	debug_enabled = not debug_enabled
	debug_mode_changed.emit(debug_enabled)


func open_level_selector(parent: Node) -> void:
	if not debug_enabled:
		return
	var selector := LEVEL_SELECTOR_SCENE.instantiate() as LevelSelectorUI
	parent.add_child(selector)

