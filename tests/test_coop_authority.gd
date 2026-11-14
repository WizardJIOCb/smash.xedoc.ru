extends GutTest

const Run = preload("res://scripts/world/district_run.gd")


func party() -> Node2D:
	var run := Run.new()
	add_child_autofree(run)
	run.coop.you = "1"
	run.coop.hosting = true
	run.coop.active = true
	run.coop.room = {"host": "1", "players": [{"id": "1", "name": "A"}, {"id": "2", "name": "B"}]}
	run.coop._sync_members()
	run.run_state = "playing"
	return run


func test_two_players_first_impulses_both_damage_the_same_enemy() -> void:
	var run = party()
	var actor = run.coop.actors["2"]
	var enemy = run.enemies[0]
	enemy.health = 10000
	run.moose.position = enemy.position - Vector2(100, 0)
	actor.moose.position = run.moose.position
	run.night.bursts = 1
	run._release_impulse()
	var after_host: int = enemy.health
	actor.night.activate()
	actor.night.try_burst()
	run.coop._context(actor, "combat", 0.5)
	assert_lt(enemy.health, after_host, "Different players' first impulses are different contacts")
	assert_eq(enemy.hits_received, 2)


func test_shared_weapon_drop_integrates_once_per_frame() -> void:
	var run = party()
	var actor = run.coop.actors["2"]
	run.armory.spawn_pickups([{"id": "shovel", "x": 300, "y": 400}])
	actor.armory.pickups = run.armory.pickups
	var item: Dictionary = run.armory.pickups[0]
	item.velocity = Vector2(50, -20)
	item.floor = 555
	var original: Vector2 = item.at
	actor.armory.advance(0.1, [], true, false)
	assert_eq(item.at, original, "A guest weapon controller must not move common pickups")
	run.armory.advance(0.1, [], true)
	assert_almost_eq(item.at.x, original.x + 5, 0.001)


func test_guest_cannot_restart_authoritative_world_and_rejoin_resets_epoch() -> void:
	var run = party()
	run.coop.hosting = false
	run.health = 73
	run.kills = 2
	run._start_new_run()
	assert_eq(run.health, 73)
	assert_eq(run.kills, 2)
	run.coop._guest_epoch = 5
	run.coop._clear()
	assert_eq(run.coop._guest_epoch, -1)


func test_train_wave_hits_each_party_member_once() -> void:
	var run = party()
	var actor = run.coop.actors["2"]
	actor.world = run
	var rules = run.campaign_rules
	rules.configure({"floor": 555, "mechanic": {"kind": "metro"}})
	rules.advance(run, 0, false)
	rules.wave_state = "wave"
	rules.waves = 1
	rules.wave_previous_x = 150
	rules.wave_x = 260
	run.moose.position = Vector2(220, 555)
	actor.moose.position = Vector2(220, 555)
	for tick in range(2):
		rules.after_move(run, run.moose.position, 1.0 / 60)
		rules.after_move(actor, actor.moose.position, 1.0 / 60)
	assert_eq(run.health, 91)
	assert_eq(actor.health, 91, "Host contact must not consume the guest's wave contact")
	assert_eq(rules.player_wave_hits, 2)


func test_water_recovers_players_independently_to_their_own_bank() -> void:
	var run = party()
	var actor = run.coop.actors["2"]
	actor.world = run
	var rules = run.campaign_rules
	rules.configure({"floor": 555, "mechanic": {"kind": "port"}})
	rules.advance(run, 0, false)
	run.moose.position = Vector2(100, 555)
	actor.moose.position = Vector2(1000, 555)
	rules.after_move(run, run.moose.position, 1.0 / 60)
	rules.after_move(actor, actor.moose.position, 1.0 / 60)
	run.moose.position = Vector2(700, 650)
	actor.moose.position = Vector2(700, 650)
	rules.after_move(run, run.moose.position, 1.0 / 60)
	rules.after_move(actor, actor.moose.position, 1.0 / 60)
	assert_eq(run.health, 95)
	assert_eq(actor.health, 95)
	assert_lt(run.moose.position.x, float(rules.tuning.gap[0]))
	assert_gt(actor.moose.position.x, float(rules.tuning.gap[1]))


func test_interleaved_player_strikes_damage_a_shared_barrier_once_each() -> void:
	var run = party()
	var rules = run.campaign_rules
	rules.configure({"floor": 555, "mechanic": {"kind": "vines", "barrier_health": 1000}})
	rules.advance(run, 0, false)
	var area: Rect2 = rules.objects[0].rect
	for serial: int in [101, 202, 101, 202]:
		rules.attack(run, serial, area, 10)
	assert_eq(rules.objects[0].health, 980, "Other players must not reset swing deduplication")


func test_party_revival_restores_artwork_after_corpse_fade() -> void:
	var run = party()
	var actor = run.coop.actors["2"]
	actor.hurt(200, actor.moose.position, run)
	actor.corpse.age = actor.corpse.lifetime - 0.001
	actor.corpse._process(0)
	assert_lt(actor.moose.skeleton.modulate.a, 0.01)
	actor.reset_at(Vector2(200, 555))
	assert_eq(actor.moose.skeleton.modulate, Color.WHITE)
	assert_true(actor.moose.visible)
	run._hurt_player(200, run.moose.position)
	run.player_corpse.age = run.player_corpse.lifetime - 0.001
	run.player_corpse._process(0)
	assert_lt(run.moose.skeleton.modulate.a, 0.01)
	run.coop._revive_host()
	assert_eq(run.moose.skeleton.modulate, Color.WHITE)
	assert_true(run.moose.visible)
