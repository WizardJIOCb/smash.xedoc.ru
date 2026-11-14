extends GutTest

const Enemy = preload("res://scripts/actors/district_enemy.gd")
const Moose = preload("res://scripts/actors/moose_rig.gd")


func make_enemy(species: String) -> Enemy:
	var enemy := Enemy.new()
	enemy.kind = species
	enemy.art_profile = "whip"
	enemy.tuning = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))[species]
	)
	add_child_autofree(enemy)
	enemy.set_physics_process(false)
	return enemy


func test_new_species_have_both_articulated_arms_and_scaled_ground_contact() -> void:
	for species: String in ["beaver", "hare", "fox", "lynx", "foreman", "firewall"]:
		var enemy := make_enemy(species)
		await get_tree().process_frame
		for direction: float in [-1.0, 1.0]:
			enemy.rig.facing = direction
			enemy.rig._process(0.016)
			for side: String in ["near", "far"]:
				assert_true(enemy.rig.bones.has(side + "_hand"), species + " has complete hands")
				var foot: Bone2D = enemy.rig.bones[side + "_foot"]
				assert_almost_eq(
					foot.global_position.y + enemy.rig.body_scale,
					10.0,
					0.1,
					species + " shares sole plane"
				)
		assert_false(enemy.rig.bones.has("shield"), "Non-shield enemies never inherit a shield")
		assert_eq(enemy.rig.bones.weapon.get_parent(), enemy.rig.bones.near_hand)


func test_ranged_events_are_once_per_beat_and_aim_is_locked() -> void:
	for species: String in ["fox", "lynx", "firewall"]:
		var enemy := make_enemy(species)
		enemy.aim = Vector2(280, 300)
		watch_signals(enemy)
		enemy.elapsed = 0.0
		enemy._new_attack(0.016)
		enemy._new_attack(0.016)
		assert_signal_emit_count(
			enemy, "shot", 1, "Repeated render frame cannot duplicate first shot"
		)
		enemy.elapsed = float(enemy.tuning.active) - 0.001
		enemy._new_attack(0.016)
		var expected := 1 if species == "fox" else (3 if species == "lynx" else 2)
		assert_eq(
			enemy.shots_fired, expected, "Slow frame still fires exactly the remaining burst beats"
		)
		assert_eq(enemy.aim, Vector2(280, 300), "Burst does not track a dodging player")


func test_hare_double_strike_and_jumpable_boss_pulse() -> void:
	var player := Moose.new()
	player.position = Vector2(70, 0)
	add_child_autofree(player)
	var hare := make_enemy("hare")
	hare.target = player
	hare.facing = 1
	watch_signals(hare)
	hare._new_attack(0.016)
	assert_signal_emit_count(hare, "hit_player", 0, "The rear windup cannot hit")
	hare.elapsed = 0.12
	hare._new_attack(0.016)
	assert_signal_emit_count(hare, "hit_player", 1, "Contact follows the first forward swing")
	hare.elapsed = 0.46
	hare._new_attack(0.016)
	hare._new_attack(0.016)
	assert_signal_emit_count(hare, "hit_player", 2)
	hare.elapsed = float(hare.tuning.active)
	hare._new_attack(0.016)
	assert_eq(hare.rig.wind, 0.0, "Finished combo does not jump back into a windup")
	assert_eq(hare.rig.strike, 0.0)
	var boss := make_enemy("firewall")
	boss.target = player
	watch_signals(boss)
	boss._ground_pulse()
	assert_signal_emit_count(boss, "hit_player", 1)
	player.position.y = -70
	boss._ground_pulse()
	assert_signal_emit_count(boss, "hit_player", 1, "Jump clears the advertised ground danger")


func test_boss_phase_thresholds_and_native_death_preserve_topology() -> void:
	var boss := make_enemy("firewall")
	await get_tree().process_frame
	watch_signals(boss)
	boss.state = "windup"
	boss.receive_hit(20, "punch", 10, Vector2(-100, 0))
	assert_eq(boss.state, "windup", "Tiny hits cannot lock the boss out of every attack")
	boss.receive_hit(21, "kick", 160, Vector2(-100, 0))
	assert_eq(boss.phase, 2)
	boss.receive_hit(22, "kick", 140, Vector2(-100, 0))
	assert_eq(boss.phase, 3)
	boss.receive_hit(23, "kick", 500, Vector2(-100, 0))
	assert_true(boss.dead)
	assert_eq(boss.corpse.bodies.size(), 15, "Scaled boss uses the same anatomical ragdoll bones")
	assert_signal_emit_count(boss, "defeated", 1)
	for body: RigidBody2D in boss.corpse.physical_bodies:
		assert_true(body.position.is_finite())


func test_foreman_both_grips_stay_on_the_handle_through_load_strike_and_return() -> void:
	var boss := Enemy.new()
	boss.kind = "foreman"
	boss.tuning = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json")).foreman
	)
	add_child_autofree(boss)
	boss.set_physics_process(false)
	var largest_gap := 0.0
	var largest_elbow := 0.0
	for facing: float in [-1.0, 1.0]:
		boss.rig.facing = facing
		for index in range(121):
			var time := index / 120.0
			boss.rig.wind = sin(time * PI) if time < 0.5 else 0.0
			boss.rig.strike = sin((time - 0.5) * TAU) if time >= 0.5 else 0.0
			boss.rig._process(1.0 / 60)
			var support: Array = boss.rig.weapon_pose.tuning.foreman.support
			var painted: Vector2 = boss.rig.bones.weapon.to_global(Vector2(support[0], support[1]))
			largest_gap = maxf(
				largest_gap, painted.distance_to(boss.rig.bones.far_hand.global_position)
			)
			for side: String in ["near", "far"]:
				largest_elbow = maxf(largest_elbow, absf(boss.rig.bones[side + "_fore"].rotation))
	assert_lt(largest_gap, 0.05, "The lower hand cannot separate from the moving hammer")
	assert_lt(rad_to_deg(largest_elbow), 145.0, "Neither elbow folds back onto the shoulder")
