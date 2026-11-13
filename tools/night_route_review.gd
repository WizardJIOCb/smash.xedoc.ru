extends "res://tools/district_route_review.gd"
## Exercises the released controls through ordinary input; never submits a score.

var night_seen: bool = false
var expiry_seen: bool = false
var snapshots: Array = []
var snapshot_wait: float = 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	snapshot_wait -= delta
	if snapshot_wait <= 0:
		snapshot_wait = 0.5
		snapshots.append(
			{
				"t": review_time,
				"state": run_state,
				"remaining": night.remaining,
				"charge": night.charge,
				"bursts": night.bursts,
				"damage": night_damage,
				"burst_hits": burst_hits,
				"health": health,
				"room": room_index + 1
			}
		)
	if night.active():
		night_seen = true
	elif night_seen:
		expiry_seen = true
	Metrics.rig["night_review"] = {
		"saw_night": night_seen, "saw_expiry": expiry_seen, "snapshots": snapshots
	}


func _drive() -> void:
	super._drive()
	var close_enemy := false
	for enemy: Enemy in enemies:
		if not enemy.dead and moose.position.distance_to(enemy.position) < 180:
			close_enemy = true
	if close_enemy:
		if not night_seen and night.charge >= 100:
			_tap("ultimate")
		elif night.active() and night.cooldown <= 0:
			_tap("super_strike")
