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
