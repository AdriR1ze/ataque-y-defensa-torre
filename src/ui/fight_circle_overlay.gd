extends CanvasLayer
class_name FightCircleOverlay

@onready var color_rect: ColorRect = $ColorRect

var _tween: Tween

func _ready() -> void:
	layer = 10
	if color_rect != null:
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Muestra u oculta la viñeta con una transición suave de opacidad
func set_overlay_visible(is_visible: bool, duration: float = 0.5) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	
	if color_rect == null:
		return

	_tween = create_tween()
	var target_alpha: float = 1.0 if is_visible else 0.0
	_tween.tween_property(color_rect, "modulate:a", target_alpha, duration)


## Ajusta el radio base del círculo transparente
func set_circle_radius(radius: float) -> void:
	if color_rect != null and color_rect.material is ShaderMaterial:
		var mat := color_rect.material as ShaderMaterial
		mat.set_shader_parameter("base_radius", radius)


## Ajusta la intensidad del ruido/rugosidad del borde
func set_noise_intensity(intensity: float) -> void:
	if color_rect != null and color_rect.material is ShaderMaterial:
		var mat := color_rect.material as ShaderMaterial
		mat.set_shader_parameter("noise_intensity", intensity)


## Cambia el color exterior (por defecto blanco)
func set_outer_color(color: Color) -> void:
	if color_rect != null and color_rect.material is ShaderMaterial:
		var mat := color_rect.material as ShaderMaterial
		mat.set_shader_parameter("outer_color", color)
