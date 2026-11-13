extends RefCounted
## Shared rig math. Spring state is (position, velocity); angles point down at zero.


static func spring(
	state: Vector2, target: float, stiffness: float, damping: float, delta: float
) -> Vector2:
	var remaining := minf(delta, 0.1)
	while remaining > 0.00001:
		var step := minf(remaining, 1.0 / 120.0)
		state.y += ((target - state.x) * stiffness - state.y * damping) * step
		state.x += state.y * step
		remaining -= step
	return state


static func leg_angles(target: Vector2, length: float = 38.0) -> Vector2:
	var distance := clampf(target.length(), 1.0, length * 2.0 - 0.02)
	var thigh := atan2(-target.x, target.y) - acos(distance / (length * 2.0))
	var shin := PI - acos(clampf(1.0 - distance * distance / (2.0 * length * length), -1, 1))
	return Vector2(thigh, shin)
