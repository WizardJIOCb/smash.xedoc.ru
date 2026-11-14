extends GutTest

const Armory = preload("res://scripts/systems/armory.gd")
const Moose = preload("res://scripts/actors/moose_rig.gd")


class Target:
	extends Node2D
	var dead: bool = false

	func hurtbox() -> Rect2:
		return Rect2(global_position - Vector2(10, 60), Vector2(20, 120))


func make_armory() -> Node2D:
	var moose := Moose.new()
	moose.position = Vector2(200, 500)
	add_child_autofree(moose)
	var armory := Armory.new()
	add_child_autofree(armory)
	armory.configure(moose)
	return armory


func test_seven_round_magazine_and_reload_conserve_rounds() -> void:
	var armory = make_armory()
	armory.grant("pistol")
	for index in range(7):
		assert_false(armory.before_attack("punch"), "Gun suppresses ordinary fist damage")
		armory.advance(0.34, [], true)
	assert_eq(armory.stats().shots, 7)
	assert_eq(armory.stats().loaded, 0)
	assert_true(armory.reload())
	armory.advance(0.5, [], true)
	assert_eq(armory.stats().loaded, 0, "Reload has a real duration")
	armory.advance(0.7, [], true)
	assert_eq(armory.stats().loaded, 7)
	assert_eq(armory.stats().reserve, 21)
	assert_eq(armory.stats().loaded + armory.stats().reserve + armory.stats().shots, 35)


func test_support_palm_stays_on_rifle_foreend_through_automatic_recoil() -> void:
	for facing: float in [-1.0, 1.0]:
		var armory = make_armory()
		armory.grant("rifle")
		armory.hero.facing = facing
		armory.trigger(true)
		var support: Array = armory.hero.firearm_pose.tuning.rifle.support
		var largest_gap := 0.0
		for frame in range(90):
			armory.advance(1.0 / 60, [], true)
			armory.hero._process(1.0 / 60)
			armory._process(0)
			var palm: Vector2 = armory.hero.bones.far_hand.to_global(Vector2(0, 9))
			var foreend: Vector2 = armory.visual.to_global(Vector2(support[0], support[1]))
			largest_gap = maxf(largest_gap, palm.distance_to(foreend))
		assert_lt(largest_gap, 0.05, "The rendered fore-end and palm share every recoil frame")
		assert_gt(armory.shots_fired, 5, "Check an actual burst and its return frames")


func test_cancelled_reload_and_room_reset_never_create_ammunition() -> void:
	var armory = make_armory()
	armory.grant("pistol")
	armory.before_attack("punch")
	armory.advance(0.4, [], true)
	assert_true(armory.reload())
	armory.advance(0.4, [], true)
	armory.cycle()
	armory.cycle()
	armory.advance(3, [], true)
	assert_eq(armory.stats().loaded, 6)
	assert_eq(armory.stats().reserve, 28)
	armory.reset(true)
	assert_eq(armory.stats().loaded, 6)
	armory.reset(false)
	assert_eq(armory.equipped, "fists")
	assert_true(armory.ammunition.is_empty())


func test_held_rifle_stops_on_empty_and_is_paused_during_reload() -> void:
	var armory = make_armory()
	armory.grant("rifle")
	armory.trigger(true)
	for frame in range(240):
		armory.advance(1.0 / 60, [], true)
	assert_eq(armory.stats().shots, 24)
	assert_eq(armory.stats().loaded, 0)
	assert_true(armory.reload())
	for frame in range(60):
		armory.advance(1.0 / 60, [], true)
	assert_eq(armory.stats().shots, 24)
	armory.trigger(false)
	armory.advance(0.8, [], true)
	assert_eq(armory.stats().loaded, 24)
	assert_eq(armory.stats().reserve, 48)
	assert_lte(armory.bullets.size(), int(armory.tuning.bullet_limit))


func test_swept_bullet_hits_nearest_target_once_even_on_long_frame() -> void:
	var armory = make_armory()
	armory.grant("pistol")
	var near := Target.new()
	var far := Target.new()
	add_child_autofree(near)
	add_child_autofree(far)
	armory.before_attack("punch")
	var start: Vector2 = armory.bullets[0].at
	near.position = start + Vector2(120, 0)
	far.position = start + Vector2(240, 0)
	watch_signals(armory)
	armory.advance(0.3, [far, near], true)
	assert_signal_emit_count(armory, "projectile_hit", 1)
	assert_eq(get_signal_parameters(armory, "projectile_hit")[0], near)
	assert_eq(armory.bullets.size(), 0)
	armory.advance(0.3, [far, near], true)
	assert_signal_emit_count(armory, "projectile_hit", 1)


func test_melee_weapon_bonus_applies_only_to_hands_and_pickups_need_proximity() -> void:
	var armory = make_armory()
	armory.spawn_pickups([{"id": "shovel", "x": 900, "y": 500}])
	assert_false(armory.interact())
	armory.hero.position.x = 880
	assert_true(armory.interact())
	assert_eq(armory.equipped, "shovel")
	assert_eq(armory.melee_damage(20, "punch"), 37)
	assert_eq(armory.melee_damage(20, "kick"), 20)
	armory.hero.combat.request("punch", false)
	assert_eq(armory.hero.combat.side, "near")
	assert_eq(armory.pickups.size(), 0)


func test_equipment_change_cancels_swing_and_long_weapon_includes_shaft() -> void:
	var armory = make_armory()
	armory.hero.combat.request("punch", false)
	armory.grant("hockey")
	assert_eq(armory.hero.combat.elapsed, -1.0, "A new weapon cannot inherit active frames")
	armory.hero.combat.request("punch", false)
	armory.hero.combat.elapsed = 0.25
	var hand: Vector2 = armory.hero.bones.near_hand.to_global(Vector2(0, 7))
	var tip: Vector2 = armory.melee_tip(hand, "punch")
	var area: Rect2 = armory.melee_area(Rect2(tip - Vector2.ONE, Vector2.ONE * 2), "punch", tip)
	assert_true(
		area.grow(1).has_point(hand), "A close target can touch the shaft, not just the tip"
	)
	armory.cycle()
	assert_eq(armory.hero.combat.elapsed, -1.0)


func test_drop_and_repickup_keep_exact_rounds_and_cancel_reload() -> void:
	var armory = make_armory()
	assert_false(armory.drop(500), "Fists cannot be thrown away")
	armory.grant("pistol", 17)
	armory.before_attack("punch")
	armory.advance(0.4, [], true)
	assert_true(armory.reload())
	assert_true(armory.drop(500))
	assert_eq(armory.equipped, "fists")
	assert_false("pistol" in armory.inventory)
	assert_false(armory.ammunition.has("pistol"))
	for index in range(60):
		armory.advance(1.0 / 60, [], true)
	assert_eq(armory.pickups.size(), 1)
	assert_almost_eq(armory.pickups[0].at.y, 482.0, 0.01, "Weapon settles on the road")
	armory.hero.position = armory.pickups[0].at
	assert_true(armory.interact())
	assert_eq(armory.stats().loaded, 6)
	assert_eq(armory.stats().reserve, 17, "Dropping during reload does not create rounds")
	assert_eq(armory.pickups.size(), 0)
	armory.advance(0, [], false)
	assert_false(armory.drop(500), "A paused game cannot discard gear")


func test_every_empty_firearm_next_attack_throws_once_and_can_be_recovered() -> void:
	var definitions: Dictionary = make_armory().tuning.weapons
	for id: String in definitions:
		if definitions[id].mode == "ranged":
			_check_empty_firearm_throw(id)


func _check_empty_firearm_throw(id: String) -> void:
	var armory = make_armory()
	armory.grant(id, 11)
	armory.ammunition[id].loaded = 0
	var target := Target.new()
	add_child_autofree(target)
	watch_signals(armory)
	armory.trigger(true)
	armory.advance(0.5, [], true)
	assert_eq(armory.equipped, id, "Holding fire does not discard an empty " + id)
	assert_eq(armory.stats().throws, 0)
	assert_false(armory.before_attack("punch"))
	assert_eq(armory.equipped, "fists")
	assert_eq(armory.stats().throws, 1)
	var item: Dictionary = armory.pickups[0]
	target.position = item.at + Vector2(100, 0)
	armory.advance(0.25, [target], true)
	assert_signal_emit_count(armory, "projectile_hit", 1)
	assert_eq(get_signal_parameters(armory, "projectile_hit")[2], 18)
	for index in range(60):
		armory.advance(1.0 / 60, [target], true)
	assert_signal_emit_count(armory, "projectile_hit", 1)
	armory.hero.position = item.at
	assert_true(armory.interact())
	assert_eq(armory.equipped, id)
	assert_eq(armory.stats().loaded, 0)
	assert_eq(armory.stats().reserve, 11)
	assert_true(armory.reload())


func test_bat_wrists_follow_handle_and_original_hands_return_after_drop_or_death() -> void:
	for facing: float in [-1.0, 1.0]:
		var armory = make_armory()
		var hero: Node2D = armory.hero
		hero.facing = facing
		armory.grant("bat")
		var largest_gap := 0.0
		for stance in [[false, false], [false, true], [true, false]]:
			hero.airborne = stance[0]
			hero.crouch_requested = stance[1]
			hero.combat.request("punch", stance[0], stance[1])
			for frame in range(70):
				armory.advance(1.0 / 60, [], true)
				hero.combat.advance(1.0 / 60, stance[0], stance[1])
				hero._process(1.0 / 60)
				armory._process(0)
				var spec: Dictionary = hero.bat_pose.assembly
				for side: String in ["near", "far"]:
					var wrist: Array = spec[side + "_wrist"]
					var at := (
						Vector2(wrist[0] - spec.pivot[0], wrist[1] - spec.pivot[1])
						* float(spec.scale)
					)
					var painted_wrist: Vector2 = armory.visual.to_global(at)
					largest_gap = maxf(
						largest_gap,
						painted_wrist.distance_to(hero.bones[side + "_hand"].global_position)
					)
		assert_lt(
			largest_gap, 0.05, "Both painted wrists stay on their sleeves during the entire swing"
		)
		assert_false(hero.bones.near_hand.get_node("fist_back").visible)
		assert_false(hero.bones.far_hand.get_node("fist").visible)
		armory.drop(500)
		assert_true(hero.bones.near_hand.get_node("fist_back").visible)
		assert_true(hero.bones.far_hand.get_node("fist").visible)
		armory.grant("bat")
		hero._process(0)
		hero.ragdoll_active = true
		armory.advance(0, [], true)
		assert_false(armory.visual.visible, "No floating hand/weapon assembly over the corpse")
		assert_true(hero.bones.near_hand.get_node("fist_back").visible)
		assert_true(hero.bones.far_hand.get_node("fist").visible)
