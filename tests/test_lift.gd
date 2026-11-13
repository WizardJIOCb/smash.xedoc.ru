extends GutTest

const Lift = preload("res://scripts/world/district_lift.gd")


func test_lift_carries_grounded_feet_exactly_but_releases_jump_and_respects_pause() -> void:
	for fps: float in [30.0, 144.0]:
		var platform := Lift.new()
		add_child_autofree(platform)
		var feet := Vector2(700, 555)
		var jump_carry := 0.0
		assert_false(platform.activate(Vector2(400, 555)))
		assert_true(platform.activate(feet))
		for frame in range(int(fps * 5)):
			platform.advance(1.0 / fps)
			jump_carry += absf(platform.carry_delta(feet, true))
			feet.y += platform.carry_delta(feet)
			if frame == int(fps):
				var paused_y := platform.surface().position.y
				platform.advance(1.0, true)
				assert_eq(platform.surface().position.y, paused_y)
				assert_eq(platform.delta_y, 0.0)
		assert_eq(jump_carry, 0.0, "Jumping never sticks to a lift")
		assert_true(platform.upper)
		assert_almost_eq(feet.y, 340.0, 0.01, "No accumulated ride drift at either rate")
		assert_false(platform.moving)
		assert_true(platform.activate(feet), "The same platform can return downstairs")
