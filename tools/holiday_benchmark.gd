extends "res://scripts/world/district_run.gd"
## Rendered stress fixture, not a live completion or a network benchmark.

const ExtraPlayer = preload("res://scripts/network/coop_actor.gd")

var bench_time: float = 0
var bench_extra: ExtraPlayer
var bench_bodies: Array[Enemy] = []
var bench_corpse_count: int = 6
var bench_fx: bool = true
var bench_players: int = 2
var bench_previous: int = 0
var bench_buckets: Dictionary = {}
var bench_spawned: bool = false
var bench_label: String = ""


func _ready() -> void:
	super._ready()
	get_window().unfocusable = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--corpses="):
			bench_corpse_count = int(arg.trim_prefix("--corpses="))
		if arg == "--no-holiday-fx":
			bench_fx = false
		if arg == "--one-player":
			bench_players = 1
		if arg.begins_with("--label="):
			bench_label = arg.trim_prefix("--label=")
	_select_chapter(route.chapters.size() - 1)
	blood.rng.seed = 7
	# Freeze the encounter only in this fixture; actual enemy death/physics/render paths remain.
	for enemy: Enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	rooms[room_index].waves = []
	holiday_fx.visible = bench_fx
	holiday_fx.set_process(bench_fx)
	if bench_players == 2:
		bench_extra = ExtraPlayer.new()
		bench_extra.peer_id = "2"
		bench_extra.compact_tag = true
		add_child(bench_extra)
		bench_extra.reset_at(Vector2(1050, floor_y))
		bench_extra.armory.grant("shovel")
	for index in range(bench_corpse_count):
		var actor := Enemy.new()
		actor.kind = ["hare", "beaver", "foreman", "whip", "hare", "beaver"][index % 6]
		actor.tuning = encounter[actor.kind]
		actor.position = Vector2(250 + index * 130, floor_y)
		actor.wounded.connect(blood.spill)
		actor.visible = false
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(actor)
		bench_bodies.append(actor)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	bench_previous = Time.get_ticks_usec()
	print(
		"HOLIDAY_BENCH_START ",
		bench_label,
		" fx=",
		bench_fx,
		" players=",
		bench_players,
		" corpses=",
		bench_corpse_count
	)


func _physics_process(delta: float) -> void:
	bench_time += delta
	if bench_time >= 5 and not bench_spawned:
		bench_spawned = true
		for index in range(bench_corpse_count):
			var actor := bench_bodies[index]
			actor.visible = true
			actor.process_mode = Node.PROCESS_MODE_INHERIT
			actor.receive_hit(index + 1, "kick", 999, actor.position - Vector2(10, 0))
	super._physics_process(delta)
	if bench_time >= 17:
		_bench_report()
		get_tree().quit()


func _process(delta: float) -> void:
	super._process(delta)
	var now := Time.get_ticks_usec()
	var frame := (now - bench_previous) / 1000.0
	bench_previous = now
	var phase := (
		"idle"
		if bench_time < 5
		else ("falling" if bench_time < 8 else ("settled" if bench_time < 14 else "fading"))
	)
	if bench_time < 2:
		return
	if not bench_buckets.has(phase):
		bench_buckets[phase] = {
			"frame_ms": [],
			"process_ms": [],
			"physics_ms": [],
			"draw_calls": [],
			"active_bodies": [],
			"render_cpu_ms": [],
			"render_gpu_ms": [],
			"settled": []
		}
	var bucket: Dictionary = bench_buckets[phase]
	bucket.frame_ms.append(frame)
	bucket.process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
	bucket.physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)
	bucket.draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	bucket.active_bodies.append(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS))
	bucket.render_cpu_ms.append(
		RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid())
	)
	bucket.render_gpu_ms.append(
		RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	)
	var settled_count := 0
	for actor: Enemy in bench_bodies:
		if is_instance_valid(actor.corpse):
			settled_count += int(actor.corpse.settled)
	bucket.settled.append(settled_count)


func _bench_report() -> void:
	var report := {
		"label": bench_label,
		"holiday_fx": bench_fx,
		"players": bench_players,
		"corpses": bench_corpse_count,
		"phases": {}
	}
	for phase: String in bench_buckets:
		report.phases[phase] = {}
		for metric: String in bench_buckets[phase]:
			var values: Array = bench_buckets[phase][metric]
			values.sort()
			var sum := 0.0
			for value: float in values:
				sum += value
			report.phases[phase][metric] = {
				"mean": sum / values.size(),
				"p95": values[int(values.size() * 0.95)],
				"max": values.back(),
				"samples": values.size()
			}
	print("HOLIDAY_BENCHMARK ", JSON.stringify(report))
