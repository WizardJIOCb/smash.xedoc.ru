extends "res://scripts/world/district_run.gd"
## Native visual fixture for the gate's painted floor, not a route completion.


func _ready() -> void:
	super._ready()
	_start_new_run()
	_load_room(2, 460)
	run_state = "review"
	closeup = true
	for enemy: Enemy in enemies:
		enemy.paused = true
	_notice = "ПОДСТАНЦИЯ · Общая опора поднята на 16px"
	_notice_left = 100
