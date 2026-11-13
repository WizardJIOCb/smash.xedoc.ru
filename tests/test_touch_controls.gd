extends GutTest

const Touch = preload("res://scripts/ui/touch_controls.gd")

var _controls: Touch


class ActionProbe:
	extends Node
	var punches: int = 0
	var jumps: int = 0

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("strike"):
			punches += 1
		if event.is_action_pressed("jump"):
			jumps += 1


func test_multitouch_movement_attacks_guard_and_pause_release() -> void:
	for action: String in ["left", "right", "sprint", "crouch", "strike", "block", "jump"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var probe := ActionProbe.new()
	add_child_autofree(probe)
	var controls := Touch.new()
	_controls = controls
	controls.enabled = true
	add_child_autofree(controls)
	controls.set_context("playing")
	_touch(0, Vector2(220, 590), true)
	_touch(1, Vector2(1080, 574), true)
	_touch(2, Vector2(1190, 512), true)
	await get_tree().process_frame
	assert_true(Input.is_action_pressed("right"), "Left thumb moves while right thumb attacks")
	assert_true(Input.is_action_pressed("sprint"), "Outer stick ring runs")
	assert_eq(probe.punches, 1, "Touch reaches the same combat event path as J")
	assert_eq(probe.jumps, 1, "Jump can overlap movement and a punch")
	_touch(1, Vector2(1080, 574), false)
	await get_tree().process_frame
	_touch(1, Vector2(1080, 574), true)
	await get_tree().process_frame
	assert_eq(probe.punches, 2, "Repeated taps can chain the next fist")
	_touch(3, Vector2(1069, 674), true)
	await get_tree().process_frame
	assert_true(Input.is_action_pressed("block"), "Guard remains held")
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(190, 650)
	controls._input(drag)
	await get_tree().process_frame
	assert_true(Input.is_action_pressed("crouch"), "Down-diagonal stick crawls")
	assert_false(Input.is_action_pressed("sprint"), "Crouch cannot accidentally sprint")
	controls.set_context("menu")
	await get_tree().process_frame
	for action: String in ["right", "sprint", "crouch", "strike", "block", "jump"]:
		assert_false(Input.is_action_pressed(action), "Opening a menu releases every held finger")
	assert_false(controls.canvas.visible)
	controls.set_context("playing")
	_touch(3, Vector2(1069, 674), true)
	await get_tree().process_frame
	controls.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().process_frame
	assert_false(Input.is_action_pressed("block"), "Losing focus never leaves guard stuck")


func _touch(index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	_controls._input(event)
