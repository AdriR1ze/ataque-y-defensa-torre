extends Node

signal audio_changed
signal video_changed
signal controls_changed


const SETTINGS_PATH := "user://settings.cfg"

const DEFAULT_RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

const RESOLUTION_LABELS := [
	"1280 x 720",
	"1600 x 900",
	"1920 x 1080",
	"2560 x 1440",
]

const REMAPPABLE_ACTIONS := [
	"move_forward",
	"move_backward",
	"move_left",
	"move_right",
	"jump",
	"interact",
	"attacking",
	"pause",
]

const ACTION_LABELS := {
	"move_forward": "Mover adelante",
	"move_backward": "Mover atrás",
	"move_left": "Mover a la izquierda",
	"move_right": "Mover a la derecha",
	"jump": "Saltar",
	"interact": "Interactuar",
	"attacking": "Atacar",
	"pause": "Pausa",
}


var master_volume := 0.8
var music_volume := 0.8
var sfx_volume := 0.8
var music_enabled := true
var music_track_index := 0

var fullscreen := false
var resolution_index := 0
var vsync := true

var action_overrides: Dictionary = {}

var _default_bindings: Dictionary = {}


func _ready() -> void:
	_snapshot_default_bindings()
	load_settings()
	_ensure_audio_buses()
	_apply_audio()
	_apply_video()


func _snapshot_default_bindings() -> void:
	for action in REMAPPABLE_ACTIONS:
		_default_bindings[action] = InputMap.action_get_events(action).duplicate()


func load_settings() -> void:
	var config := ConfigFile.new()

	if config.load(SETTINGS_PATH) != OK:
		return

	master_volume = config.get_value("audio", "master_volume", master_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	music_enabled = config.get_value("audio", "music_enabled", music_enabled)
	music_track_index = config.get_value("audio", "music_track_index", music_track_index)
	fullscreen = config.get_value("video", "fullscreen", fullscreen)
	resolution_index = config.get_value("video", "resolution_index", resolution_index)
	vsync = config.get_value("video", "vsync", vsync)
	action_overrides = config.get_value("controls", "overrides", {})

	_apply_overrides()


func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "music_track_index", music_track_index)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "resolution_index", resolution_index)
	config.set_value("video", "vsync", vsync)
	config.set_value("controls", "overrides", action_overrides)

	config.save(SETTINGS_PATH)


func _apply_overrides() -> void:
	for action in action_overrides:
		var keycode: int = action_overrides[action]

		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, _make_key_event(keycode))


func _make_key_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	save_settings()
	audio_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	save_settings()
	audio_changed.emit()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	save_settings()
	audio_changed.emit()


func set_music_enabled(value: bool) -> void:
	music_enabled = value
	save_settings()
	audio_changed.emit()


func set_music_track(index: int) -> void:
	music_track_index = maxi(index, 0)
	save_settings()
	audio_changed.emit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_video()
	save_settings()
	video_changed.emit()


func set_resolution_index(index: int) -> void:
	resolution_index = clampi(index, 0, DEFAULT_RESOLUTIONS.size() - 1)
	_apply_video()
	save_settings()
	video_changed.emit()


func set_vsync(value: bool) -> void:
	vsync = value
	_apply_video()
	save_settings()
	video_changed.emit()


func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue

		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


func _apply_audio() -> void:
	AudioServer.set_bus_volume_db(0, _volume_to_db(master_volume))

	for bus_name in ["Music", "SFX"]:
		var index := AudioServer.get_bus_index(bus_name)

		if index == -1:
			continue

		var volume := music_volume if bus_name == "Music" else sfx_volume
		AudioServer.set_bus_volume_db(index, _volume_to_db(volume))


func _volume_to_db(volume: float) -> float:
	return linear_to_db(volume) if volume > 0.0 else -80.0


func _apply_video() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(DEFAULT_RESOLUTIONS[resolution_index])

	var vsync_mode := (
		DisplayServer.VSYNC_ENABLED
		if vsync
		else DisplayServer.VSYNC_DISABLED
	)
	DisplayServer.window_set_vsync_mode(vsync_mode)


func rebind_action(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		return

	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, _make_key_event(keycode))
	action_overrides[action] = keycode
	save_settings()
	controls_changed.emit()


func reset_action(action: String) -> void:
	if not InputMap.has_action(action):
		return

	InputMap.action_erase_events(action)

	for event in _default_bindings.get(action, []):
		InputMap.action_add_event(action, event)

	action_overrides.erase(action)
	save_settings()
	controls_changed.emit()


func reset_all_controls() -> void:
	for action in REMAPPABLE_ACTIONS:
		reset_action(action)


func get_action_display(action: String) -> String:
	var events := InputMap.action_get_events(action)

	if events.is_empty():
		return ""

	return _event_display(events[0])


func _event_display(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "Clic izquierdo"
			MOUSE_BUTTON_RIGHT:
				return "Clic derecho"
			MOUSE_BUTTON_MIDDLE:
				return "Clic medio"

	if event is InputEventKey:
		if event.physical_keycode != 0:
			return OS.get_keycode_string(event.physical_keycode)

		if event.keycode != 0:
			return OS.get_keycode_string(event.keycode)

	return ""
