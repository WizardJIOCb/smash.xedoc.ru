extends Node2D
## Bounded ballistic particles and fading stains rendered in three instanced batches.

const Batch = preload("res://scripts/world/blood_batch.gd")

var drops: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var stains: Array[Dictionary] = []
var surfaces: Array[Rect2] = []
var paused: bool = false
var emitted: int = 0
var landed: int = 0
var stain_layer: Batch
var drop_layer: Batch
var mist_layer: Batch
var rng := RandomNumberGenerator.new()
var tuning: Dictionary = (
	JSON.parse_string(FileAccess.get_file_as_string("res://data/physical_combat.json")).blood
)
var _stains_dirty: bool = false
var _fade_redraw: float = 0.0
var _air_visible: bool = false


func _ready() -> void:
	mist_layer = Batch.new()
	mist_layer.setup("mist", int(tuning.mist_limit))
	add_child(mist_layer)
	drop_layer = Batch.new()
	drop_layer.setup("drop", int(tuning.drop_limit))
	add_child(drop_layer)
	stain_layer = Batch.new()
	stain_layer.setup("stain", int(tuning.stain_limit))
	stain_layer.z_as_relative = false
	stain_layer.z_index = 0
	add_child(stain_layer)
	set_physics_process(false)


func clear() -> void:
	drops.clear()
	clouds.clear()
	stains.clear()
	for batch: Batch in [stain_layer, drop_layer, mist_layer]:
		batch.multimesh.visible_instance_count = 0
	_stains_dirty = false
	_air_visible = false
	set_physics_process(false)


func spill(at: Vector2, direction: Vector2, lethal: bool, mechanical: bool = false) -> void:
	set_physics_process(true)
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
				"depth": rng.randf_range(float(tuning.depth_back), float(tuning.depth_front)),
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
			var depth_scale := 1.0 if surface.size.x > 600 else float(tuning.ledge_depth_scale)
			var plane := surface.position.y + float(item.depth) * depth_scale
			if before.y <= plane and item.at.y >= plane:
				var fraction := (plane - before.y) / maxf(0.001, item.at.y - before.y)
				var x := lerpf(before.x, item.at.x, fraction)
				if x < surface.position.x or x > surface.end.x:
					continue
				item.age = 10
				landed += 1
				stains.append(_stain(Vector2(x, plane), item))
				_stains_dirty = true
				if not item.splash:
					for index in range(3):
						splashes.append(
							{
								"at": Vector2(x, plane - 1),
								"v": Vector2(rng.randf_range(-55, 55), rng.randf_range(-65, -25)),
								"r": 0.8,
								"age": 0.0,
								"color": item.color,
								"depth": item.depth,
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
	var fading := false
	var previous_count := stains.size()
	for item: Dictionary in stains:
		item.age += delta
		fading = fading or item.age > item.life - float(tuning.stain_fade)
	stains = stains.filter(func(item: Dictionary) -> bool: return item.age < item.life)
	while stains.size() > int(tuning.stain_limit):
		stains.pop_front()
	while drops.size() > int(tuning.drop_limit):
		drops.pop_front()
	var air_visible := not drops.is_empty() or not clouds.is_empty()
	if air_visible or _air_visible:
		_render_air()
	_air_visible = air_visible
	_fade_redraw -= delta
	if (
		is_instance_valid(stain_layer)
		and (_stains_dirty or previous_count != stains.size() or (fading and _fade_redraw <= 0))
	):
		_render_stains()
		_stains_dirty = false
		_fade_redraw = 1.0 / 12.0
	if not air_visible and stains.is_empty():
		set_physics_process(false)


func _stain(at: Vector2, drop: Dictionary) -> Dictionary:
	return {
		"at": at,
		"r": drop.r * rng.randf_range(1.6, 3.6),
		"age": 0.0,
		"life": rng.randf_range(float(tuning.stain_min_life), float(tuning.stain_max_life)),
		"color": drop.color,
		"angle": rng.randf_range(-0.15, 0.15),
		"squash": rng.randf_range(0.38, 0.58),
		"stretch": rng.randf_range(0.85, 1.25) * (-1.0 if rng.randf() < 0.5 else 1.0)
	}


func _render_stains() -> void:
	stain_layer.multimesh.visible_instance_count = stains.size()
	for index in range(stains.size()):
		var item: Dictionary = stains[index]
		var color: Color = item.color
		color.a = (
			0.8 * (1.0 - smoothstep(item.life - float(tuning.stain_fade), item.life, item.age))
		)
		stain_layer.put(
			index, item.at, Vector2(item.stretch, item.squash) * item.r * 2.4, item.angle, color
		)


func _render_air() -> void:
	mist_layer.multimesh.visible_instance_count = clouds.size()
	for index in range(clouds.size()):
		var item: Dictionary = clouds[index]
		var color: Color = item.color
		color.a = 0.3 * pow(1 - item.age / 0.5, 2)
		mist_layer.put(index, item.at, Vector2.ONE * item.r * (1.2 + item.age * 6), 0, color)
	drop_layer.multimesh.visible_instance_count = drops.size()
	for index in range(drops.size()):
		var item: Dictionary = drops[index]
		var color: Color = item.color
		color.a = 0.95
		var velocity: Vector2 = item.v
		var length := maxf(item.r * 2.0, velocity.limit_length(220).length() * 0.015 + item.r)
		drop_layer.put(index, item.at, Vector2(length, item.r * 2.4), velocity.angle(), color)
