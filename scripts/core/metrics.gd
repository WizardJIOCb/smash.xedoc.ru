extends Node

var completed: bool = false
var events: Array[Dictionary] = []
var probe_x: float = 640.0
var probe_y: float = 490.0
var quarantine: bool = false
var stage: String = "web_setup_only"
var skeletal_animation: bool = false
var rig: Dictionary = {}


func record(event: String) -> void:
	events.append({"event": event, "ms": Time.get_ticks_msec()})


func to_dict() -> Dictionary:
	return {
		"completed": completed,
		"events": events,
		"probe": [probe_x, probe_y],
		"quarantine": quarantine,
		"stage": stage,
		"skeletal_animation": skeletal_animation,
		"rig": rig,
	}
