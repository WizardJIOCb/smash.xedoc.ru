extends "res://scripts/world/district_run.gd"
## Native-only review driver. Uses normal input events; never changes health or enemies.

var review_time: float = 0.0
var tap_wait: float = 0.0
var jump_wait: float = 0.0
var review_inputs: Dictionary = {}


func _ready() -> void:
	super._ready()
	front.start_requested.emit.call_deferred()


func _physics_process(delta: float) -> void:
	review_time += delta
	tap_wait -= delta
	jump_wait -= delta
	if run_state == "playing":
		_drive()
	super._physics_process(delta)


func _drive() -> void:
	var closest: Enemy
	var distance := INF
	for enemy: Enemy in enemies:
		if not enemy.dead and absf(enemy.position.x - moose.position.x) < distance:
			distance = absf(enemy.position.x - moose.position.x)
			closest = enemy
	if is_instance_valid(closest):
		var direction := signf(closest.position.x - moose.position.x)
		_move(direction if distance > 82 else 0.0, distance > 200)
		if distance < 117 and tap_wait <= 0:
			_tap("kick")
			tap_wait = 0.37
		if closest.kind == "drone" and distance < 135 and jump_wait <= 0:
			_tap("jump")
			jump_wait = 0.8
	else:
		if not cleared[room_index]:
			var aim_x := relay.x
			if room_index == 1:
				if moose.position.y > 456:
					aim_x = 850
				elif moose.position.y > 396:
					aim_x = 1060
			_move(signf(aim_x - moose.position.x) if absf(aim_x - moose.position.x) > 15 else 0.0)
			if room_index == 1 and jump_wait <= 0 and absf(aim_x - moose.position.x) < 120:
				_tap("jump")
				jump_wait = 0.75
			if moose.position.distance_to(relay) < 105 and tap_wait <= 0:
				_tap("interact")
				tap_wait = 0.4
		else:
			_move(1.0, true)


func _move(direction: float, sprint: bool = false) -> void:
	_hold("left", direction < 0)
	_hold("right", direction > 0)
	_hold("sprint", sprint)


func _tap(action: String) -> void:
	_send(action, true)
	_send.call_deferred(action, false)


func _hold(action: String, pressed: bool) -> void:
	if Input.is_action_pressed(action) != pressed:
		review_inputs[action] = pressed
		_send(action, pressed)


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1 if pressed else 0
	Input.parse_input_event(event)
