extends Node2D
## Passing stock and sound read the authoritative wind clock, including its tail.

const CAR = preload("res://assets/environment/props/metro-car.png")
const RAILS = preload("res://assets/audio/metro-rails.wav")
const WIND = preload("res://assets/audio/metro-wind.wav")
const SoftSpot = preload("res://scripts/world/soft_spot.gd")

var rules: Node2D
var settings: Dictionary
var layout: Dictionary
var age: float = 1000
var direction: float = 1
var nose: float = 0
var passing: bool = false
var _openings: Array[PackedVector2Array] = []
var _foreground: Array[PackedVector2Array] = []
var _background: Texture2D
var _spot: Texture2D
var _rails: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _source_clock: float = -1000
var _source_phase: String = ""


func _ready() -> void:
	settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/metro_train.json"))
	layout = settings.layouts.get(rules.tuning.train_scene, settings.layouts["metro-station"])
	_background = load("res://assets/environment/" + str(layout.background))
	_spot = SoftSpot.texture()
	for spec: Array in layout.openings:
		_openings.append(_points(spec))
	for spec: Array in layout.foreground:
		_foreground.append(_points(spec))
	_rails = _sound(RAILS)
	_wind = _sound(WIND)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _process(delta: float) -> void:
	var phase: String = rules.wave_state
	var source: float = rules.wave_time
	if phase != _source_phase or source != _source_clock:
		age = (
			-source
			if phase == "warning"
			else (
				float(rules.tuning.wave_seconds) - source
				if phase == "wave"
				else (
					float(rules.tuning.wave_seconds + rules.tuning.interval_seconds) - source
					if rules.waves > 0
					else 1000.0
				)
			)
		)
		_source_clock = source
		_source_phase = phase
	elif not rules.presentation_paused:
		# Smooth between authoritative co-op packets; never advance the damage clock.
		age += delta
	direction = (
		(1.0 if (rules.waves + 1) % 2 else -1.0)
		if phase == "warning"
		else float(rules.wave_direction)
	)
	var speed := travel_speed()
	nose = (
		-float(rules.tuning.wave_width) + speed * age
		if direction > 0
		else float(rules.tuning.world_width + rules.tuning.wave_width) - speed * age
	)
	passing = age >= 0 and age < end_age()
	var approach: bool = phase == "warning"
	var gain := (
		lerpf(0.04, 0.42, 1 - source / float(rules.tuning.warning_seconds))
		if approach
		else clampf(1 - maxf(0, age - float(rules.tuning.wave_seconds)) / tail_seconds(), 0, 1)
	)
	var sound = rules.get_parent().get("audio")
	var audible: bool = is_instance_valid(sound) and not sound.muted and (approach or passing)
	_bed(_rails, audible, gain, float(settings.rail_volume_db))
	_bed(_wind, audible, gain * gain, float(settings.wind_volume_db))
	queue_redraw()


func travel_speed() -> float:
	return (
		float(rules.tuning.world_width + rules.tuning.wave_width * 2)
		/ float(rules.tuning.wave_seconds)
	)


func metrics() -> Dictionary:
	return {
		"visible": passing,
		"nose_x": nose,
		"direction": direction,
		"age": age,
		"paused": rules.presentation_paused,
		"audio_playing": _rails.playing,
		"audio_paused": _rails.stream_paused
	}


func tail_seconds() -> float:
	return (
		float(settings.car_width + settings.coupler_gap) * int(settings.car_count) / travel_speed()
	)


func end_age() -> float:
	return float(rules.tuning.wave_seconds) + tail_seconds()


func _draw() -> void:
	if not passing:
		return
	var width := float(settings.car_width)
	var height := float(settings.car_height)
	var top := float(layout.y)
	var head_at := Vector2(nose, top + height * 0.64)
	var beam := Rect2(
		head_at - Vector2(0 if direction > 0 else settings.headlight_reach, 30),
		Vector2(settings.headlight_reach, 60)
	)
	_clipped(_spot, beam, false, Color(1, 0.7, 0.3, 0.3))
	for index in range(int(settings.car_count)):
		var front := nose - direction * index * (width + float(settings.coupler_gap))
		var rect := Rect2(front - (width if direction > 0 else 0.0), top, width, height)
		_clipped(CAR, rect, direction < 0, Color(0.85, 0.92, 0.88))
	# Reuse the actual painted foreground for thin railings, crates and barrels.
	for polygon: PackedVector2Array in _foreground:
		var uv := PackedVector2Array()
		for point: Vector2 in polygon:
			uv.append(point / Vector2(1280, 720))
		draw_polygon(polygon, PackedColorArray([Color.WHITE]), uv, _background)
	var sole: float = rules.tuning.floor + rules.tuning.foot_offset
	for index in range(3):
		var light_x := nose - direction * (width * 0.35 + index * width * 0.34)
		draw_texture_rect(
			_spot, Rect2(light_x - 64, sole - 15, 128, 18), false, Color(1, 0.65, 0.25, 0.08)
		)


func _clipped(texture: Texture2D, rect: Rect2, flip: bool, tint: Color) -> void:
	var corners := PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
	)
	for opening: PackedVector2Array in _openings:
		for polygon: PackedVector2Array in Geometry2D.intersect_polygons(corners, opening):
			var uv := PackedVector2Array()
			for point: Vector2 in polygon:
				var local := (point - rect.position) / rect.size
				uv.append(Vector2(1 - local.x if flip else local.x, local.y))
			draw_polygon(polygon, PackedColorArray([tint]), uv, texture)


func _sound(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var loop: AudioStreamWAV = stream.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(stream.get_length() * stream.mix_rate)
	player.stream = loop
	add_child(player)
	return player


func _bed(player: AudioStreamPlayer, audible: bool, gain: float, volume: float) -> void:
	player.stream_paused = rules.presentation_paused
	if not audible:
		player.stop()
		return
	player.volume_db = volume + linear_to_db(maxf(0.001, gain))
	if not player.playing and not rules.presentation_paused:
		player.play()


func _points(spec: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point: Array in spec:
		points.append(Vector2(point[0], point[1]))
	return points
