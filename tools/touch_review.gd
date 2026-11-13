extends "res://scripts/world/district_run.gd"
## Raw screen-touch events through the native window, not direct game actions.

var review_time: float = 0.0
var next_event: int = 0
var schedule: Array = [
	[0.4, 0, Vector2(218, 590), true],
	[0.7, 1, Vector2(1080, 574), true],
	[0.9, 1, Vector2(1080, 574), false],
	[1.1, 1, Vector2(1080, 574), true],
	[1.3, 1, Vector2(1080, 574), false],
	[1.5, 0, Vector2(218, 590), false],
	[1.8, 1, Vector2(1190, 512), true],
	[1.95, 1, Vector2(1190, 512), false],
	[2.1, 1, Vector2(1180, 622), true],
	[2.3, 1, Vector2(1180, 622), false],
	[2.9, 1, Vector2(1069, 674), true],
	[3.5, 1, Vector2(1069, 674), false],
	[3.7, 0, Vector2(187, 650), true],
	[4.1, 1, Vector2(1180, 622), true],
	[4.3, 1, Vector2(1180, 622), false],
	[4.6, 0, Vector2(187, 650), false],
	[4.8, 1, Vector2(880, 451), true],
	[4.95, 1, Vector2(880, 451), false],
	[5.2, 1, Vector2(980, 451), true],
	[5.35, 1, Vector2(980, 451), false],
	[5.8, 1, Vector2(1080, 451), true],
	[5.95, 1, Vector2(1080, 451), false],
	[7.0, 0, Vector2(215, 590), true],
	[7.1, 1, Vector2(1218, 149), true],
	[7.3, 1, Vector2(1218, 149), false],
	[7.3, 0, Vector2(215, 590), false],
]


func _ready() -> void:
	super._ready()
	touch_controls.enabled = true
	_start_new_run()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	review_time += delta
	while next_event < schedule.size() and review_time >= float(schedule[next_event][0]):
		var item: Array = schedule[next_event]
		next_event += 1
		var event := InputEventScreenTouch.new()
		event.index = item[1]
		event.position = item[2]
		event.pressed = item[3]
		Input.parse_input_event(event)
