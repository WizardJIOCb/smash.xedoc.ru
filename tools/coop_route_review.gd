extends "res://tools/district_route_review.gd"
## Two real game instances, normal input only; no health/enemy mutation.
var seen_rooms: Array[int] = []
var seen_phases: Array[int] = []
var pulse_wait: float = 0
var report_clock: float = 0
var done_clock: float = 0
var role: String = "host"
var joined: bool = false
var selected: bool = false
var review_chapter: int = 0


func _ready() -> void:
	super._ready()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--review-role="):
			role = arg.trim_prefix("--review-role=")
		if arg.begins_with("--review-chapter="):
			review_chapter = int(arg.trim_prefix("--review-chapter="))
	_wait_for_party.call_deferred()


func _wait_for_party() -> void:
	if not coop.active:
		run_state = "menu"


func _physics_process(delta: float) -> void:
	if role == "guest" and not joined and FileAccess.file_exists("res://.tools/coop-host.json"):
		var host_state = JSON.parse_string(
			FileAccess.get_file_as_string("res://.tools/coop-host.json")
		)
		if host_state is Dictionary and not str(host_state.get("code", "")).is_empty():
			coop.endpoint = "ws://127.0.0.1:8791/coop"
			coop.join_room("Гость", str(host_state.code))
			joined = true
	if role == "host" and coop.active and not selected and review_chapter > 0:
		selected = true
		coop.send({"type": "chapter", "chapter": review_chapter})
	super._physics_process(delta)
	report_clock += delta
	if report_clock >= 0.25:
		report_clock = 0
		var info = {
			"code": coop.room.get("code", ""),
			"role": role,
			"active": coop.active,
			"hosting": coop.hosting,
			"room": room_index,
			"health": health,
			"state": run_state,
			"kills": kills,
			"hits": hits_landed,
			"relays": cleared.count(true),
			"seconds": elapsed_run,
			"players": coop._snapshot().players,
			"wave": route.wave
		}
		var file = FileAccess.open("res://.tools/coop-" + role + ".json", FileAccess.WRITE)
		file.store_string(JSON.stringify(info))
	if run_state == "won":
		done_clock += delta
		if done_clock > (4 if role == "host" else 2):
			print(
				"COOP_REVIEW_PASS ",
				role,
				" kills=",
				kills,
				" relays=",
				cleared.count(true),
				" rooms=",
				seen_rooms
			)
			get_tree().quit(0)
	if review_time > 160:
		print(
			"COOP_REVIEW_TIMEOUT ",
			role,
			" state=",
			run_state,
			" room=",
			room_index,
			" kills=",
			kills
		)
		get_tree().quit(1)


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
		var aim_x := relay.x
		if room_index == 1:
			if moose.position.y > 456:
				aim_x = 850
			elif moose.position.y > 396:
				aim_x = 1060
		_move(signf(aim_x - moose.position.x) if absf(aim_x - moose.position.x) > 15 else 0.0)
		if room_index == 1 and jump_wait <= 0 and absf(aim_x - moose.position.x) < 120:
			_tap("jump")
			jump_wait = 0.75
		if moose.position.distance_to(relay) < 105 and tap_wait <= 0:
			_tap("interact")
			tap_wait = 0.4
	else:
		_move(1, true)
