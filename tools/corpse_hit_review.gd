extends "res://tools/district_route_review.gd"
## Normal inputs: defeat a boar, wait for it to rest, then kick and juggle it.

var resting_seen: bool = false
var airborne_hits: int = 0
var resting_hits: int = 0
var last_hits: int = 0


func _drive() -> void:
	var victim: Enemy
	for enemy: Enemy in enemies:
		if enemy.dead and is_instance_valid(enemy.corpse):
			victim = enemy
			break
	if not is_instance_valid(victim):
		super._drive()
		return
	var corpse := victim.corpse
	var at: Vector2 = corpse.bodies.hips.position
	if corpse_hits > last_hits:
		if at.y < floor_y - 90:
			airborne_hits += corpse_hits - last_hits
		else:
			resting_hits += corpse_hits - last_hits
		last_hits = corpse_hits
	resting_seen = resting_seen or corpse.settled
	if not resting_seen:
		_move(0)
		return
	var gap := at.x - moose.position.x
	var approach := gap - 100
	_move(signf(approach) if absf(approach) > 12 else 0.0, approach > 190)
	_hold("crouch", absf(gap) < 140 and at.y >= floor_y - 95)
	if absf(gap) < 135 and tap_wait <= 0:
		_tap("kick" if at.y >= floor_y - 95 else "punch")
		tap_wait = 0.45
	if at.y < floor_y - 140 and jump_wait <= 0:
		_tap("jump")
		jump_wait = 0.85


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	Metrics.rig["review_resting_seen"] = resting_seen
	Metrics.rig["review_resting_hits"] = resting_hits
	Metrics.rig["review_airborne_hits"] = airborne_hits
	Metrics.rig["review_upright"] = absf(moose.bones.hips.rotation) < 0.001
	if DisplayServer.get_name() == "headless" and review_time > 24:
		print("CORPSE_REVIEW ", JSON.stringify(Metrics.rig))
		get_tree().quit()
