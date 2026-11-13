extends Node

var completed: bool = false
var events: Array[Dictionary] = []
var probe_x: float = 640.0
var probe_y: float = 490.0
var quarantine: bool = false


func record(event: String) -> void:
	events.append({"event": event, "ms": Time.get_ticks_msec()})


func to_dict() -> Dictionary:
	return {
		"completed": completed,
		"events": events,
		"probe": [probe_x, probe_y],
		"quarantine": quarantine,
		"stage": "web_setup_only",
		"skeletal_animation": false,
	}
