extends Node2D
## Blood-only rendered benchmark. No enemies, ragdolls, screenshot readback or fixed fps.

const Blood = preload("res://scripts/world/blood_fx.gd")

var blood: Blood
var clock: float = 0
var emitted_once: bool = false
var emitted_stress: bool = false
var previous_tick: int = 0
var buckets: Dictionary = {}


func _ready() -> void:
	get_window().unfocusable = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 240
	var background := Sprite2D.new()
	background.texture = load("res://assets/environment/courtyard-alive-clean.png")
	background.centered = false
	background.scale = Vector2(1280, 720) / background.texture.get_size()
	background.z_index = -10
	add_child(background)
	blood = Blood.new()
	blood.rng.seed = 7
	blood.surfaces = [Rect2(-100, 560, 1480, 30)]
	blood.z_index = 24
	add_child(blood)


func _physics_process(delta: float) -> void:
	clock += delta
	if clock >= 3 and not emitted_once:
		emitted_once = true
		blood.spill(Vector2(600, 400), Vector2(220, -80), true)
	if clock >= 7 and not emitted_stress:
		emitted_stress = true
		blood.spill(Vector2(380, 360), Vector2(-200, -80), true)
		blood.spill(Vector2(940, 380), Vector2(200, -80), true)
	blood.visible = clock < 6 or clock >= 7
	if clock >= 20:
		var report := {}
		for phase: String in buckets:
			report[phase] = {}
			for metric: String in buckets[phase]:
				var values: Array = buckets[phase][metric]
				values.sort()
				var total := 0.0
				for value: float in values:
					total += value
				report[phase][metric] = {"mean": total / values.size(), "p95": values[int(values.size() * 0.95)], "max": values.back()}
		print("BLOOD_BENCHMARK ", JSON.stringify(report))
		get_tree().quit()


func _process(_delta: float) -> void:
	var tick := Time.get_ticks_usec()
	var frame_ms := (tick - previous_tick) / 1000.0
	previous_tick = tick
	var phase := ""
	if clock > 1 and clock < 3:
		phase = "baseline"
	elif clock >= 3 and clock < 4.5:
		phase = "droplets"
	elif clock >= 4.5 and clock < 6:
		phase = "one_burst_pools"
	elif clock >= 6 and clock < 7:
		phase = "hidden_pools"
	elif clock >= 9 and clock < 12:
		phase = "maximum_pools"
	elif clock >= 16 and clock < 19:
		phase = "fading_pools"
	if phase.is_empty():
		return
	if not buckets.has(phase):
		buckets[phase] = {"frame_ms": [], "draw_calls": [], "stains": [], "drops": []}
	buckets[phase].frame_ms.append(frame_ms)
	buckets[phase].draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	buckets[phase].stains.append(blood.stains.size())
	buckets[phase].drops.append(blood.drops.size())
