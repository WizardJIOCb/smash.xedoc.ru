extends Node2D
## Drops stop at the highest paved surface, with shallow depth and pooled splashes.

const Batch = preload("res://scripts/world/blood_batch.gd")

var surfaces: Array[Rect2] = [Rect2(-200, 565, 1680, 24)]
var paused: bool = false
var impacts: int = 0
var drops: Array[Dictionary] = []
var streaks: Batch
var ripples: Batch
var rng := RandomNumberGenerator.new()
var tuning: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rain.json"))


func _ready() -> void:
	streaks = Batch.new()
	streaks.setup("drop", int(tuning.count) * 5)
	add_child(streaks)
	ripples = Batch.new()
	ripples.setup("rain_ring", int(tuning.count))
	add_child(ripples)
	configure(surfaces)


func configure(planes: Array[Rect2]) -> void:
	surfaces = planes.duplicate()
	surfaces.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y < b.position.y)
	drops.clear()
	for index in range(int(tuning.count)):
		var drop := _new_drop()
		drop.age = rng.randf() * (drop.flight + float(tuning.splash_life))
		drops.append(drop)
	if is_instance_valid(streaks):
		streaks.multimesh.visible_instance_count = 0
		ripples.multimesh.visible_instance_count = 0


func _new_drop() -> Dictionary:
	var origin := Vector2(rng.randf_range(-50, 1330), -40)
	var velocity := Vector2(float(tuning.drift), rng.randf_range(tuning.fall_min, tuning.fall_max))
	var ground: float = surfaces.back().position.y
	var target_y := ground + rng.randf_range(tuning.ground_depth_min, tuning.ground_depth_max)
	for surface: Rect2 in surfaces:
		var crossing_x := origin.x + velocity.x * (surface.position.y - origin.y) / velocity.y
		if crossing_x >= surface.position.x and crossing_x <= surface.end.x:
			if surface.position.y < ground - 1:
				target_y = (
					surface.position.y
					+ rng.randf_range(tuning.ledge_depth_min, tuning.ledge_depth_max)
				)
			break
	var flight := (target_y - origin.y) / velocity.y
	return {
		"origin": origin,
		"velocity": velocity,
		"impact": origin + velocity * flight,
		"flight": flight,
		"age": 0.0,
		"size": rng.randf_range(0.7, 1.15),
		"counted": false
	}


func _physics_process(delta: float) -> void:
	if paused or not visible:
		return
	var air_count := 0
	var ring_count := 0
	for index in range(drops.size()):
		var drop: Dictionary = drops[index]
		drop.age += delta
		if drop.age >= drop.flight + float(tuning.splash_life):
			drop = _new_drop()
			drops[index] = drop
		var age: float = drop.age
		if age < drop.flight:
			var velocity: Vector2 = drop.velocity
			var head: Vector2 = drop.origin + velocity * age
			var length: float = tuning.streak * drop.size
			streaks.put(
				air_count,
				head - velocity.normalized() * length * 0.5,
				Vector2(length, drop.size),
				velocity.angle(),
				Color(0.66, 0.86, 0.91, 0.24)
			)
			air_count += 1
			continue
		if not drop.counted:
			drop.counted = true
			impacts += 1
		var time: float = age - drop.flight
		var fade: float = 1.0 - time / float(tuning.splash_life)
		var width: float = lerpf(3, tuning.ripple_width, 1.0 - fade) * drop.size
		ripples.put(
			ring_count,
			drop.impact,
			Vector2(width, width * 0.22),
			0,
			Color(0.72, 0.88, 0.91, fade * 0.27)
		)
		ring_count += 1
		for petal in range(4):
			var velocity := Vector2(
				(petal - 1.5) * 25 * drop.size, -float(tuning.splash_speed) * (0.7 + 0.1 * petal)
			)
			var offset := (
				velocity * time + Vector2(0, float(tuning.splash_gravity) * time * time * 0.5)
			)
			if offset.y >= 0:
				continue
			streaks.put(
				air_count,
				drop.impact + offset,
				Vector2(2.4, 1.2) * drop.size,
				Vector2(velocity.x, velocity.y + tuning.splash_gravity * time).angle(),
				Color(0.78, 0.91, 0.93, fade * 0.48)
			)
			air_count += 1
	streaks.multimesh.visible_instance_count = air_count
	ripples.multimesh.visible_instance_count = ring_count
