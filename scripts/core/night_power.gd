extends RefCounted
## Timed ultimate. Gameplay owns time; presentation never advances these clocks.

var tuning: Dictionary = JSON.parse_string(
	FileAccess.get_file_as_string("res://data/night_power.json")
)
var charge: float = 100.0
var remaining: float = 0.0
var cooldown: float = 0.0
var burst_time: float = -1.0
var casts: int = 0
var bursts: int = 0
var _released: bool = false


func active() -> bool:
	return remaining > 0


func activate() -> bool:
	if active() or charge < 100:
		return false
	charge = 0
	remaining = float(tuning.duration)
	cooldown = 0
	casts += 1
	return true


func gain(amount: float) -> void:
	if not active():
		charge = clampf(charge + amount, 0, 100)


func try_burst() -> bool:
	if not active() or cooldown > 0 or burst_time >= 0:
		return false
	burst_time = 0
	_released = false
	cooldown = float(tuning.burst_cooldown)
	return true


func advance(delta: float) -> bool:
	var released_now := false
	if not active():
		return false
	var available := minf(delta, remaining)
	remaining = maxf(0, remaining - delta)
	cooldown = maxf(0, cooldown - available)
	if burst_time >= 0:
		burst_time += available
		if not _released and burst_time >= float(tuning.burst_windup):
			_released = true
			bursts += 1
			released_now = true
		if burst_time >= float(tuning.burst_windup) + float(tuning.burst_recovery):
			burst_time = -1
	if not active():
		burst_time = -1
	return released_now


func pose() -> Vector2:
	if burst_time < 0:
		return Vector2.ZERO
	var windup := float(tuning.burst_windup)
	if burst_time < windup:
		return Vector2(smoothstep(0, windup, burst_time), 0)
	return Vector2(0, 1.0 - smoothstep(0, float(tuning.burst_recovery), burst_time - windup))


func cancel() -> void:
	remaining = 0
	burst_time = -1
	cooldown = 0


func reset() -> void:
	cancel()
	charge = 100
	casts = 0
	bursts = 0
