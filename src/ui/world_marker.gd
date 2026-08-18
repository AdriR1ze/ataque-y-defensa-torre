extends Sprite3D
class_name WorldMarker

@export var texture_path: String = ""
@export var float_height := 3.0
@export var bob_amplitude := 0.3
@export var bob_speed := 2.0
@export var sprite_scale := 2.0

var _base_y := 0.0


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	if texture_path != "":
		texture = load(texture_path) as Texture2D
	scale = Vector3.ONE * sprite_scale
	position = Vector3(0, float_height, 0)
	_base_y = position.y


func _process(_delta: float) -> void:
	position.y = _base_y + sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_amplitude
