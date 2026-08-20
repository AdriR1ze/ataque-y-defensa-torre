extends CanvasLayer
class_name CombatFocusOverlay

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	layer = 10
	if color_rect != null:
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
