extends Control

@onready var fps_label: Label = %FpsLabel
@onready var debug_label: Label = %DebugLabel


func _process(_delta: float) -> void:
	fps_label.text = "FPS " + str(Engine.get_frames_per_second())

	var level := get_tree().get_first_node_in_group("current_level")
	var level_text := "Sin nivel"
	if level != null:
		level_text = str(level)

	debug_label.text = "Nivel: %s | Debug: %s" % [
		level_text,
		"ON" if Debug.debug_enabled else "OFF"
	]
