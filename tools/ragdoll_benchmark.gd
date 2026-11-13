extends "res://tools/ragdoll_review.gd"
## Actual rendered frames, without capture/readback or --fixed-fps.

var buckets: Dictionary = {}
var previous_tick: int = 0
var reported: bool = false


func _ready() -> void:
	super._ready()
	get_window().unfocusable = true
	fired = true


func _physics_process(delta: float) -> void:
	if time >= 3 and corpses.is_empty():
		fired = false
	super._physics_process(delta)


func _process(_delta: float) -> void:
	var tick := Time.get_ticks_usec()
	var frame_ms := (tick - previous_tick) / 1000.0
	previous_tick = tick
	if time > 1 and time < 14:
		var phase := "baseline" if time < 3 else ("falling" if time < 6 else ("landing" if time < 10 else "settled"))
		if not buckets.has(phase):
			buckets[phase] = {"frame_ms": [], "physics_ms": [], "script_ms": [], "active": []}
		var bucket: Dictionary = buckets[phase]
		bucket.frame_ms.append(frame_ms)
		bucket.physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)
		bucket.script_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
		bucket.active.append(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS))
	if time >= 14 and not reported:
		reported = true
		var report := {}
		for phase: String in buckets:
			report[phase] = {}
			for metric: String in buckets[phase]:
				var values: Array = buckets[phase][metric]
				values.sort()
				var sum := 0.0
				for value: float in values:
					sum += value
				report[phase][metric] = {"mean": sum / values.size(), "p95": values[int(values.size() * 0.95)], "max": values.back()}
		print("RAGDOLL_BENCHMARK ", JSON.stringify(report))
		get_tree().quit()
