extends "res://scripts/gyms/rig_lab.gd"
## Isolated idle pose review, independent of keyboard input in other windows.


func _ready() -> void:
	super._ready()
	closeup = true


func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % 6 == 0:
		_sync_metrics()
