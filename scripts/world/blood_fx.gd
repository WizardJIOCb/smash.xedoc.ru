extends Node2D
## Bounded ballistic droplets, impact mist, surface splashes and fading wet stains.

var drops: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var stains: Array[Dictionary] = []
var surfaces: Array[Rect2] = []
var paused: bool = false
var emitted: int = 0
var landed: int = 0
var rng := RandomNumberGenerator.new()
var tuning: Dictionary = (
	JSON.parse_string(FileAccess.get_file_as_string("res://data/physical_combat.json")).blood
)


func spill(at: Vector2, direction: Vector2, lethal: bool, mechanical: bool = false) -> void:
	var color := Color("8b1e29") if not mechanical else Color("273334")
	var count := int(tuning.lethal_drops if lethal else tuning.hit_drops)
	emitted += count
	var axis := direction.normalized()
	for index in range(count):
		var velocity := axis.rotated(rng.randf_range(-0.8, 0.8)) * rng.randf_range(50, 170)
		velocity.y -= rng.randf_range(65, 190 if lethal else 110)
		drops.append(
			{
				"at": at,
				"v": velocity,
				"age": 0.0,
				"r": rng.randf_range(1.0, 3.0 if lethal else 2.0),
				"color": color,
				"splash": false
			}
		)
	for index in range(7 if lethal else 3):
		clouds.append(
			{
				"at": at + Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10)),
				"v": axis * rng.randf_range(12, 55) + Vector2(0, -20),
				"age": 0.0,
				"r": rng.randf_range(7, 17),
				"color": color
			}
		)
	while drops.size() > int(tuning.drop_limit) - 60:
		drops.pop_front()
	while clouds.size() > int(tuning.mist_limit):
		clouds.pop_front()


func _physics_process(delta: float) -> void:
	if paused:
		return
	var splashes: Array[Dictionary] = []
	for item: Dictionary in drops:
		var before: Vector2 = item.at
		item.age += delta
		item.v.y += float(tuning.gravity) * delta
		item.at += item.v * delta
		for surface: Rect2 in surfaces:
			if before.y <= surface.position.y and item.at.y >= surface.position.y:
				var fraction := (surface.position.y - before.y) / maxf(0.001, item.at.y - before.y)
				var x := lerpf(before.x, item.at.x, fraction)
				if x < surface.position.x or x > surface.end.x:
					continue
				item.age = 10
				landed += 1
				stains.append(
					{
						"at": Vector2(x, surface.position.y + 0.5),
						"r": item.r * rng.randf_range(1.5, 3.2),
						"age": 0.0,
						"life":
						rng.randf_range(float(tuning.stain_min_life), float(tuning.stain_max_life)),
						"color": item.color
					}
				)
				if not item.splash:
					for index in range(3):
						splashes.append(
							{
								"at": Vector2(x, surface.position.y - 1),
								"v": Vector2(rng.randf_range(-55, 55), rng.randf_range(-65, -25)),
								"r": 0.8,
								"age": 0.0,
								"color": item.color,
								"splash": true
							}
						)
				break
	drops = drops.filter(func(item: Dictionary) -> bool: return item.age < 3.0)
	drops.append_array(splashes)
	for item: Dictionary in clouds:
		item.age += delta
		item.at += item.v * delta
	clouds = clouds.filter(func(item: Dictionary) -> bool: return item.age < 0.5)
	for item: Dictionary in stains:
		item.age += delta
	stains = stains.filter(func(item: Dictionary) -> bool: return item.age < item.life)
	while stains.size() > int(tuning.stain_limit):
		stains.pop_front()
	while drops.size() > int(tuning.drop_limit):
		drops.pop_front()
	queue_redraw()


func _draw() -> void:
	for item: Dictionary in stains:
		var color: Color = item.color
		color.a = (
			0.8 * (1.0 - smoothstep(item.life - float(tuning.stain_fade), item.life, item.age))
		)
		draw_set_transform(item.at, 0, Vector2(1, 0.2))
		draw_circle(Vector2.ZERO, item.r, color)
		draw_circle(
			Vector2(-item.r * 0.5, -0.5), item.r * 0.3, Color(0.65, 0.12, 0.13, color.a * 0.3)
		)
	draw_set_transform(Vector2.ZERO)
	for item: Dictionary in clouds:
		var color: Color = item.color
		color.a = 0.09 * pow(1 - item.age / 0.5, 2)
		for ring in range(4):
			draw_circle(item.at, item.r * (0.6 + item.age * 3) * (1.0 - ring * 0.17), color)
	for item: Dictionary in drops:
		var color: Color = item.color
		color.a = 0.95
		draw_line(item.at, item.at - item.v.limit_length(220) * 0.015, color, item.r, true)
		draw_circle(item.at, item.r * 0.7, color)
