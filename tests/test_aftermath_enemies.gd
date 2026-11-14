extends GutTest

const Enemy = preload("res://scripts/actors/district_enemy.gd")
const Moose = preload("res://scripts/actors/moose_rig.gd")
const KINDS = [
	"otter",
	"seal",
	"skipper",
	"mole",
	"ferret",
	"dispatcher",
	"raccoon",
	"hedgehog",
	"agronomist",
	"crow",
	"owl",
	"manager"
]


func make_enemy(species: String) -> Enemy:
	var enemy := Enemy.new()
	enemy.kind = species
	# Only this isolated logic fixture uses a donor. Release has no art fallback.
	enemy.art_profile = "whip"
	enemy.tuning = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))[species]
	)
	enemy.position = Vector2(500, 560)
	add_child_autofree(enemy)
	enemy.set_physics_process(false)
	return enemy


func make_player(at := Vector2(600, 560)) -> Moose:
	var player := Moose.new()
	player.position = at
	add_child_autofree(player)
	player.set_process(false)
	return player


func test_slow_frames_emit_each_combo_beat_and_marked_shot_once() -> void:
	for species: String in ["raccoon", "owl", "manager", "ferret"]:
		var enemy := make_enemy(species)
		enemy.target = make_player()
		enemy.facing = 1
		enemy.aim = Vector2(600, 460)
		watch_signals(enemy)
		enemy.elapsed = float(enemy.tuning.active) - 0.001
		enemy.pattern._attack()
		enemy.pattern._attack()
		var count := 2 if species == "ferret" else 1
		assert_eq(enemy._events_fired, count, "A slow frame catches up without duplicating beats")
		assert_signal_emit_count(enemy, "hit_player" if species == "ferret" else "shot", count)
		assert_eq(enemy.aim, Vector2(600, 460), "A warned shot cannot track the player's dodge")


func test_hook_body_push_and_guard_reduce_displacement_without_turning_the_target() -> void:
	for species: String in ["otter", "seal"]:
		for blocking: bool in [false, true]:
			var enemy := make_enemy(species)
			var player := make_player()
			player.blocking = blocking
			player.facing = -1
			enemy.target = player
			enemy.facing = 1
			watch_signals(enemy)
			enemy.pattern._melee_beat()
			var motion := -24.0 if species == "otter" else 30.0
			assert_signal_emitted_with_parameters(
				enemy, "forced_player_motion", [motion * (0.65 if blocking else 1.0)]
			)
			assert_eq(player.facing, -1.0, "A displacement request never changes player facing")
			player.position.x = 1000
			enemy.pattern._melee_beat()
			assert_signal_emit_count(enemy, "forced_player_motion", 1, "A missed hook cannot pull")


func test_front_guard_opens_to_a_kick_back_attack_or_exposed_recovery() -> void:
	for species: String in ["hedgehog", "agronomist"]:
		var enemy := make_enemy(species)
		enemy.facing = 1
		var initial := enemy.health
		enemy.receive_hit(1, "punch", 19, Vector2(600, 560))
		assert_eq(enemy.health, initial, "The visible front guard blocks an ordinary fist")
		enemy.receive_hit(2, "punch", 19, Vector2(400, 560))
		assert_eq(enemy.health, initial - 19, "The back is always vulnerable")
		enemy.state = "approach"
		enemy.guard_down = 0
		enemy.receive_hit(3, "kick", 26, Vector2(600, 560))
		assert_eq(enemy.health, initial - 45)
		assert_gte(enemy.guard_down, 1.8, "A kick creates a usable follow-up window")
		enemy.state = "recovery"
		enemy.guard_down = 0
		enemy.receive_hit(4, "punch", 19, Vector2(600, 560))
		assert_eq(enemy.health, initial - 64, "A stuck tool exposes the boss's front")


func test_dispatcher_line_is_warned_and_a_crouch_clears_its_height() -> void:
	var enemy := make_enemy("dispatcher")
	enemy.target = make_player()
	enemy.facing = 1
	enemy._attack_index = 1
	enemy.pattern._select_move()
	assert_eq(enemy.pattern.value("attack_style"), "line")
	assert_gte(float(enemy.pattern.value("windup")), 1.0)
	watch_signals(enemy)
	enemy.target.crouch = 1
	enemy.pattern._melee_beat()
	assert_signal_emit_count(enemy, "hit_player", 0, "The announced crouch clears the line")
	enemy.target.crouch = 0
	enemy.pattern._melee_beat()
	assert_signal_emit_count(enemy, "hit_player", 1)


func test_charge_cannot_cross_a_grounded_body_when_one_frame_spans_the_whole_dash() -> void:
	var enemy := make_enemy("seal")
	enemy.target = make_player(Vector2(572, 560))
	enemy.facing = 1
	enemy.elapsed = float(enemy.tuning.active)
	enemy.pattern._attack()
	assert_eq(enemy.position.x, 500.0, "The charge stops at the shared body boundary")
	assert_eq(enemy.melee_contacts, 1, "Stopping against the body still lands just one bash")


func test_boss_patterns_change_and_punches_do_not_cancel_their_attack() -> void:
	for species: String in ["skipper", "dispatcher", "agronomist", "manager"]:
		var enemy := make_enemy(species)
		enemy.state = "windup"
		enemy.guard_down = 2
		enemy.receive_hit(20, "punch", 19, Vector2(400, 560))
		assert_eq(enemy.state, "windup", "Small hits cannot stun-lock a boss's windup")
		enemy.health = int(enemy.maximum_health * 0.49)
		enemy._update_phase()
		assert_eq(enemy.phase, 2)
		assert_gt(enemy._phase_pause, 0.0, "Phase changes are announced with an open pause")
		var sequence: Array = enemy.tuning.phase_patterns[enemy.phase - 1]
		assert_true(sequence.has(1.0), "The second phase adds or reorders a real move")
		if species == "manager":
			enemy.health = 100
			enemy._update_phase()
			assert_eq(enemy.phase, 3)
			enemy._attack_index = 0
			enemy.pattern._select_move()
			assert_false(enemy.is_ranged(), "The third phase opens with close melee")
			enemy._attack_index = 1
			enemy.pattern._select_move()
			assert_true(enemy.is_ranged(), "Close melee still alternates with a warned shot")
		enemy.receive_hit(21, "kick", 999, Vector2(400, 560))
		assert_true(enemy.dead)
		assert_eq(
			enemy.corpse.bodies.size(), 15, "All new bosses retain the ordinary native ragdoll"
		)


func test_two_hand_profiles_hold_the_handle_and_palms_cover_the_shaft_in_both_facings() -> void:
	for species: String in KINDS:
		var enemy := make_enemy(species)
		var rig := enemy.rig
		var gap := 0.0
		var elbow := 0.0
		for facing: float in [-1.0, 1.0]:
			rig.facing = facing
			for index in range(61):
				var time := index / 60.0
				rig.wind = sin(time * PI) if time < 0.5 else 0.0
				rig.strike = maxf(0, sin((time - 0.5) * TAU))
				rig._process(1.0 / 60)
				var profile: Dictionary = rig.weapon_pose.tuning.profiles[rig.pose_style]
				if profile.has("support"):
					var custom: Dictionary = rig.weapon_pose.tuning.by_kind.get(species, {})
					var support: Array = custom.get("support", profile.support)
					var handle: Vector2 = rig.bones.weapon.to_global(
						Vector2(support[0], support[1])
					)
					gap = maxf(gap, handle.distance_to(rig.bones.far_hand.global_position))
				for side: String in ["near", "far"]:
					elbow = maxf(elbow, absf(rig.bones[side + "_fore"].rotation))
		assert_lt(gap, 0.08, species + " keeps both hands attached through the swing")
		assert_lt(rad_to_deg(elbow), 155.0, species + " elbows keep a natural bend")
		assert_gt(rig.weapon_sprite.z_index, rig.arm_meshes.near.z_index)
		assert_lt(rig.weapon_sprite.z_index, rig.arm_meshes.near.hand_mesh.z_index)
		assert_eq(rig.bones.head.position, Vector2(0, -57), "Head uses the centered neck socket")
