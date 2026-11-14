extends "res://tools/district_route_review.gd"
## Bounded normal-input route for either continuation. Never changes HP or enemies.

var seen_rooms: Array[int] = []
var seen_phases: Array[int] = []
var death_wait: float = 0
var pulse_wait: float = 0
var lift_walk: Dictionary = {}
var rule_history: Dictionary = {}
var boss_history: Dictionary = {}


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
		if enemy.boss:
			if not boss_history.has(enemy.kind):
				boss_history[enemy.kind] = []
			if not boss_history[enemy.kind].has(enemy.phase):
				boss_history[enemy.kind].append(enemy.phase)
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
	if _drive_room_rule():
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
		_move(signf(relay.x - moose.position.x) if absf(relay.x - moose.position.x) > 15 else 0.0)
		if moose.position.distance_to(relay) < 105 and tap_wait <= 0:
			_tap("interact")
			tap_wait = 0.4
	else:
		_move(1, true)


func _drive_room_rule() -> bool:
	if not is_instance_valid(campaign_rules):
		return false
	var rules := campaign_rules
	_hold("crouch", rules.kind == "metro" and rules.wave_state in ["warning", "wave"])
	if rules.kind == "port" and bool(rules.tuning.gap_enabled):
		for enemy: Enemy in enemies:
			if not enemy.dead and absf(enemy.position.x - moose.position.x) < 185:
				return false
		var right := float(rules.tuning.gap[1])
		if moose.position.x < right + 12:
			_hold("block", false)
			var wait_x := float(rules.tuning.gap[0]) - 35
			if rules.riding:
				_move(0)
			else:
				_move(
					signf(wait_x - moose.position.x) if absf(wait_x - moose.position.x) > 8 else 0.0
				)
			return true
	if rules.kind in ["vines", "roofs"]:
		var target_x := relay.x if not cleared[room_index] else 1250.0
		for enemy: Enemy in enemies:
			if not enemy.dead and enemy.position.x > moose.position.x:
				target_x = minf(target_x, enemy.position.x)
		for item: Dictionary in rules.objects:
			var rect: Rect2 = item.rect
			if item.health <= 0 or rect.end.x < moose.position.x or rect.position.x > target_x:
				continue
			_hold("block", false)
			var distance := rect.position.x - moose.position.x
			_move(1 if distance > 65 else 0.0)
			if distance <= 110 and tap_wait <= 0:
				if moose.facing < 0:
					_tap("quick_turn")
				_tap("kick")
				tap_wait = 0.45
			return true
		if rules.kind == "roofs" and bool(rules.tuning.gap_enabled) and not rules.bridge_down:
			_move(0)
			_hold("block", true)
			return true
	return false


func _observe_lift_walk() -> void:
	if not is_instance_valid(carrier) or not carrier.upper or _remaining() > 0:
		return
	var room := room_index + 1
	if not lift_walk.has(room):
		lift_walk[room] = {"jumps": jumps, "drop": 0.0, "done": false}
	var walk: Dictionary = lift_walk[room]
	if walk.done:
		return
	walk.drop = maxf(float(walk.drop), moose.position.y - float(carrier.tuning.top))
	if moose.position.x > carrier.surface().end.x + 40:
		walk.jumps = jumps - int(walk.jumps)
		walk.done = true
		Metrics.record("review_walked_off_lift")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_observe_lift_walk()
	if run_state == "lost":
		death_wait += delta
		if death_wait > 2:
			_tap("restart")
			death_wait = 0
	Metrics.rig["review_rooms"] = seen_rooms
	Metrics.rig["review_phases"] = seen_phases
	Metrics.rig["review_lift_walk"] = lift_walk
	if is_instance_valid(campaign_rules) and not campaign_rules.kind.is_empty():
		rule_history[room_index + 1] = campaign_rules.metrics()
	Metrics.rig["review_rules"] = rule_history
	Metrics.rig["review_bosses"] = boss_history
	var deadline := 480 if route.chapter >= 3 else 300
	if DisplayServer.get_name() == "headless" and (run_state == "won" or review_time > deadline):
		_sync_metrics()
		Metrics.rig["review_rooms"] = seen_rooms
		Metrics.rig["review_phases"] = seen_phases
		Metrics.rig["review_lift_walk"] = lift_walk
		Metrics.rig["review_rules"] = rule_history
		Metrics.rig["review_bosses"] = boss_history
		var expected_lifts := 0
		for index in range(int(route.current().start), int(route.current().end) + 1):
			if rooms[index].has("lift"):
				expected_lifts += 1
		var walk_ok := lift_walk.size() == expected_lifts
		for walk: Dictionary in lift_walk.values():
			walk_ok = walk_ok and walk.done and walk.jumps == 0 and float(walk.drop) <= 0.01
		print("CAMPAIGN_REVIEW ", JSON.stringify(Metrics.rig))
		get_tree().quit(0 if run_state == "won" and walk_ok else 1)
