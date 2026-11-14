extends "res://tools/campaign_route_review.gd"
## Actual holiday battle through ordinary inputs; the second hero is a render proxy.

const ExtraPlayer = preload("res://scripts/network/coop_actor.gd")

var perf_previous: int = 0
var perf_buckets: Dictionary = {}
var perf_finish: float = 0


func _ready() -> void:
	super._ready()
	get_window().unfocusable = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var extra := ExtraPlayer.new()
	extra.peer_id = "2"
	extra.compact_tag = true
	add_child(extra)
	extra.reset_at(Vector2(1130, 555))
	extra.armory.grant("shovel")
	perf_previous = Time.get_ticks_usec()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if run_state == "won":
		perf_finish += delta
	if perf_finish > 2 or review_time > 90:
		print(
			"HOLIDAY_ROUTE_BENCHMARK ",
			JSON.stringify(
				{
					"state": run_state,
					"kills": kills,
					"health": health,
					"deaths": deaths,
					"phases": perf_buckets
				}
			)
		)
		get_tree().quit(0 if run_state == "won" else 1)


func _process(delta: float) -> void:
	super._process(delta)
	var now := Time.get_ticks_usec()
	var frame := (now - perf_previous) / 1000.0
	perf_previous = now
	if review_time < 2:
		return
	var live := 0
	var corpses := 0
	for enemy: Enemy in enemies:
		live += int(not enemy.dead)
		corpses += int(enemy.dead and enemy.rig.visible)
	var phase := (
		"combat_corpses" if live > 0 and corpses > 0 else ("combat" if live > 0 else "cleared")
	)
	if not perf_buckets.has(phase):
		perf_buckets[phase] = {
			"frames": 0,
			"total_frame_ms": 0.0,
			"max_frame_ms": 0.0,
			"total_draw_calls": 0.0,
			"max_draw_calls": 0.0,
			"total_physics_ms": 0.0,
			"max_corpses": 0
		}
	var bucket: Dictionary = perf_buckets[phase]
	var calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	bucket.frames += 1
	bucket.total_frame_ms += frame
	bucket.max_frame_ms = maxf(bucket.max_frame_ms, frame)
	bucket.total_draw_calls += calls
	bucket.max_draw_calls = maxf(bucket.max_draw_calls, calls)
	bucket.total_physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
	bucket.max_corpses = maxi(bucket.max_corpses, corpses)
