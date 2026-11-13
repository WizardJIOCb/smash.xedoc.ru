extends "res://tools/district_route_review.gd"
## Bounded normal-input route for either continuation. Never changes HP or enemies.

var seen_rooms: Array[int] = []
var seen_phases: Array[int] = []
var death_wait: float = 0
var pulse_wait: float = 0


func _ready() -> void:
	super._ready()
	var chapter := maxi(2, OS.get_environment("SMASH_REVIEW_CHAPTER").to_int())
	_select_chapter.call_deferred(chapter - 1)


func _drive() -> void:
	pulse_wait -= 1.0 / 60
	if not seen_rooms.has(room_index + 1):
		seen_rooms.append(room_index + 1)
	var closest: Enemy
	var distance := INF
	for enemy: Enemy in enemies:
		if enemy.boss and not seen_phases.has(enemy.phase):
			seen_phases.append(enemy.phase)
		if not enemy.dead and absf(enemy.position.x - moose.position.x) < distance:
			distance = absf(enemy.position.x - moose.position.x)
			closest = enemy
	if not armory.pickups.is_empty():
		var pickup: Vector2 = armory.pickups[0].at
		_move(signf(pickup.x - moose.position.x) if absf(pickup.x - moose.position.x) > 25 else 0.0)
		_hold("block", false)
		if pickup.distance_to(moose.position) < 75 and tap_wait <= 0:
			_tap("interact")
			tap_wait = 0.3
		return
	if is_instance_valid(closest):
		var direction := signf(closest.position.x - moose.position.x)
		if moose.facing != direction:
			_hold("block", false)
			_move(direction)
			return
		var ranged := armory.is_ranged()
		var desired := 280.0 if ranged else 100.0
		_move(direction if distance > desired else 0.0, distance > 300)
		var defend := (
			closest.state in ["windup", "attack"] and distance < float(closest.tuning.reach) + 30
		)
		_hold("block", defend and moose.combat.elapsed < 0)
		if health < 55 and night.charge >= 100:
			_tap("ultimate")
		if night.active() and distance < 300 and pulse_wait <= 0:
			_tap("super_strike")
			pulse_wait = 2.2
		if ranged and armory.stats().loaded == 0:
			_tap("reload_weapon")
		if not defend and distance < (650 if ranged else 165) and tap_wait <= 0:
			_tap("strike" if ranged or armory.equipped != "fists" else "kick")
			tap_wait = 0.15 if ranged else 0.32
		if closest.boss and closest.state == "attack" and jump_wait <= 0:
			_tap("jump")
			jump_wait = 1.1
		return
	_hold("block", false)
	if not route.waves_done(rooms[room_index]):
		_move(0)
		return
	if not cleared[room_index]:
		if is_instance_valid(carrier) and carrier.moving and carrier.board(moose.position):
			_move(0)
			return
		if is_instance_valid(carrier) and moose.position.y > 400:
			_move(signf(680 - moose.position.x) if absf(moose.position.x - 680) > 15 else 0.0)
			if carrier.board(moose.position) and not carrier.moving and tap_wait <= 0:
				_tap("interact")
				tap_wait = 0.4
			return
		if is_instance_valid(carrier) and carrier.upper and moose.position.x < 820:
			_move(1)
			if moose.position.x > 715 and jump_wait <= 0:
				_tap("jump")
				jump_wait = 0.7
			return
		_move(signf(relay.x - moose.position.x) if absf(relay.x - moose.position.x) > 15 else 0.0)
		if moose.position.distance_to(relay) < 105 and tap_wait <= 0:
			_tap("interact")
			tap_wait = 0.4
	else:
		_move(1, true)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if run_state == "lost":
		death_wait += delta
		if death_wait > 2:
			_tap("restart")
			death_wait = 0
	Metrics.rig["review_rooms"] = seen_rooms
	Metrics.rig["review_phases"] = seen_phases
	if DisplayServer.get_name() == "headless" and (run_state == "won" or review_time > 300):
		_sync_metrics()
		Metrics.rig["review_rooms"] = seen_rooms
		Metrics.rig["review_phases"] = seen_phases
		print("CAMPAIGN_REVIEW ", JSON.stringify(Metrics.rig))
		get_tree().quit(0 if run_state == "won" else 1)
