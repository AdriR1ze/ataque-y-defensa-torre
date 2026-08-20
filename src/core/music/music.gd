extends Node

enum State {
	MENU,
	PLANNING,
	COMBAT,
	BOSS,
}

const SAMPLE_RATE := 22050
const BASE_AMPLITUDE := 0.55

const TRACK_NAMES := [
	"Automático (Adaptativo)",
	"El Asedio del Tirano",
	"Estrategia Desesperada",
	"Marcha de los Monstruos",
	"Vigilia de la Ciudadela",
	"La Última Muralla",
]

const TRACK_CONFIGS := [
	# 0: El Asedio del Tirano (Batalla Principal - Tensión Alta)
	{
		"chords": [
			[36, 48, 51, 55], # Cm
			[32, 44, 48, 52], # Ab
			[34, 46, 49, 53], # Bbm
			[31, 43, 47, 50], # G7
		],
		"bpm": 136.0,
		"lead_pattern": [0, 1, 2, 1, 3, 2, 1, 0, 0, 2, 3, 2, 1, 2, 1, 0],
		"lead_timbre": 2, # Dark Brass
		"bass_timbre": 0, # Sub Bass
		"drum_amount": 1.0,
		"drum_style": 0, # Militaristic Siege
		"tempo_multiplier": 1.0,
	},
	# 1: Estrategia Desesperada (Planificación / Cuenta Regresiva)
	{
		"chords": [
			[38, 50, 53, 57], # Dm
			[34, 46, 50, 53], # Bb
			[33, 45, 48, 52], # Am
			[31, 43, 47, 50], # A7
		],
		"bpm": 98.0,
		"lead_pattern": [0, -1, 1, -1, 2, -1, 1, -1, 0, -1, 3, -1, 2, -1, 1, -1],
		"lead_timbre": 3, # Gothic Choir / Synth Pad
		"bass_timbre": 0, # Heartbeat Sub
		"drum_amount": 0.5,
		"drum_style": 1, # Clock Ticking Suspense
		"tempo_multiplier": 1.0,
	},
	# 2: Marcha de los Monstruos (Invasión de Horda / Jefe)
	{
		"chords": [
			[42, 54, 57, 60], # F#m / Tritone tension
			[36, 48, 51, 54], # Cm
			[41, 53, 56, 60], # Fm
			[35, 47, 50, 53], # Bm
		],
		"bpm": 148.0,
		"lead_pattern": [0, 2, 1, 3, 0, 3, 2, 1, 0, 1, 2, 3, 2, 3, 1, 0],
		"lead_timbre": 1, # Sinister Saw Lead
		"bass_timbre": 1, # Heavy Distortion Bass
		"drum_amount": 1.2,
		"drum_style": 2, # Heavy Industrial Rampage
		"tempo_multiplier": 1.0,
	},
	# 3: Vigilia de la Ciudadela (Ambiente Oscuro Tiránico)
	{
		"chords": [
			[45, 57, 60, 64], # Am
			[41, 53, 57, 60], # F
			[38, 50, 53, 57], # Dm
			[40, 52, 56, 59], # E7
		],
		"bpm": 80.0,
		"lead_pattern": [0, -1, -1, 1, -1, -1, 2, -1, -1, 1, -1, -1, 0, -1, -1, -1],
		"lead_timbre": 3, # Choir Pad
		"bass_timbre": 0, # Deep Sub Drone
		"drum_amount": 0.2,
		"drum_style": 1, # Subtle Ambient Pulses
		"tempo_multiplier": 1.0,
	},
	# 4: La Última Muralla (Defensa Clímax)
	{
		"chords": [
			[40, 52, 55, 59], # Em
			[36, 48, 52, 55], # C
			[33, 45, 48, 52], # Am
			[35, 47, 51, 54], # B7
		],
		"bpm": 142.0,
		"lead_pattern": [0, 1, 0, 2, 1, 2, 1, 3, 2, 3, 2, 1, 0, 1, 2, 3],
		"lead_timbre": 2, # Climax Dark Horns
		"bass_timbre": 0, # Driving Bass Pulse
		"drum_amount": 1.1,
		"drum_style": 0, # Climax Battle Drums
		"tempo_multiplier": 1.0,
	},
]


var _player: AudioStreamPlayer
var _streams: Array[AudioStreamWAV] = []
var _current_state := State.MENU
var _target_track_index := -1


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	add_child(_player)

	_generate_tracks()

	Settings.audio_changed.connect(_on_audio_changed)
	_refresh()


func get_track_count() -> int:
	return TRACK_NAMES.size()


func get_track_names() -> Array:
	return TRACK_NAMES.duplicate()


func set_game_state(state: State) -> void:
	_current_state = state
	_refresh()


func _on_audio_changed() -> void:
	_refresh()


func _refresh() -> void:
	if _streams.is_empty():
		return

	var user_setting := Settings.music_track_index
	var desired_index := 0

	if user_setting == 0:
		# Modo Adaptativo
		match _current_state:
			State.MENU:
				desired_index = 3 # Vigilia de la Ciudadela
			State.PLANNING:
				desired_index = 1 # Estrategia Desesperada
			State.COMBAT:
				desired_index = 0 # El Asedio del Tirano
			State.BOSS:
				desired_index = 2 # Marcha de los Monstruos
			_:
				desired_index = 0
	else:
		# Selección manual de canción (1-indexed en UI -> 0-indexed en configs)
		desired_index = clampi(user_setting - 1, 0, _streams.size() - 1)

	if _player.stream != _streams[desired_index]:
		_player.stream = _streams[desired_index]
		_player.play()

	_player.stream_paused = not Settings.music_enabled


func _generate_tracks() -> void:
	_streams.clear()
	for config in TRACK_CONFIGS:
		_streams.append(_build_loop(config))


func _build_loop(track: Dictionary) -> AudioStreamWAV:
	var chords: Array = track["chords"]
	var bpm: float = track["bpm"]
	var lead_pattern: Array = track["lead_pattern"]
	var lead_timbre: int = track["lead_timbre"]
	var bass_timbre: int = track["bass_timbre"]
	var drum_amount: float = track["drum_amount"]
	var drum_style: int = track.get("drum_style", 0)

	var step_time := 60.0 / bpm / 4.0
	var steps := chords.size() * 16
	var sample_count := int(step_time * steps * SAMPLE_RATE)
	var buffer := PackedFloat32Array()
	buffer.resize(sample_count)

	for bar in range(chords.size()):
		var chord: Array = chords[bar]
		var root: int = chord[0]
		var bar_start_step := bar * 16

		for step in range(16):
			var step_index := bar_start_step + step
			var start := int(step_index * step_time * SAMPLE_RATE)

			# Bajo ostinato / Sub pulse
			if step % 2 == 0:
				var bass_midi := root
				if step % 4 == 2:
					bass_midi += 7 # Quinta justa para tensión
				var bass := _make_note(
					_midi_to_hz(bass_midi),
					step_time * 1.8,
					0.35,
					bass_timbre
				)
				_mix(buffer, start, bass)

			# Melodía / Lead ostinato
			var lead_index: int = lead_pattern[step % lead_pattern.size()]
			if lead_index != -1:
				var chord_index := clampi(lead_index % chord.size(), 0, chord.size() - 1)
				var lead_midi: int = chord[chord_index] + 12
				var lead := _make_note(
					_midi_to_hz(lead_midi),
					step_time * 1.2,
					0.25,
					lead_timbre
				)
				_mix(buffer, start, lead)

			# Percusión de tensión
			match drum_style:
				0: # Militaristic Siege
					if step % 4 == 0:
						_mix(buffer, start, _make_kick(step_time))
					if step % 4 == 2 or step % 8 == 7:
						_mix(buffer, start, _make_snare(step_time, drum_amount))
					if step % 2 == 1:
						_mix(buffer, start, _make_hat(step_time, drum_amount))
				1: # Ticking Clock / Suspense
					_mix(buffer, start, _make_tick(step_time, 0.3 * drum_amount if step % 4 == 0 else 0.15 * drum_amount))
					if step % 8 == 0:
						_mix(buffer, start, _make_sub_thump(step_time))
				2: # Industrial Rampage
					if step % 2 == 0:
						_mix(buffer, start, _make_kick(step_time * 1.2))
					if step % 2 == 1:
						_mix(buffer, start, _make_snare(step_time, drum_amount * 1.2))
						_mix(buffer, start, _make_hat(step_time, drum_amount))

	_normalize(buffer)

	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)

	for i in range(sample_count):
		var sample := clampi(int(buffer[i] * 32767.0), -32768, 32767)
		pcm.encode_s16(i * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = sample_count
	stream.data = pcm

	return stream


func _normalize(buffer: PackedFloat32Array) -> void:
	var peak := 0.0
	for i in range(buffer.size()):
		var val := absf(buffer[i])
		if val > peak:
			peak = val

	if peak <= 0.0:
		return

	var gain := BASE_AMPLITUDE / peak
	for i in range(buffer.size()):
		buffer[i] *= gain


func _make_note(freq: float, duration: float, amplitude: float, timbre: int) -> PackedFloat32Array:
	var length := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(length)

	var attack := maxi(int(0.012 * SAMPLE_RATE), 1)
	var omega := TAU * freq / SAMPLE_RATE

	for i in range(length):
		var t := float(i) / length
		var env := minf(1.0, float(i) / attack) * pow(1.0 - t, 1.8)
		var phase := omega * i
		var value := 0.0

		match timbre:
			0: # Sub Bass / Heartbeat Sine
				value = sin(phase) + 0.3 * sin(phase * 0.5)
			1: # Sinister Saw
				var saw := 0.0
				for k in range(1, 6):
					saw += (1.0 / k) * sin(phase * k)
				value = saw * 0.6
			2: # Dark Tyrant Brass
				value = 0.7 * sin(phase) + 0.4 * sin(phase * 2.0) + 0.25 * sin(phase * 3.0) + 0.1 * sin(phase * 4.0)
			3: # Choir Pad
				value = 0.5 * sin(phase) + 0.35 * sin(phase * 1.498) + 0.25 * sin(phase * 2.0) # Quinta justa sutil

		samples[i] = value * env * amplitude

	return samples


func _make_kick(duration: float) -> PackedFloat32Array:
	var length := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(length)

	var phase := 0.0
	for i in range(length):
		var t := float(i) / length
		var freq := lerpf(110.0, 35.0, pow(t, 0.5))
		phase += TAU * freq / SAMPLE_RATE
		var env := pow(1.0 - t, 2.5)
		samples[i] = sin(phase) * env * 0.7

	return samples


func _make_snare(duration: float, amount: float) -> PackedFloat32Array:
	var length := int(duration * SAMPLE_RATE * 0.75)
	var samples := PackedFloat32Array()
	samples.resize(length)

	var phase := 0.0
	for i in range(length):
		var t := float(i) / length
		phase += TAU * 180.0 / SAMPLE_RATE
		var tone := sin(phase) * pow(1.0 - t, 4.0) * 0.3
		var noise := randf_range(-1.0, 1.0) * pow(1.0 - t, 2.0) * 0.4
		samples[i] = (tone + noise) * amount

	return samples


func _make_hat(duration: float, amount: float) -> PackedFloat32Array:
	var length := int(duration * SAMPLE_RATE * 0.4)
	var samples := PackedFloat32Array()
	samples.resize(length)

	for i in range(length):
		var t := float(i) / length
		var env := pow(1.0 - t, 3.5)
		samples[i] = randf_range(-1.0, 1.0) * env * 0.15 * amount

	return samples


func _make_tick(duration: float, volume: float) -> PackedFloat32Array:
	var length := int(duration * SAMPLE_RATE * 0.15)
	var samples := PackedFloat32Array()
	samples.resize(length)

	var phase := 0.0
	for i in range(length):
		var t := float(i) / length
		phase += TAU * 2400.0 / SAMPLE_RATE
		var env := pow(1.0 - t, 8.0)
		samples[i] = sin(phase) * env * volume

	return samples


func _make_sub_thump(duration: float) -> PackedFloat32Array:
	var length := int(duration * SAMPLE_RATE * 0.8)
	var samples := PackedFloat32Array()
	samples.resize(length)

	var phase := 0.0
	for i in range(length):
		var t := float(i) / length
		var freq := lerpf(65.0, 25.0, t)
		phase += TAU * freq / SAMPLE_RATE
		var env := pow(1.0 - t, 1.5)
		samples[i] = sin(phase) * env * 0.6

	return samples


func _mix(buffer: PackedFloat32Array, start: int, note: PackedFloat32Array) -> void:
	var length := mini(note.size(), buffer.size() - start)
	if length <= 0:
		return

	for i in range(length):
		buffer[start + i] += note[i]


func _midi_to_hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)
