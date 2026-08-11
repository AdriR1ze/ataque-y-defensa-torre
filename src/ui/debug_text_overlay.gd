extends Control

@onready var fps_label : Label = %FpsLabel

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	fps_label.set_text("FPS" + str(Engine.get_frames_per_second()))
