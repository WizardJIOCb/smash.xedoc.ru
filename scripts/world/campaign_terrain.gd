extends Node2D
## Gap rooms have real banks and a deep corpse floor; water is an effects plane only.

const Ragdoll = preload("res://scripts/actors/skeletal_ragdoll.gd")
const WORLD_LEFT: float = -200
const WORLD_RIGHT: float = 1480
const THICKNESS: float = 24

var physical_surfaces: Array[Rect2] = []
var blood_surfaces: Array[Rect2] = []
var rain_surfaces: Array[Rect2] = []
var deck: AnimatableBody2D
var bridge: StaticBody2D
var bridge_active: bool = false
var carried_distance: float = 0
var unsupported_wakes: int = 0
var sink_y: float = 0

var _run: Node
var _rules: Node2D
var _floor: float
var _gap := Vector2.ZERO
var _solid: Array[Rect2] = []
var _corpses: Array[Ragdoll] = []
var _seen: Dictionary = {}
var _attached: Dictionary = {}
var _old_deck := Rect2()
var _bridge_plane := Rect2()
var _deck_indices := Vector3i(-1, -1, -1)
var _elapsed: float = 0
var _deck_velocity: float = 0


static func applies(rules: Node2D) -> bool:
	return (
		is_instance_valid(rules)
		and rules.kind in ["port", "roofs"]
		and bool(rules.tuning.get("gap_enabled", false))
	)


func configure(run, rules: Node2D, base_floor: float) -> void:
	_run = run
	_rules = rules
	_floor = base_floor
	_gap = Vector2(rules.tuning.gap[0], rules.tuning.gap[1])
	_elapsed = rules.elapsed
	var sole := float(rules.tuning.foot_offset)
	sink_y = base_floor + float(rules.tuning.fall_depth) + float(rules.tuning.body_height)
	_solid.append(Rect2(WORLD_LEFT, base_floor + sole, _gap.x - WORLD_LEFT, THICKNESS))
	_solid.append(Rect2(_gap.y, base_floor + sole, WORLD_RIGHT - _gap.y, THICKNESS))
	for ledge: Rect2 in run.ledges:
		_solid.append(Rect2(ledge.position + Vector2(0, sole), Vector2(ledge.size.x, THICKNESS)))
	for surface: Rect2 in _solid:
		_static_body(surface, surface.position.y < base_floor)
	blood_surfaces.assign(_solid)
	rain_surfaces.assign(_solid)
	var deep := Rect2(_gap.x, sink_y, _gap.y - _gap.x, THICKNESS)
	_static_body(deep, false)
	_solid.append(deep)
	physical_surfaces.assign(_solid)
	if rules.kind == "port":
		# Existing rain depth is negative. Center its ground range inside the water.
		var water_y := base_floor + sole * 5
		var rain_depth: float = (
			(run.rain.tuning.ground_depth_min + run.rain.tuning.ground_depth_max) / 2
		)
		blood_surfaces.append(Rect2(_gap.x, water_y, _gap.y - _gap.x, THICKNESS))
		rain_surfaces.append(Rect2(_gap.x, water_y - rain_depth, _gap.y - _gap.x, THICKNESS))
		_old_deck = rules.deck_rect()
		_old_deck.position.y += sole
		deck = AnimatableBody2D.new()
		deck.name = "CargoDeck"
		deck.collision_layer = Ragdoll.TERRAIN_LAYER
		deck.collision_mask = Ragdoll.CORPSE_LAYER
		deck.sync_to_physics = true
		deck.position = _old_deck.get_center()
		var shape := _shape(_old_deck.size)
		shape.one_way_collision = true
		deck.add_child(shape)
		add_child(deck)
		physical_surfaces.append(_old_deck)
		blood_surfaces.append(_old_deck)
		rain_surfaces.append(_old_deck)
	else:
		blood_surfaces.append(deep)
		rain_surfaces.append(deep)
		var overlap := float(rules.tuning.bridge_overlap)
		_bridge_plane = Rect2(
			_gap.x - overlap, base_floor + sole, _gap.y - _gap.x + overlap * 2, THICKNESS
		)
		bridge = _static_body(_bridge_plane, true)
		bridge.name = "BillboardBridge"
		bridge.collision_layer = 0
	physical_surfaces.sort_custom(_higher)
	blood_surfaces.sort_custom(_higher)
	rain_surfaces.sort_custom(_higher)
	if is_instance_valid(deck):
		_deck_indices = Vector3i(
			physical_surfaces.find(_old_deck),
			blood_surfaces.find(_old_deck),
			rain_surfaces.find(_old_deck)
		)


func _ready() -> void:
	setup_effects()


func setup_effects() -> void:
	_run.blood.clear()
	_run.blood.surfaces = blood_surfaces
	_run.rain.configure(rain_surfaces)
	# Rain.configure duplicates and seeds drops once. The moving planes are shared thereafter.
	_run.rain.surfaces = rain_surfaces


func advance(paused: bool) -> void:
	_discover_corpses()
	for corpse: Ragdoll in _corpses:
		corpse.paused = paused
		for body: RigidBody2D in corpse.physical_bodies:
			var frozen := paused or corpse.settled
			if body.freeze != frozen:
				body.freeze = frozen
	if paused:
		return
	var current := _old_deck
	var dx := 0.0
	if is_instance_valid(deck):
		current = _rules.deck_rect()
		current.position.y += float(_rules.tuning.foot_offset)
		dx = current.position.x - _old_deck.position.x
		var delta := maxf(1.0 / Engine.physics_ticks_per_second, float(_rules.elapsed) - _elapsed)
		_deck_velocity = dx / delta
		deck.position = current.get_center()
		physical_surfaces[_deck_indices.x] = current
		blood_surfaces[_deck_indices.y] = current
		rain_surfaces[_deck_indices.z] = current
		if not is_zero_approx(dx):
			_carry_stains(dx)
			_retarget_rain()
	if is_instance_valid(bridge) and _rules.bridge_down and not bridge_active:
		bridge_active = true
		bridge.collision_layer = Ragdoll.TERRAIN_LAYER
		_solid.append(_bridge_plane)
		physical_surfaces.append(_bridge_plane)
		blood_surfaces.append(_bridge_plane)
		rain_surfaces.append(_bridge_plane)
		physical_surfaces.sort_custom(_higher)
		blood_surfaces.sort_custom(_higher)
		rain_surfaces.sort_custom(_higher)
		_retarget_rain()
	for corpse: Ragdoll in _corpses:
		if not corpse.settled:
			continue
		var id := corpse.get_instance_id()
		if _static_support(corpse):
			_attached.erase(id)
		elif is_instance_valid(deck) and _supported(corpse, _old_deck):
			_attached[id] = true
			if not is_zero_approx(dx):
				for body: RigidBody2D in corpse.physical_bodies:
					body.position.x += dx
				corpse.pose_dirty = true
				carried_distance += absf(dx)
		else:
			_wake(corpse, Vector2(_deck_velocity if _attached.has(id) else 0.0, 0))
			_attached.erase(id)
	_old_deck = current
	_elapsed = _rules.elapsed


func metrics() -> Dictionary:
	return {
		"corpse_carried": carried_distance,
		"unsupported_wakes": unsupported_wakes,
		"tracked_corpses": _corpses.size(),
		"sink_y": sink_y,
		"bridge_collision": bridge_active
	}


func _static_body(surface: Rect2, one_way: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = Ragdoll.TERRAIN_LAYER
	body.collision_mask = Ragdoll.CORPSE_LAYER
	body.position = surface.get_center()
	var shape := _shape(surface.size)
	shape.one_way_collision = one_way
	body.add_child(shape)
	add_child(body)
	return body


func _shape(size: Vector2) -> CollisionShape2D:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	return collision


func _discover_corpses() -> void:
	for index in range(_corpses.size() - 1, -1, -1):
		var corpse := _corpses[index]
		if not is_instance_valid(corpse):
			_corpses.remove_at(index)
		elif corpse.age >= corpse.lifetime:
			_seen.erase(corpse.get_instance_id())
			_attached.erase(corpse.get_instance_id())
			_corpses.remove_at(index)
	for enemy in _run.enemies:
		if is_instance_valid(enemy):
			_track(enemy.corpse)
	_track(_run.get("player_corpse"))


func _track(corpse: Ragdoll) -> void:
	if not is_instance_valid(corpse) or corpse.age >= corpse.lifetime:
		return
	var id := corpse.get_instance_id()
	if not _seen.has(id):
		_seen[id] = true
		_corpses.append(corpse)


func _static_support(corpse: Ragdoll) -> bool:
	for plane: Rect2 in _solid:
		if _supported(corpse, plane):
			return true
	return false


func _supported(corpse: Ragdoll, plane: Rect2) -> bool:
	var tolerance := float(_rules.tuning.boarding_tolerance)
	for shape: CollisionShape2D in corpse.hit_shapes:
		var bounds: Rect2 = shape.global_transform * shape.shape.get_rect()
		if bounds.end.x <= plane.position.x or bounds.position.x >= plane.end.x:
			continue
		if absf(bounds.end.y - plane.position.y) <= tolerance:
			return true
	return false


func _wake(corpse: Ragdoll, velocity: Vector2) -> void:
	# Settling detaches the joints. Reconnect at the current pose without synthesizing a hit.
	for constraint: Dictionary in corpse.constraints:
		var joint: PinJoint2D = constraint.joint
		var a: RigidBody2D = constraint.a
		var b: RigidBody2D = constraint.b
		joint.position = (a.to_global(joint.get_meta("a")) + b.to_global(joint.get_meta("b"))) * 0.5
		joint.node_a = joint.get_path_to(a)
		joint.node_b = joint.get_path_to(b)
		joint.set_meta("a", a.to_local(joint.position))
		joint.set_meta("b", b.to_local(joint.position))
	corpse.settled = false
	corpse.still_time = 0
	corpse.pose_dirty = true
	for body: RigidBody2D in corpse.physical_bodies:
		body.freeze = false
		body.sleeping = false
		body.collision_layer = Ragdoll.CORPSE_LAYER | corpse.self_layer
		body.collision_mask = Ragdoll.TERRAIN_LAYER | corpse.self_layer
		body.linear_velocity = velocity.limit_length(float(corpse.tuning.hit_speed_cap))
	corpse.set_process(true)
	corpse.set_physics_process(true)
	unsupported_wakes += 1


func _carry_stains(dx: float) -> void:
	var dirty := false
	for stain: Dictionary in _run.blood.stains:
		var at: Vector2 = stain.at
		if at.x <= _gap.x or at.x >= _gap.y:
			continue
		if at.x < _old_deck.position.x or at.x > _old_deck.end.x:
			continue
		if absf(at.y - _old_deck.position.y) <= float(_rules.tuning.boarding_tolerance):
			stain.at.x += dx
			dirty = true
	if dirty:
		_run.blood._stains_dirty = true


func _retarget_rain() -> void:
	var rain: Node2D = _run.rain
	for drop: Dictionary in rain.drops:
		if drop.age >= drop.flight:
			continue
		var origin: Vector2 = drop.origin
		var velocity: Vector2 = drop.velocity
		var fraction := fposmod(origin.x, 1)
		for plane: Rect2 in rain_surfaces:
			var x := origin.x + velocity.x * (plane.position.y - origin.y) / velocity.y
			if x < plane.position.x or x > plane.end.x:
				continue
			var depth := lerpf(
				float(rain.tuning.ledge_depth_min), float(rain.tuning.ledge_depth_max), fraction
			)
			if plane.position.y == rain_surfaces.back().position.y:
				depth = lerpf(
					float(rain.tuning.ground_depth_min),
					float(rain.tuning.ground_depth_max),
					fraction
				)
			var flight := (plane.position.y + depth - origin.y) / velocity.y
			if flight < float(drop.age):
				continue
			drop.flight = flight
			drop.impact = origin + velocity * flight
			break


static func _higher(a: Rect2, b: Rect2) -> bool:
	return a.position.y < b.position.y
