extends CanvasLayer
class_name WaveUI

signal finished

@onready var root: Control = %Root
@onready var countdown_label: Label = %CountdownLabel

var _remaining := 0
var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	root.visible = false


func start_countdown(seconds: int) -> void:
	_remaining = seconds
	root.visible = true
	_update_label()
	_timer.start(1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		_finish()


func _on_tick() -> void:
	_remaining -= 1
	if _remaining <= 0:
		_finish()
	else:
		_update_label()
		_timer.start(1.0)


func _update_label() -> void:
	countdown_label.text = str(_remaining)


func _finish() -> void:
	_timer.stop()
	root.visible = false
	finished.emit()
