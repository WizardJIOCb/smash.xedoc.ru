extends RefCounted

var active: bool = false
var remaining: float = 0.0
var cycle_distance: float = 0.0
var travelled: float = 0.0
var planned_distance: float = 0.0
var _velocity: float = 0.0
var _deceleration: float = 0.0
var _direction: float = 1.0


func begin(speed: float, phase: float, cycle: float, target_phase: float = PI) -> void:
	_velocity = absf(speed)
	_direction = signf(speed)
	cycle_distance = cycle
	# Finish with the near foot behind, matching the chosen guard stance.
	remaining = fposmod(target_phase - phase, TAU) / TAU * cycle
	planned_distance = remaining
	travelled = 0
	_deceleration = speed * speed / (2.0 * maxf(remaining, 0.001))
	active = _velocity > 0.1


func advance(delta: float) -> float:
	if not active:
		return 0
	var time := minf(delta, _velocity / _deceleration)
	var distance := minf(remaining, _velocity * time - 0.5 * _deceleration * time * time)
	_velocity = maxf(0, _velocity - _deceleration * time)
	if _velocity < 0.01:
		distance = remaining
	remaining -= distance
	travelled += distance
	active = remaining > 0.001
	return distance * _direction
