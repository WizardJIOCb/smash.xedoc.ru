extends GutTest

const RigMath = preload("res://scripts/core/rig_math.gd")


func test_leg_ik_reaches_ground_targets_on_both_sides() -> void:
	for target: Vector2 in [Vector2(-29, 69), Vector2(29, 69), Vector2(12, 54)]:
		var angles := RigMath.leg_angles(target)
		var solved := Vector2.DOWN.rotated(angles.x) * 38.0
		solved += Vector2.DOWN.rotated(angles.x + angles.y) * 38.0
		assert_lt(solved.distance_to(target), 0.01, "Foot must reach its ground target")


func test_head_spring_is_stable_at_low_frame_rates() -> void:
	var sixty := Vector2.ZERO
	var thirty := Vector2.ZERO
	for frame in range(60):
		sixty = RigMath.spring(sixty, 0.25, 155, 16, 1.0 / 60.0)
	for frame in range(30):
		thirty = RigMath.spring(thirty, 0.25, 155, 16, 1.0 / 30.0)
	assert_almost_eq(sixty.x, thirty.x, 0.001)
	assert_almost_eq(thirty.x, 0.25, 0.002)
	assert_false(is_nan(thirty.x))
