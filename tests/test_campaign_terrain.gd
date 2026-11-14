extends GutTest

const Terrain = preload("res://scripts/world/campaign_terrain.gd")
const Rules = preload("res://scripts/world/campaign_rules.gd")
const Ragdoll = preload("res://scripts/actors/skeletal_ragdoll.gd")
const Blood = preload("res://scripts/world/blood_fx.gd")
const Rain = preload("res://scripts/world/rain_fx.gd")


class Run:
	extends Node2D
	var enemies: Array[Node2D] = []
	var ledges: Array[Rect2] = []
	var player_corpse: Ragdoll
	var blood := Blood.new()
	var rain := Rain.new()


class Painted:
	extends Node2D
	var bones: Dictionary = {}
	var skeleton := Node2D.new()
	var ragdoll_active: bool = true

	func _ready() -> void:
		add_child(skeleton)
		var bone := Bone2D.new()
		bone.name = "body"
		bone.set_autocalculate_length_and_angle(false)
		bone.length = 80
		skeleton.add_child(bone)
		bones.body = bone


func fixture(kind: String) -> Array:
	var run := Run.new()
	add_child_autofree(run)
	run.add_child(run.blood)
	run.add_child(run.rain)
	run.rain.paused = true
	run.rain.rng.seed = 11
	var rules := Rules.new()
	rules.configure({"floor": 555, "mechanic": {"kind": kind, "gap_enabled": true}})
	if kind == "port":
		rules.deck_x = 640
	add_child_autofree(rules)
	var terrain := Terrain.new()
	terrain.configure(run, rules, 555)
	add_child_autofree(terrain)
	return [run, rules, terrain]


func ray_at(x: float, bottom: float = 710) -> Dictionary:
	return get_viewport().world_2d.direct_space_state.intersect_ray(
		PhysicsRayQueryParameters2D.create(Vector2(x, 500), Vector2(x, bottom), 8)
	)


func test_water_has_banks_and_deep_collision_but_only_shallow_effects_planes() -> void:
	var f := fixture("port")
	var run: Run = f[0]
	var terrain: Terrain = f[2]
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(ray_at(200).position.y, 565.0, "The paved bank remains solid")
	assert_true(ray_at(820).is_empty(), "Neither water nor the old baseline is solid")
	assert_eq(ray_at(820, 1100).position.y, terrain.sink_y)
	assert_gt(terrain.sink_y, 900.0, "A sinking corpse settles outside the visible playfield")
	var samples := 0
	var shallowest := INF
	var deepest := -INF
	for index in range(512):
		var drop: Dictionary = run.rain._new_drop()
		if drop.impact.x > 780 and drop.impact.x < 850:
			samples += 1
			shallowest = minf(shallowest, drop.impact.y)
			deepest = maxf(deepest, drop.impact.y)
	assert_gt(samples, 10)
	assert_between(shallowest, 590.0, 620.0)
	assert_between(deepest, 590.0, 620.0)
	assert_gt(
		deepest - shallowest, 10.0, "Rain splashes through water depth rather than on a flat rail"
	)
	assert_ne(run.blood.surfaces, terrain.physical_surfaces)


func test_a_settled_corpse_rides_pauses_then_wakes_and_sinks_when_unsupported() -> void:
	var f := fixture("port")
	var run: Run = f[0]
	var rules: Rules = f[1]
	var terrain: Terrain = f[2]
	var rig := Painted.new()
	rig.position = Vector2(640, 490)
	run.add_child(rig)
	var corpse := Ragdoll.new()
	rig.add_child(corpse)
	corpse.start(rig, rig.position, Vector2.ZERO, Vector2.ZERO)
	run.player_corpse = corpse
	for frame in range(150):
		terrain.advance(false)
		await get_tree().physics_frame
	var body: RigidBody2D = corpse.bodies.body
	assert_true(corpse.settled, "A real rigid body lands and settles on the cargo deck")
	assert_between(body.position.y, 500.0, 565.0)
	var start_x := body.position.x
	for frame in range(40):
		rules.deck_x += 1.5
		rules.elapsed += 1.0 / 60
		terrain.advance(false)
		await get_tree().physics_frame
	assert_almost_eq(body.position.x - start_x, 60.0, 0.01)
	assert_gte(terrain.carried_distance, 59.9)
	var paused_at := body.position
	var paused_age := corpse.age
	for frame in range(15):
		terrain.advance(true)
		await get_tree().physics_frame
	assert_eq(body.position, paused_at)
	assert_eq(corpse.age, paused_age)
	assert_true(body.freeze)
	var lifetime := corpse.lifetime
	# Reproduce a sleeping pose left in empty water after its former support disappears.
	body.position.x = 510
	terrain.advance(false)
	assert_false(corpse.settled)
	assert_false(body.freeze)
	assert_eq(corpse.hits, 0, "Losing support does not fabricate a combat hit")
	assert_eq(corpse.lifetime, lifetime, "Support changes never extend corpse lifetime")
	assert_eq(corpse.physical_bodies.size(), 1)
	for frame in range(100):
		terrain.advance(false)
		await get_tree().physics_frame
	assert_gt(body.position.y, 720.0, "The corpse falls through the real gap")
	assert_lt(body.position.y, terrain.sink_y)
	assert_eq(terrain.unsupported_wakes, 1, "Unsupported sleep is repaired once, not every frame")


func test_roof_bridge_has_real_collision_and_effects_only_after_it_lands() -> void:
	var f := fixture("roofs")
	var rules: Rules = f[1]
	var terrain: Terrain = f[2]
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(ray_at(780).is_empty())
	var initial_planes := terrain.rain_surfaces.size()
	rules.bridge_down = true
	terrain.advance(true)
	await get_tree().physics_frame
	assert_false(terrain.bridge_active, "A menu pause cannot introduce a bridge collision")
	terrain.advance(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(terrain.bridge_active)
	assert_eq(ray_at(780).position.y, 565.0)
	assert_eq(terrain.rain_surfaces.size(), initial_planes + 1)
	var falling := RigidBody2D.new()
	falling.position = Vector2(780, 490)
	falling.collision_layer = 16
	falling.collision_mask = 8
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10
	collider.shape = circle
	falling.add_child(collider)
	add_child_autofree(falling)
	for frame in range(70):
		terrain.advance(false)
		await get_tree().physics_frame
	assert_between(falling.position.y, 552.0, 556.0, "The bridge physically catches a falling body")
	assert_eq(terrain.rain_surfaces.size(), initial_planes + 1, "The bridge is added once")


func test_moving_deck_retargets_pending_rain_without_rebuilding_the_drop_pool() -> void:
	var f := fixture("port")
	var run: Run = f[0]
	var rules: Rules = f[1]
	var terrain: Terrain = f[2]
	run.rain.drops.clear()
	run.rain.drops.append(
		{
			"origin": Vector2(800.5, -40),
			"velocity": Vector2(0, 400),
			"impact": Vector2(800.5, 605),
			"flight": 1.7,
			"age": 1.0,
			"size": 1.0,
			"counted": false
		}
	)
	rules.deck_x = 800
	rules.elapsed = 1
	terrain.advance(false)
	var on_deck: float = run.rain.drops[0].impact.y
	assert_lt(on_deck, 565.0)
	rules.deck_x = 500
	rules.elapsed = 2
	terrain.advance(false)
	assert_between(float(run.rain.drops[0].impact.y), 590.0, 620.0)
	assert_eq(run.rain.drops.size(), 1, "Moving support updates pending impacts in place")


func test_legacy_and_gap_disabled_rooms_do_not_select_campaign_terrain() -> void:
	for spec: Dictionary in [
		{},
		{"kind": "vines"},
		{"kind": "port", "gap_enabled": false},
		{"kind": "roofs", "gap_enabled": false}
	]:
		var rules := Rules.new()
		rules.configure({"floor": 555, "mechanic": spec})
		add_child_autofree(rules)
		assert_false(Terrain.applies(rules))
