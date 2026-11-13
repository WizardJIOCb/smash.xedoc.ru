extends "res://scripts/world/district_run.gd"
## Native visual review: jump normally on the third road and the upper alley ledge.

var review_clock: float = 0.0
var ledge_review: bool = false
var tapped: bool = false


func _ready() -> void:
	super._ready()
	_start_new_run()
	_load_room(2, 400)
	closeup = true
	for enemy: Enemy in enemies:
		enemy.paused = true


func _physics_process(delta: float) -> void:
	review_clock += delta
	if review_clock >= 2.4 and not ledge_review:
		ledge_review = true
		_load_room(1, 1080)
		moose.position.y = 415
		floor_y = 415
		tapped = false
		for enemy: Enemy in enemies:
			enemy.paused = true
	if review_clock >= (2.9 if ledge_review else 0.4) and not tapped:
		tapped = true
		var event := InputEventAction.new()
		event.action = "jump"
		event.pressed = true
		Input.parse_input_event(event)
		event = InputEventAction.new()
		event.action = "jump"
		Input.parse_input_event.call_deferred(event)
	super._physics_process(delta)
	Metrics.rig["landing_splash_y"] = _dust_y
