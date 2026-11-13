extends Node
## Original synthesized one-shots; no external recordings or license dependencies.

var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var muted: bool = true
var cursor: int = 0


func _ready() -> void:
	var preferences := ConfigFile.new()
	if preferences.load("user://audio.cfg") == OK:
		muted = bool(preferences.get_value("sound", "muted", true))
	if OS.has_feature("web"):
		var saved = JavaScriptBridge.eval(
			(
				"(() => { try { return localStorage.getItem('smash-sound-muted'); }"
				+ " catch (_) { return null; } })()"
			),
			true
		)
		if saved is String and saved in ["true", "false"]:
			muted = saved == "true"
	var settings := {
		"hit": [92, 0.15, 0.7],
		"block": [520, 0.12, 0.45],
		"down": [59, 0.4, 0.45],
		"warn": [240, 0.12, 0.03],
		"hurt": [68, 0.24, 0.6],
		"relay": [620, 0.65, 0.03],
		"swing": [140, 0.1, 0.35]
	}
	for id: String in settings:
		var setting: Array = settings[id]
		sounds[id] = _wave(float(setting[0]), float(setting[1]), float(setting[2]))
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -16
		add_child(player)
		voices.append(player)


func set_muted(value: bool) -> void:
	muted = value
	if muted:
		for player: AudioStreamPlayer in voices:
			player.stop()
	var preferences := ConfigFile.new()
	preferences.set_value("sound", "muted", muted)
	preferences.save("user://audio.cfg")
	# Web user:// flush is asynchronous. Persist this small explicit choice now,
	# including when the player immediately reloads or follows ?cache=clear.
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			(
				"try { localStorage.setItem('smash-sound-muted', %s); } catch (_) {}"
				% JSON.stringify(str(muted).to_lower())
			),
			true
		)


func play(id: String) -> void:
	if muted or not sounds.has(id):
		return
	cursor = (cursor + 1) % voices.size()
	voices[cursor].stream = sounds[id]
	voices[cursor].play()


func _wave(frequency: float, duration: float, noise: float) -> AudioStreamWAV:
	var rate := 22050
	var bytes := PackedByteArray()
	var random := RandomNumberGenerator.new()
	random.seed = int(frequency)
	for index in range(int(rate * duration)):
		var t := index / float(rate)
		var envelope := exp(-t / duration * 7) * minf(1, t * 800)
		var signal_value := sin(TAU * frequency * t * (1 - t * 0.3)) * (1 - noise)
		signal_value += random.randf_range(-1, 1) * noise
		var sample := int(clampf(signal_value * envelope, -1, 1) * 26000)
		bytes.append(sample & 255)
		bytes.append((sample >> 8) & 255)
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = rate
	wave.data = bytes
	return wave
