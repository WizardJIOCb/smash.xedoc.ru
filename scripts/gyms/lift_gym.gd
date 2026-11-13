extends "res://scripts/gyms/rig_lab.gd"
## Manual gym; SMASH_LIFT_REVIEW=1 demonstrates the same action-input path.

const Lift = preload("res://scripts/world/district_lift.gd")

var carrier: Lift
var review: bool = false
var review_time: float = 0.0
var ride_error: float = 0.0
var reached_upper: bool = false
var jumped_off: bool = false


func _ready() -> void:
	super._ready()
	review = OS.get_environment("SMASH_LIFT_REVIEW") == "1"
	carrier = Lift.new()
	add_child(carrier)
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	InputMap.action_add_event("interact", key)
	moose.position.x = float(carrier.tuning.review.start_x)


func _physics_process(delta: float) -> void:
	review_time += delta
	if review:
		_drive_review()
	if Input.is_action_just_pressed("interact"):
		carrier.activate(moose.position)
	carrier.advance(delta)
	moose.position.y += carrier.carry_delta(moose.position, moose.airborne)
	var surface_y := 555.0
	var deck := carrier.surface()
	if (
		moose.position.x >= deck.position.x
		and moose.position.x <= deck.end.x
		and moose.position.y <= deck.position.y + 12
	):
		surface_y = deck.position.y
	if moose.position.x >= 820 and moose.position.y <= 352:
		surface_y = minf(surface_y, 340)
	floor_y = surface_y
	if absf(moose.position.y - floor_y) < 0.01 and vertical_speed == 0:
		moose.position.y = floor_y
	lift = minf(0, moose.position.y - floor_y)
	super._physics_process(delta)
	if carrier.moving and not moose.airborne:
		ride_error = maxf(ride_error, absf(moose.position.y - deck.position.y))
	reached_upper = reached_upper or carrier.upper
	jumped_off = jumped_off or (reached_upper and moose.position.x > deck.end.x and moose.airborne)
	status.text = "ГРУЗОВОЙ ЛИФТ · E — запуск · прыжок на верхний настил"
	Metrics.stage = "lift_gym"
	Metrics.completed = reached_upper and jumped_off and not moose.airborne
	Metrics.rig["carrier_y"] = deck.position.y
	Metrics.rig["carrier_moving"] = carrier.moving
	Metrics.rig["ride_error"] = ride_error
	Metrics.rig["reached_upper"] = reached_upper
	Metrics.rig["jumped_off"] = jumped_off


func _process(delta: float) -> void:
	super._process(delta)
	status.text = "ГРУЗОВОЙ ЛИФТ · E — запуск · прыжок на верхний настил"


func _drive_review() -> void:
	var timing: Dictionary = carrier.tuning.review
	_action(
		"right",
		(
			(review_time < float(timing.activate_at) - 0.25 and moose.position.x < 640)
			or (
				review_time >= float(timing.jump_at) - 0.6 and review_time < float(timing.finish_at)
			)
		)
	)
	_action("interact", absf(review_time - float(timing.activate_at)) < 0.04)
	_action("jump", absf(review_time - float(timing.jump_at)) < 0.04)


func _action(action: String, pressed: bool) -> void:
	if Input.is_action_pressed(action) == pressed:
		return
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _draw() -> void:
	super._draw()
	draw_rect(Rect2(820, 350, 460, 24), Color("263638"))
	draw_line(Vector2(820, 350), Vector2(1280, 350), Color("bcb591"), 5)
	for x in range(830, 1280, 28):
		draw_line(Vector2(x, 356), Vector2(x + 12, 370), Color("bf9c4b"), 5)
