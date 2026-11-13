extends GutTest

const Moose = preload("res://scripts/actors/moose_rig.gd")
const EnemyRig = preload("res://scripts/actors/enemy_rig.gd")
const Ragdoll = preload("res://scripts/actors/skeletal_ragdoll.gd")
const Blood = preload("res://scripts/world/blood_fx.gd")
const Enemy = preload("res://scripts/actors/district_enemy.gd")


func test_corpse_hits_deduplicate_without_repeating_kill_or_damage() -> void:
	var enemy := Enemy.new()
	enemy.kind = "whip"
	enemy.tuning = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json")).whip
	)
	add_child_autofree(enemy)
	await get_tree().process_frame
	watch_signals(enemy)
	assert_true(enemy.receive_hit(1, "kick", 500, Vector2(-100, 0)))
	var at: Vector2 = enemy.corpse.bodies.hips.position
	assert_false(
		enemy.receive_corpse_hit(1, at, Vector2.RIGHT, "kick"), "Fatal swing cannot hit twice"
	)
	assert_true(enemy.receive_corpse_hit(2, at, Vector2.RIGHT, "punch"))
	assert_false(enemy.receive_corpse_hit(2, at, Vector2.RIGHT, "punch"))
	assert_true(enemy.receive_corpse_hit(3, at, Vector2.LEFT, "kick"))
	assert_signal_emit_count(enemy, "defeated", 1)
	assert_eq(enemy.hits_received, 1)
	assert_eq(enemy.health, 0)
	assert_eq(enemy.corpse.hits, 2)


func test_enemy_planted_soles_match_moose_in_both_directions() -> void:
	var moose := Moose.new()
	add_child_autofree(moose)
	var enemy := EnemyRig.new()
	add_child_autofree(enemy)
	await get_tree().process_frame
	for direction: float in [-1.0, 1.0]:
		enemy.facing = direction
		enemy.pace = 0
		for frame in range(15):
			await get_tree().process_frame
		var sole: float = moose.bones.near_foot.global_position.y + 16.2
		for side: String in ["near", "far"]:
			var enemy_sole: float = enemy.bones[side + "_foot"].global_position.y + 1
			assert_almost_eq(enemy_sole, sole, 1.0, "Boots share the painted ground plane")
			var hip: Vector2 = enemy.bones[side + "_leg"].global_position
			var knee: Vector2 = enemy.bones[side + "_shin"].global_position
			var ankle: Vector2 = enemy.bones[side + "_foot"].global_position
			assert_gt(
				(knee.x - (hip.x + ankle.x) * 0.5) * direction,
				0.0,
				"Knees bend forward in either facing"
			)


func test_mirrored_ragdoll_keeps_skeleton_attached_and_hits_ground() -> void:
	var rig := Moose.new()
	rig.position = Vector2(400, 380)
	rig.facing = -1
	add_child_autofree(rig)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 8
	floor_body.collision_mask = 16
	floor_body.position = Vector2(400, 570)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1200, 20)
	collider.shape = shape
	floor_body.add_child(collider)
	add_child_autofree(floor_body)
	await get_tree().process_frame
	rig.ragdoll_active = true
	var corpse := Ragdoll.new()
	rig.add_child(corpse)
	corpse.start(rig, rig.position + Vector2(0, -130), Vector2(-180, -80), Vector2(50, 250))
	assert_eq(corpse.bodies.size(), 15)
	assert_eq(corpse.physical_bodies.size(), 9)
	assert_eq(corpse.joints.size(), 8)
	for frame in range(150):
		await get_tree().physics_frame
	assert_gt(corpse.bodies.hips.position.y, 480.0, "Inherited fall reaches the ground")
	assert_lt(corpse.bodies.hips.position.y, 562.0, "Pelvis cannot pass through ground")
	assert_lt(corpse.joint_error(), 5.0, "Limbs stay attached after impact")
	for body: RigidBody2D in corpse.bodies.values():
		assert_true(body.position.is_finite())
	for side: String in ["far", "near"]:
		assert_between(rig.bones[side + "_shin"].rotation, 0.11, 1.11, "Knee cannot fold backwards")
		assert_between(
			rig.bones[side + "_foot"].rotation, -0.31, 0.41, "Ankle keeps a natural bend"
		)


func test_blood_lands_on_upper_surface_and_fades_with_bounded_particles() -> void:
	var blood := Blood.new()
	blood.surfaces = [Rect2(-1000, 120, 2000, 20), Rect2(-1000, 300, 2000, 20)]
	blood.rng.seed = 7
	add_child_autofree(blood)
	blood.set_physics_process(false)
	blood.spill(Vector2(0, 60), Vector2.RIGHT, true)
	for frame in range(100):
		blood._physics_process(0.025)
	assert_gt(blood.landed, 34, "Droplets create secondary splashes")
	assert_gt(blood.stains.size(), 0)
	assert_eq(blood.stain_layer.multimesh.visible_instance_count, blood.stains.size())
	var depth_min := INF
	var depth_max := -INF
	for stain: Dictionary in blood.stains:
		assert_between(stain.at.y, 106.0, 127.0, "First platform contact includes its road depth")
		depth_min = minf(depth_min, stain.at.y)
		depth_max = maxf(depth_max, stain.at.y)
	assert_gt(depth_max - depth_min, 12.0, "Stains scatter through depth instead of forming a line")
	for frame in range(760):
		blood._physics_process(0.025)
	assert_eq(blood.stains.size(), 0, "Rain washes all stains away after their lifetime")
	assert_eq(
		blood.stain_layer.multimesh.visible_instance_count,
		0,
		"Expired stains also leave the GPU batch"
	)
	assert_false(blood.is_physics_processing(), "Empty blood effects stop updating")
	for burst in range(30):
		blood.spill(Vector2.ZERO, Vector2.RIGHT, true)
	assert_lte(blood.drops.size(), 240)
	assert_lte(blood.clouds.size(), 48)
	blood.clear()
	for batch: Node2D in [blood.stain_layer, blood.drop_layer, blood.mist_layer]:
		assert_eq(
			batch.multimesh.visible_instance_count, 0, "Room changes remove all visible instances"
		)
	assert_eq(blood.drops.size(), 0)
	assert_false(blood.is_physics_processing(), "A cleared effect stays idle until the next hit")


func test_enemy_ragdolls_settle_without_stretched_joints_after_head_hit_and_trip() -> void:
	var ground := StaticBody2D.new()
	ground.collision_layer = 8
	ground.collision_mask = 16
	ground.position = Vector2(640, 570)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(2000, 20)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	var corpses: Array[Ragdoll] = []
	var neck_spans: Array[float] = []
	for index in range(2):
		var rig := EnemyRig.new()
		rig.kind = "shield" if index == 0 else "whip"
		rig.facing = -1 if index == 0 else 1
		rig.position = Vector2(300 + index * 600, 550)
		add_child_autofree(rig)
		await get_tree().process_frame
		neck_spans.append(
			rig.bones.head.global_position.distance_to(rig.bones.hips.global_position)
		)
		rig.ragdoll_active = true
		var corpse := Ragdoll.new()
		rig.add_child(corpse)
		corpse.start(
			rig,
			rig.position + Vector2(0, -140 if index == 0 else -27),
			Vector2(-260 if index == 0 else 260, -80),
			Vector2.ZERO
		)
		corpses.append(corpse)
	assert_eq(corpses[0].impact_bone, "head", "High strike transfers momentum into the head")
	assert_true(
		"shin" in corpses[1].impact_bone or "leg" in corpses[1].impact_bone,
		"Low strike trips a leg"
	)
	for frame in range(240):
		await get_tree().physics_frame
	await get_tree().process_frame
	for index in range(corpses.size()):
		var corpse := corpses[index]
		assert_lt(corpse.joint_error(), 3.0, "Mirrored joints stay attached after settling")
		assert_gt(corpse.bodies.hips.position.y, 490.0)
		assert_lt(corpse.bodies.hips.position.y, 562.0)
		assert_lt(
			absf(corpse.bodies.hips.linear_velocity.x),
			5.0,
			"Corpse settles instead of gaining energy"
		)
		var painted: Node2D = corpse.rig
		assert_lt(
			absf(painted.bones.body.rotation), 0.3, "Spine keeps the trunk and pelvis aligned"
		)
		assert_lt(
			absf(painted.bones.head.rotation), 0.45, "Neck cannot fold the muzzle into the chest"
		)
		assert_gt(
			painted.bones.head.global_position.distance_to(painted.bones.hips.global_position),
			neck_spans[index] * 0.95,
			"Head stays outside the pelvis"
		)
		assert_true(corpse.settled, "A resting corpse stops simulating before its visual fade")
		for body: RigidBody2D in corpse.physical_bodies:
			assert_true(body.freeze, "Settled limbs consume no active solver work")
		var count := corpse.physical_bodies.size()
		var at: Vector2 = corpse.bodies.hips.position
		assert_ne(corpse.contact(Rect2(at - Vector2(20, 20), Vector2(40, 40)), at), Vector2.INF)
		assert_true(corpse.react(at, Vector2.RIGHT, "kick"))
		assert_false(corpse.settled, "A hit wakes a resting corpse")
		assert_lt(corpse.bodies.hips.linear_velocity.y, -100.0, "Kick tosses the body up")
		assert_true(corpse.react(at, Vector2.LEFT, "punch"), "An airborne body can be hit again")
		assert_eq(corpse.physical_bodies.size(), count, "Wake reuses the physical skeleton")
	for frame in range(240):
		await get_tree().physics_frame
	for corpse: Ragdoll in corpses:
		assert_true(corpse.settled, "A tossed body returns to idle physics")
		assert_lt(corpse.joint_error(), 3.0, "Reattached joints survive a second landing")
		corpse.age = corpse.lifetime
		assert_false(corpse.react(corpse.bodies.hips.position, Vector2.RIGHT, "kick"))
