extends RefCounted

signal started(kind: String, side: String, in_air: bool, low: bool)

var tuning: Dictionary
var elapsed: float = -1.0
var kind: String = "punch"
var side: String = "near"
var in_air: bool = false
var low: bool = false
var kick_step: int = 0
var serial: int = 0
var chain_length: int = 0
var weapon: String = "fists"
var counts := {
	"near": 0,
	"far": 0,
	"kick": 0,
	"air_punch": 0,
	"air_kick": 0,
	"crouch_punch": 0,
	"crouch_kick": 0
}
var history: Array[String] = []
var _next_side: String = "near"
var _next_kick: int = 0
var _next_kick_side: String = "near"
var _pending: String = ""
var _buffer_left: float = 0.0
var _idle: float = 0.0


func _init() -> void:
	tuning = JSON.parse_string(FileAccess.get_file_as_string("res://data/attacks.json"))


func request(action: String, airborne: bool, crouching: bool = false) -> void:
	if elapsed < 0:
		_begin(action, airborne, crouching)
	else:
		# One deliberate follow-up, never an unbounded queue of mash inputs.
		_pending = action
		_buffer_left = float(tuning.buffer)


func advance(delta: float, airborne: bool, crouching: bool = false) -> void:
	if elapsed < 0:
		_idle += delta
		if _idle > float(tuning.reset_after):
			_next_side = "near"
			_next_kick = 0
			_next_kick_side = "near"
			chain_length = 0
		return
	elapsed += delta
	_buffer_left = maxf(0, _buffer_left - delta)
	if _buffer_left <= 0:
		_pending = ""
	var timing := timings()
	if elapsed >= float(timing.chain) and not _pending.is_empty():
		var next := _pending
		_begin(next, airborne, crouching)
	elif elapsed >= float(timing.duration):
		elapsed = -1
		_idle = 0


func timings() -> Dictionary:
	if weapon == "bat" and kind == "punch":
		return tuning["air_bat" if in_air else ("crouch_bat" if low else "bat")]
	if in_air:
		return tuning["air_" + kind]
	if low:
		return tuning["crouch_" + kind]
	if kind == "kick" and kick_step > 0:
		return tuning["kick" + str(kick_step + 1)]
	return tuning.cross if kind == "punch" and side == "far" else tuning[kind]


func envelope() -> Vector2:
	if elapsed < 0:
		return Vector2.ZERO
	var timing := timings()
	var wind := smoothstep(0, float(timing.windup), elapsed)
	var extend := smoothstep(float(timing.windup), float(timing.extension), elapsed)
	var recover := smoothstep(float(timing.hold), float(timing.duration), elapsed)
	return Vector2(extend * (1.0 - recover), wind * (1.0 - extend))


func recovery() -> float:
	var timing := timings()
	return smoothstep(float(timing.hold), float(timing.duration), elapsed)


func is_active() -> bool:
	if elapsed < 0:
		return false
	var timing := timings()
	return elapsed >= float(timing.extension) and elapsed <= float(timing.hold)


func interrupt() -> void:
	elapsed = -1
	_pending = ""
	_buffer_left = 0
	_idle = float(tuning.reset_after) + 1
	chain_length = 0


func _begin(action: String, airborne: bool, crouching: bool) -> void:
	kind = action
	in_air = airborne
	low = crouching and not airborne
	side = _next_side if kind == "punch" else "near"
	if kind == "punch":
		_next_side = "far" if side == "near" else "near"
		counts[side] += 1
	else:
		counts.kick += 1
		kick_step = _next_kick
		_next_kick = (_next_kick + 1) % 3
		side = _next_kick_side
		_next_kick_side = "far" if side == "near" else "near"
	if in_air:
		counts["air_" + kind] += 1
	elif low:
		counts["crouch_" + kind] += 1
	elapsed = 0
	_idle = 0
	_pending = ""
	_buffer_left = 0
	serial += 1
	chain_length += 1
	var prefix := "air_" if in_air else ("crouch_" if low else "")
	var step_text := str(kick_step + 1) if kind == "kick" else ""
	history.append(prefix + kind + step_text + ":" + side)
	if history.size() > 12:
		history.pop_front()
	started.emit(kind, side, in_air, low)
