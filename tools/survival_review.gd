extends "res://tools/coop_route_review.gd"
## Ordinary-input survival review. Stop fighting at a target wave to test real defeat.

var survival_solo: bool = false
var give_up_wave: int = 3
var survival_done: float = 0


func _ready() -> void:
	super._ready()
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--survival-solo":
			survival_solo = true
		if arg.begins_with("--give-up-wave="):
			give_up_wave = int(arg.trim_prefix("--give-up-wave="))
	if survival_solo:
		_start_survival.call_deferred()


func _drive() -> void:
	if survival.enabled and survival.wave >= give_up_wave:
		_move(0)
		_hold("block", false)
		return
	super._drive()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not survival.enabled:
		return
	var file := FileAccess.open(
		"res://.tools/survival-%s-%s.json" % [review_run, role], FileAccess.WRITE
	)
	var report := survival.stats(self)
	report.merge(
		{
			"state": run_state,
			"health": health,
			"mode": "coop" if coop.active else "solo",
			"survival": survival.snapshot(),
			"actors": coop._snapshot().players,
			"enemies": enemies.size(),
			"living": _remaining()
		}
	)
	file.store_string(JSON.stringify(report))
	if run_state == "lost":
		survival_done += delta
		if survival_done > (4 if role == "host" and coop.active else 2):
			print("SURVIVAL_REVIEW_PASS ", role, " ", JSON.stringify(survival.stats(self)))
			get_tree().quit(0)
