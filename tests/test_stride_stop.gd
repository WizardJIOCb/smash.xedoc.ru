extends GutTest

const Stop = preload("res://scripts/core/stride_stop.gd")


func test_stops_at_planned_footfall_in_both_directions_and_frame_rates() -> void:
	for direction: float in [-1.0, 1.0]:
		for fps: float in [30.0, 144.0]:
			var stop := Stop.new()
			var phase := TAU * 0.18
			var target := PI if direction > 0 else 0.0
			stop.begin(235.0 * direction, phase, 109.09, target)
			var distance := 0.0
			for tick in range(int(fps * 2)):
				distance += stop.advance(1.0 / fps)
			assert_false(stop.active)
			assert_almost_eq(absf(distance), stop.planned_distance, 0.001)
			var end := fposmod(phase + absf(distance) / 109.09 * TAU - target, TAU)
			assert_lt(minf(end, TAU - end), 0.001, "The final gait is a planted guard footfall")


func test_short_final_step_cannot_restart_itself_or_drift_past_target() -> void:
	var stop := Stop.new()
	stop.begin(235, PI - 0.01, 109.09)
	var distance := stop.advance(0.1)
	assert_false(stop.active)
	assert_almost_eq(distance, stop.planned_distance, 0.001)
	assert_eq(stop.advance(1), 0.0)
