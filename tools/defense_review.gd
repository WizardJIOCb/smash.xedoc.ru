extends "res://tools/district_route_review.gd"
## Real input: block several attacks, release, die, allow physics, restart.

var restarted: bool = false
var death_at: float = -1
var blocked_health: int = -1
var corpse_seen: bool = false


func _drive() -> void:
	if review_time < 14:
		_hold("block", true)
		_move(1.0 if moose.position.x < 550 else 0.0)
		blocked_health = health
	else:
		_hold("block", false)
		_move(0)
	if restarted:
		super._drive()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if run_state == "lost":
		corpse_seen = is_instance_valid(player_corpse) and player_corpse.bodies.size() == 15
		if death_at < 0:
			death_at = review_time
		if review_time > death_at + 5 and not restarted:
			restarted = true
			_tap("restart")
	Metrics.rig["review_blocked_health"] = blocked_health
	Metrics.rig["review_death_at"] = death_at
	Metrics.rig["review_corpse_seen"] = corpse_seen
	Metrics.rig["review_restarted"] = restarted
	Metrics.rig["review_restart_hips_upright"] = restarted and not moose.ragdoll_active and absf(moose.bones.hips.rotation) < 0.001
