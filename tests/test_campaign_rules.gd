extends GutTest

const Rules = preload("res://scripts/world/campaign_rules.gd")


class Hero:
	extends Node2D
	var facing: float = -1
	var airborne: bool = false
	var crouch: float = 0
	var crouch_requested: bool = false
	var horizontal_speed: float = 0
	var vertical_speed: float = 0
	var finishing_step: bool = true
	var stop_cycle_distance: float = 80
	var preparation: float = 0.5
	var feet_resets: int = 0

	func land(_impact: float) -> void:
		feet_resets += 1


class Stop:
	extends RefCounted
	var active: bool = true


class Projectiles:
	extends RefCounted
	var projectiles: Array[Dictionary] = []


class Run:
	extends Node
	var moose := Hero.new()
	var enemies: Array[Node2D] = []
	var effects := Projectiles.new()
	var health: int = 100
	var floor_y: float = 555
	var speed: float = 180
	var lift: float = -10
	var vertical_speed: float = 200
	var hurts: int = 0
	var _notice: String = ""
	var _notice_left: float = 0
	var _stride_stop := Stop.new()
	var _direction_was_held: bool = true
	var _jump_buffer: float = 0.1
	var _preparation_time: float = 0.04

	func _hurt_player(amount: int, _source: Vector2, _high: bool) -> void:
		health -= amount
		hurts += 1
		speed = 777
		moose.facing = 1

	func _feedback(_at: Vector2, _caption: String, _color: Color, _sound: String) -> void:
		pass


class Guard:
	extends Node2D
	var health: int = 80
	var dead: bool = false
	var kind: String = "hare"
	var boss: bool = false
	var push: float = 0
	var contacts: int = 0

	func hurtbox() -> Rect2:
		return Rect2(position - Vector2(31, 160), Vector2(62, 167))

	func receive_hit(_serial: int, _kind: String, damage: int, _source: Vector2) -> bool:
		health -= damage
		contacts += 1
		return true


func fixture(kind: String, overrides: Dictionary = {}) -> Array:
	var run := Run.new()
	add_child_autofree(run)
	run.add_child(run.moose)
	run.moose.position = Vector2(170, 555)
	var rule := Rules.new()
	var settings := {"kind": kind}
	settings.merge(overrides, true)
	rule.configure({"floor": 555, "mechanic": settings})
	add_child_autofree(rule)
	rule.set_physics_process(false)
	rule.advance(run, 0, false)
	return [run, rule]


func test_port_carry_is_exact_at_two_rates_and_jump_releases_the_deck() -> void:
	for fps: float in [30, 144]:
		var f := fixture("port")
		var run: Run = f[0]
		var rule: Rules = f[1]
		run.moose.position = Vector2(rule.deck_x, 555)
		for frame in range(int(fps * 7)):
			rule.advance(run, 1 / fps, false)
		assert_almost_eq(
			run.moose.position.x,
			rule.deck_x,
			0.001,
			"Feet track the deck without accumulating drift"
		)
		assert_gt(rule.carried_distance, 500.0)
		var before := run.moose.position
		var deck_before := rule.deck_x
		rule.advance(run, 2, true)
		assert_eq(rule.deck_x, deck_before)
		assert_eq(rule.deck_delta, 0.0)
		assert_eq(run.moose.position, before)
		run.moose.airborne = true
		rule.advance(run, 2, false)
		assert_eq(run.moose.position, before, "Jumping keeps its own horizontal momentum")
		var deck := rule.deck_rect()
		run.moose.airborne = false
		run.moose.position = Vector2(deck_before, 555)
		assert_gt(deck.size.x, 0.0)
		assert_eq(rule.floor_at(run, 410), 410.0, "An existing upper ledge keeps its floor")


func test_fall_uses_damage_callback_once_preserves_facing_and_resets_captured_step() -> void:
	var f := fixture("port")
	var run: Run = f[0]
	var rule: Rules = f[1]
	run.moose.position = Vector2(700, 650)
	rule.after_move(run, Vector2(700, 640), 1.0 / 60)
	assert_eq(run.hurts, 1)
	assert_eq(run.health, 95)
	assert_eq(run.moose.facing, -1.0)
	assert_lt(run.moose.position.x, float(rule.tuning.gap[0]))
	assert_eq(run.moose.position.y, 555.0)
	assert_eq(run.lift, 0.0)
	assert_eq(run.vertical_speed, 0.0)
	assert_eq(run.speed, 0.0)
	assert_false(run._stride_stop.active)
	assert_false(run._direction_was_held)
	assert_eq(run.moose.feet_resets, 1)
	assert_eq(run.moose.preparation, 0.0)
	rule.after_move(run, run.moose.position, 1.0 / 60)
	assert_eq(run.hurts, 1, "Returning to the safe bank is one event")
	rule.advance(run, 1, false)
	run.health = 2
	run.moose.position = Vector2(700, 650)
	rule.after_move(run, Vector2(700, 640), 1.0 / 60)
	assert_eq(run.health, 1, "Water recovery can never instantly end a run")


func test_metro_warns_first_then_hits_each_exposed_actor_once_and_shelters_both_sides() -> void:
	for protection: String in ["none", "crouch", "niche"]:
		var f := fixture(
			"metro",
			{
				"first_warning": 0.1,
				"warning_seconds": 0.3,
				"wave_seconds": 1.0,
				"interval_seconds": 100
			}
		)
		var run: Run = f[0]
		var rule: Rules = f[1]
		if protection == "crouch":
			run.moose.crouch_requested = true
		elif protection == "niche":
			run.moose.position.x = 350
		var guards: Array[Guard] = []
		for x: float in [730, 350]:
			var guard := Guard.new()
			guard.position = Vector2(x, 555)
			run.add_child(guard)
			run.enemies.append(guard)
			guards.append(guard)
		rule.advance(run, 0.1, false)
		assert_eq(rule.wave_state, "warning")
		assert_eq(run.health, 100)
		assert_true(run._notice.contains("ниша"))
		for frame in range(100):
			rule.advance(run, 1.0 / 60, false)
			rule.after_move(run, run.moose.position, 1.0 / 60)
		assert_eq(run.hurts, 1 if protection == "none" else 0)
		assert_eq(guards[0].contacts, 1)
		assert_eq(guards[0].health, 62)
		assert_eq(guards[1].contacts, 0, "A niche shelters enemies too")
		assert_gt(guards[0].push, 0.0)


func test_vines_accept_one_damage_per_strike_and_required_paths_never_regrow() -> void:
	var f := fixture("vines", {"optional_regrow_seconds": 0.2})
	var run: Run = f[0]
	var rule: Rules = f[1]
	var first: Dictionary = rule.objects[0]
	var second: Dictionary = rule.objects[1]
	run.moose.position.x = 600
	rule.after_move(run, Vector2(300, 555), 1.0 / 60)
	assert_eq(run.moose.position.x, 492.0, "A swept movement cannot tunnel through a live passage")
	var guard := Guard.new()
	guard.position = Vector2(520, 555)
	run.add_child(guard)
	run.enemies.append(guard)
	rule._ground_enemies(run)
	assert_almost_eq(
		guard.hurtbox().end.x, float(first.rect.position.x), 0.01, "Live vines stop guards too"
	)
	guard.position.x = 170
	assert_true(rule.attack(run, 1, first.rect, 19))
	rule.attack(run, 1, first.rect, 19)
	assert_eq(first.health, 19, "An active melee hitbox can be sampled repeatedly")
	rule.attack(run, 2, first.rect, 19)
	assert_eq(first.health, 0)
	rule.attack(run, 3, second.rect, 38)
	run.moose.position.x = 170
	rule.advance(run, 2, false)
	assert_eq(first.health, 0, "Required clearance is permanent for this room instance")
	assert_eq(second.health, 38, "Only the optional barrier may regrow")
	run.moose.position.x = 600
	rule.after_move(run, Vector2(300, 555), 1.0 / 60)
	assert_eq(run.moose.position.x, 600.0)
	guard.position.x = 520
	rule._ground_enemies(run)
	assert_eq(guard.position.x, 520.0, "A cleared passage stays open for guards")


func test_roof_cover_absorbs_projectiles_and_only_the_last_support_drops_the_bridge() -> void:
	var f := fixture(
		"roofs",
		{
			"gap_enabled": true,
			"supports":
			[{"x": 540, "width": 28, "height": 156}, {"x": 600, "width": 28, "height": 156}]
		}
	)
	var run: Run = f[0]
	var rule: Rules = f[1]
	run.effects.projectiles.append(
		{"at": Vector2(450, 450), "velocity": Vector2(-285, 0), "damage": 9, "age": 0.0}
	)
	rule.advance(run, 0.2, false)
	assert_eq(run.effects.projectiles.size(), 0)
	assert_eq(rule.objects[0].health, 37)
	assert_eq(rule.cover_blocks, 1)
	run.moose.position = Vector2(780, 555)
	assert_gt(rule.floor_at(run, 555), 555.0)
	rule.attack(run, 1, rule.objects[1].rect, 50)
	rule.advance(run, 1, false)
	assert_false(rule.bridge_down, "Every configured support must break")
	rule.attack(run, 2, rule.objects[2].rect, 50)
	rule.advance(run, 3, true)
	assert_eq(rule.bridge_progress, 0.0)
	assert_false(rule.attack(run, 3, rule.objects[0].rect, 100), "Menu pauses cannot destroy cover")
	assert_eq(rule.objects[0].health, 37)
	rule.advance(run, 0.8, false)
	assert_true(rule.bridge_down)
	assert_eq(rule.floor_at(run, 555), 555.0, "The fallen sign spans the prepared gap")
	assert_eq(run.health, 100)


func test_gaps_can_be_disabled_and_enemies_never_stand_over_empty_water() -> void:
	var f := fixture("port")
	var run: Run = f[0]
	var rule: Rules = f[1]
	var enemy := Guard.new()
	run.add_child(enemy)
	run.enemies.append(enemy)
	enemy.position = Vector2(760, 555)
	rule._ground_enemies(run)
	assert_gt(enemy.position.x, float(rule.tuning.gap[1]))
	assert_eq(enemy.position.y, 555.0)
	rule.tuning.gap_enabled = false
	run.moose.position = Vector2(700, 555)
	assert_eq(rule.floor_at(run, 555), 555.0, "Boss decks retain continuous pavement")


func test_rooms_without_mechanics_are_inert() -> void:
	var f := fixture("")
	var run: Run = f[0]
	var rule: Rules = f[1]
	var before := run.moose.position
	rule.advance(run, 50, false)
	rule.after_move(run, before, 1)
	assert_eq(rule.floor_at(run, 529), 529.0)
	assert_eq(run.moose.position, before)
	assert_eq(run.health, 100)
	assert_false(rule.attack(run, 1, Rect2(0, 0, 1280, 720), 100))
	assert_false(rule.interact(run))
