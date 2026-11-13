class_name ProbeMotion
extends RefCounted


static func step(
	position: Vector2, direction: Vector2, speed: float, delta: float, bounds: Rect2
) -> Vector2:
	var result: Vector2 = position + direction.limit_length() * speed * delta
	return result.clamp(bounds.position, bounds.end)
