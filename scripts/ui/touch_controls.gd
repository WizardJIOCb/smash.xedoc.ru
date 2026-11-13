extends CanvasLayer
## Multitouch controls use the same actions as the keyboard, including quick taps.

const FONT = preload("res://assets/fonts/Manrope-Semibold.tres")
const STICK = Vector2(145, 590)
const RADIUS = 76.0
const BUTTONS = [
	["strike", "РУКА", Vector2(1080, 574), 43.0],
	["kick", "НОГА", Vector2(1180, 622), 43.0],
	["block", "БЛОК", Vector2(1069, 674), 37.0],
	["jump", "ПРЫЖОК", Vector2(1190, 512), 43.0],
	["interact", "ВЗЯТЬ", Vector2(959, 646), 35.0],
	["cycle_weapon", "СМЕНА", Vector2(805, 625), 30.0],
	["reload_weapon", "ПАТРОНЫ", Vector2(880, 625), 30.0],
	["world", "ДЕНЬ/НОЧЬ", Vector2(880, 451), 35.0],
	["ultimate", "УЛЬТА", Vector2(980, 451), 35.0],
	["super_strike", "ИМПУЛЬС", Vector2(1080, 451), 35.0],
	["pause_run", "МЕНЮ", Vector2(1218, 149), 32.0],
	["fullscreen", "ЭКРАН", Vector2(1130, 149), 32.0],
	["restart", "ПОВТОР", Vector2(1140, 598), 56.0],
]

var enabled: bool = false
var context: String = "menu"
var canvas: Node2D
var touches: Dictionary = {}
var strengths: Dictionary = {}
var stick_finger: int = -1
var stick_offset := Vector2.ZERO


func _ready() -> void:
	layer = 12
	enabled = enabled or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		enabled = (
			enabled
			or bool(
				JavaScriptBridge.eval(
					"navigator.maxTouchPoints > 0 && matchMedia('(pointer: coarse)').matches", true
				)
			)
		)
	canvas = Node2D.new()
	canvas.draw.connect(_draw_controls)
	canvas.visible = false
	add_child(canvas)


func set_context(value: String) -> void:
	if context == value:
		return
	context = value
	release_all()
	canvas.visible = enabled and context in ["playing", "lost"]
	canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not enabled:
			enabled = true
			canvas.visible = context in ["playing", "lost"]
		if not canvas.visible:
			return
		if event.pressed and not event.canceled:
			_begin(event.index, event.position)
		else:
			_end(event.index)
	elif event is InputEventScreenDrag and canvas.visible:
		if event.index == stick_finger:
			_move_stick(event.position)
			get_viewport().set_input_as_handled()
		elif touches.has(event.index):
			# Slide away to cancel a held guard, without leaving it stuck on.
			var button: Array = touches[event.index]
			if event.position.distance_to(button[2]) > float(button[3]) * 1.5:
				_end(event.index)


func _begin(finger: int, at: Vector2) -> void:
	if context == "playing" and stick_finger < 0 and Rect2(20, 490, 290, 225).has_point(at):
		stick_finger = finger
		_move_stick(at)
		get_viewport().set_input_as_handled()
		return
	for button: Array in BUTTONS:
		if not _available(str(button[0])) or at.distance_to(button[2]) > float(button[3]):
			continue
		touches[finger] = button
		if button[0] == "fullscreen":
			_fullscreen()
		else:
			_set_action(button[0], 1.0)
		canvas.queue_redraw()
		get_viewport().set_input_as_handled()
		return


func _end(finger: int) -> void:
	if finger == stick_finger:
		stick_finger = -1
		stick_offset = Vector2.ZERO
		for action: String in ["left", "right", "sprint", "crouch"]:
			_set_action(action, 0)
	if touches.has(finger):
		var action: String = touches[finger][0]
		touches.erase(finger)
		var still_held := false
		for button: Array in touches.values():
			still_held = still_held or button[0] == action
		if not still_held and action != "fullscreen":
			_set_action(action, 0)
	canvas.queue_redraw()


func _move_stick(at: Vector2) -> void:
	stick_offset = (at - STICK).limit_length(RADIUS)
	var axis := stick_offset / RADIUS
	_set_action("left", clampf((-axis.x - 0.18) / 0.6, 0, 1))
	_set_action("right", clampf((axis.x - 0.18) / 0.6, 0, 1))
	_set_action("sprint", 1.0 if absf(axis.x) > 0.88 and axis.y < 0.48 else 0.0)
	_set_action("crouch", 1.0 if axis.y > 0.48 else 0.0)
	canvas.queue_redraw()


func _set_action(action: String, strength: float) -> void:
	if is_equal_approx(float(strengths.get(action, 0)), strength):
		return
	strengths[action] = strength
	var event := InputEventAction.new()
	event.action = action
	event.pressed = strength > 0
	event.strength = strength
	Input.parse_input_event(event)


func release_all() -> void:
	touches.clear()
	stick_finger = -1
	stick_offset = Vector2.ZERO
	for action: String in strengths.keys():
		_set_action(action, 0)
	if is_instance_valid(canvas):
		canvas.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()


func _exit_tree() -> void:
	release_all()


func _available(action: String) -> bool:
	return (
		action in ["pause_run", "fullscreen", "restart"]
		if context == "lost"
		else action != "restart"
	)


func _fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			(
				"(() => { const e = document.documentElement;"
				+ " if (document.fullscreenElement) { document.exitFullscreen?.(); return; }"
				+ " e.requestFullscreen?.().then(() => screen.orientation?.lock?.('landscape'))"
				+ " .catch(() => {}); })()"
			),
			true
		)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _draw_controls() -> void:
	if context == "playing":
		canvas.draw_circle(STICK, RADIUS, Color(0.025, 0.07, 0.08, 0.36))
		canvas.draw_arc(STICK, RADIUS, 0, TAU, 48, Color(0.86, 0.78, 0.59, 0.5), 2, true)
		canvas.draw_circle(STICK + stick_offset * 0.68, 30, Color(0.86, 0.78, 0.59, 0.38))
		_caption(STICK + Vector2(0, 107), "ВНИЗ — ПРИСЕД · КРАЙ — БЕГ", 11)
	for button: Array in BUTTONS:
		var action: String = button[0]
		if not _available(action):
			continue
		var at: Vector2 = button[2]
		var radius: float = button[3]
		var active := float(strengths.get(action, 0)) > 0
		var accent := Color("ed8a78") if action in ["ultimate", "super_strike"] else Color("e2c390")
		canvas.draw_circle(at, radius, Color(0.025, 0.07, 0.08, 0.72 if active else 0.45))
		accent.a = 0.95 if active else 0.6
		canvas.draw_arc(at, radius, 0, TAU, 40, accent, 3 if active else 1.5, true)
		var caption := (
			action
			in ["strike", "kick", "jump", "block", "restart", "cycle_weapon", "reload_weapon"]
		)
		_draw_icon(action, at - Vector2(0, 7 if caption else 0), accent)
		if caption:
			_caption(at + Vector2(0, 25), str(button[1]), 10)


func _draw_icon(action: String, at: Vector2, color: Color) -> void:
	if action in ["cycle_weapon", "reload_weapon"]:
		canvas.draw_arc(at, 13, -PI * 0.7, PI * 0.9, 24, color, 2, true)
		_stroke(at, [Vector2(-14, -3), Vector2(-10, -12), Vector2(-4, -10)], color)
		if action == "reload_weapon":
			_stroke(
				at,
				[Vector2(-3, -4), Vector2(4, -4), Vector2(4, 9), Vector2(-3, 9), Vector2(-3, -4)],
				color
			)
	elif action == "strike":
		_stroke(
			at,
			[
				Vector2(-14, 15),
				Vector2(-16, 4),
				Vector2(-16, -6),
				Vector2(-11, -6),
				Vector2(-11, -13),
				Vector2(-4, -13),
				Vector2(-4, -16),
				Vector2(3, -16),
				Vector2(3, -13),
				Vector2(10, -13),
				Vector2(10, -10),
				Vector2(16, -10),
				Vector2(17, 5),
				Vector2(9, 15),
				Vector2(-14, 15)
			],
			color
		)
		_stroke(at, [Vector2(-11, -6), Vector2(-6, -1), Vector2(6, -1), Vector2(7, 5)], color)
		_stroke(at, [Vector2(-4, -12), Vector2(-4, -6)], color)
		_stroke(at, [Vector2(3, -11), Vector2(3, -6)], color)
		_stroke(at, [Vector2(10, -8), Vector2(10, -4)], color)
	elif action == "kick":
		_stroke(
			at,
			[
				Vector2(-14, -16),
				Vector2(-2, -16),
				Vector2(-2, -3),
				Vector2(5, 4),
				Vector2(17, 6),
				Vector2(19, 11),
				Vector2(17, 15),
				Vector2(-15, 15),
				Vector2(-17, 11),
				Vector2(-14, 4),
				Vector2(-14, -16)
			],
			color
		)
		_stroke(at, [Vector2(-13, 10), Vector2(16, 10)], color)
		_stroke(at, [Vector2(-7, -12), Vector2(-7, -3), Vector2(0, 4)], color)
	elif action == "jump":
		_stroke(at, [Vector2(0, 12), Vector2(0, -17)], color)
		_stroke(at, [Vector2(-11, -5), Vector2(0, -17), Vector2(11, -5)], color)
		_stroke(at, [Vector2(-14, 17), Vector2(14, 17)], color)
	elif action == "block":
		_stroke(
			at,
			[
				Vector2(-15, -15),
				Vector2(15, -15),
				Vector2(14, 2),
				Vector2(9, 12),
				Vector2(0, 19),
				Vector2(-9, 12),
				Vector2(-14, 2),
				Vector2(-15, -15)
			],
			color
		)
		_stroke(at, [Vector2(0, -9), Vector2(0, 10)], color)
	elif action == "interact":
		canvas.draw_arc(at, 15, -PI / 2 + 0.55, PI * 1.5 - 0.55, 32, color, 2.6, true)
		_stroke(at, [Vector2(0, -20), Vector2(0, 0)], color)
	elif action == "world":
		var sun := at + Vector2(-9, -3)
		canvas.draw_arc(sun, 6, 0, TAU, 24, color, 2.2, true)
		for index in range(8):
			var ray := Vector2.from_angle(index * TAU / 8)
			canvas.draw_line(sun + ray * 9, sun + ray * 12, color, 2, true)
		var moon := PackedVector2Array()
		for index in range(17):
			moon.append(at + Vector2(8, 3) + Vector2.from_angle(-PI / 2 + index * PI / 16) * 12)
		for index in range(17):
			moon.append(at + Vector2(9, 3) + Vector2.from_angle(PI / 2 - index * PI / 16) * 8)
		canvas.draw_colored_polygon(moon, color)
	elif action == "ultimate":
		for side: float in [-1.0, 1.0]:
			_stroke(
				at,
				[
					Vector2(0, 16),
					Vector2(0, 3),
					Vector2(side * 8, -3),
					Vector2(side * 13, -13),
					Vector2(side * 13, -20)
				],
				color
			)
			_stroke(
				at, [Vector2(side * 9, -5), Vector2(side * 19, -8), Vector2(side * 22, -14)], color
			)
			_stroke(
				at, [Vector2(side * 5, 0), Vector2(side * 16, 2), Vector2(side * 21, -2)], color
			)
	elif action == "super_strike":
		canvas.draw_circle(at, 4, color)
		for index in range(4):
			var angle := index * PI / 2
			canvas.draw_arc(at, 14, angle + 0.2, angle + PI / 2 - 0.2, 12, color, 2.6, true)
			var ray := Vector2.from_angle(angle + PI / 4)
			canvas.draw_line(at + ray * 19, at + ray * 24, color, 2.6, true)
	elif action == "pause_run":
		for offset: float in [-10.0, 0.0, 10.0]:
			_stroke(at, [Vector2(-16, offset), Vector2(16, offset)], color)
	elif action == "fullscreen":
		for x: float in [-1.0, 1.0]:
			for y: float in [-1.0, 1.0]:
				_stroke(
					at,
					[Vector2(x * 7, y * 17), Vector2(x * 17, y * 17), Vector2(x * 17, y * 7)],
					color
				)
	elif action == "restart":
		canvas.draw_arc(at, 15, 0.5, TAU, 36, color, 2.6, true)
		_stroke(at, [Vector2(7, -4), Vector2(15, 0), Vector2(18, -8)], color)


func _stroke(at: Vector2, points: Array[Vector2], color: Color) -> void:
	var vertices := PackedVector2Array()
	for point: Vector2 in points:
		vertices.append(at + point)
	canvas.draw_polyline(vertices, color, 2.6, true)


func _caption(at: Vector2, text: String, size: int) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	canvas.draw_string(
		FONT,
		at - Vector2(width * 0.5, 0),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		Color(0.94, 0.91, 0.8, 0.85)
	)
