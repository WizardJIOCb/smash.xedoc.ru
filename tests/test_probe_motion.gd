extends "res://addons/gut/test.gd"

const Motion = preload("res://scripts/core/probe_motion.gd")


func test_diagonal_has_same_speed_as_horizontal() -> void:
	var bounds := Rect2(-1000, -1000, 2000, 2000)
	var horizontal := Motion.step(Vector2.ZERO, Vector2.RIGHT, 200, 1, bounds)
	var diagonal := Motion.step(Vector2.ZERO, Vector2.ONE, 200, 1, bounds)
	assert_almost_eq(horizontal.length(), diagonal.length(), 0.001)


func test_movement_remains_in_bounds_after_long_frame() -> void:
	var result := Motion.step(Vector2(50, 50), Vector2.RIGHT, 200, 10, Rect2(0, 0, 100, 100))
	assert_eq(result, Vector2(100, 50))
