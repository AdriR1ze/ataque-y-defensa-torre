extends Node

signal debug_mode_changed(enabled: bool)

var debug_enabled := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_MINUS or event.physical_keycode == KEY_KP_SUBTRACT:
			toggle_debug()


func toggle_debug() -> void:
	debug_enabled = not debug_enabled
	debug_mode_changed.emit(debug_enabled)
