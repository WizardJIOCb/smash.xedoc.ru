extends GutTest

const Survival = preload("res://scripts/systems/survival_run.gd")


func test_endless_plans_stay_bounded_and_bosses_rotate() -> void:
	var survival := Survival.new()
	var encounters: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/encounters.json")
	)
	for number in [1, 2, 5, 10, 50, 1000]:
		for party in [1, 2, 16]:
			var wave := survival.plan(number, party)
			assert_true(wave.size() > 0 and wave.size() <= 16)
			for kind in wave:
				assert_true(encounters.has(kind))
	assert_eq(survival.plan(5, 1)[0], "foreman")
	assert_eq(survival.plan(10, 1)[0], "dispatcher")
	assert_true(survival.plan(4, 16).size() > survival.plan(4, 1).size())


func test_survival_scaling_never_changes_campaign_tuning() -> void:
	var survival := Survival.new()
	var base := {"health": 100, "damage": 12, "speed": 40, "moves": [{"damage": 20}]}
	survival.begin(1)
	survival.wave = 1
	var first := survival.enemy_tuning(base)
	survival.wave = 10
	var later := survival.enemy_tuning(base)
	assert_eq(first.health, 100)
	assert_gt(later.health, first.health)
	assert_gt(later.moves[0].damage, first.moves[0].damage)
	survival.begin(16)
	survival.wave = 10
	assert_gt(survival.enemy_tuning(base).health, later.health)
	assert_eq(base.health, 100)
	assert_eq(base.moves[0].damage, 20)


func test_guest_snapshot_preserves_wave_rest_and_reinforcement_count() -> void:
	var survival := Survival.new()
	var state := {
		"enabled": true, "wave": 8, "completed": 7, "rest": 0.5, "players": 4, "pending": 5
	}
	survival.apply_snapshot(state)
	assert_eq(survival.snapshot(), state)
	survival.begin(1)
	assert_eq(survival.wave, 0)
	assert_eq(survival.completed, 0)
	assert_eq(survival.pending_count, 0)
	assert_gt(survival.rest, 0.0)
