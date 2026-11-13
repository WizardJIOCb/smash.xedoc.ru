extends GutTest

const Scores = preload("res://scripts/core/run_scores.gd")


func test_score_rewards_time_health_and_penalizes_deaths() -> void:
	var baseline := {"seconds": 60.0, "health": 100, "deaths": 0}
	assert_eq(Scores.calculate(baseline), 8400)
	assert_eq(Scores.calculate({"seconds": 60.0, "health": 82, "deaths": 1}), 8020)
	assert_eq(Scores.calculate({"seconds": 9999.0, "health": 0, "deaths": 100}), 0)
