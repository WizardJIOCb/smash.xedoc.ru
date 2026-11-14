extends Node
## Room lifecycle and host-owned cooperative simulation. No gameplay authority on guests.

const Actor = preload("res://scripts/network/coop_actor.gd")
const Codec = preload("res://scripts/network/coop_codec.gd")
const Lobby = preload("res://scripts/ui/coop_lobby.gd")
const CampaignContact = preload("res://scripts/world/campaign_contact.gd")
const ACTIONS = [
	"left",
	"right",
	"jump",
	"crouch",
	"sprint",
	"strike",
	"kick",
	"block",
	"interact",
	"cycle_weapon",
	"reload_weapon",
	"drop_weapon",
	"quick_turn",
	"ultimate",
	"super_strike",
	"world"
]
const CONTEXT = [
	"moose",
	"armory",
	"night",
	"health",
	"floor_y",
	"speed",
	"lift",
	"vertical_speed",
	"_tip_serial",
	"_previous_tip"
]

var run: Node2D
var lobby: Lobby
var socket: WebSocketPeer
var room: Dictionary = {}
var you: String = ""
var actors: Dictionary = {}
var active: bool = false
var starting: bool = false
var hosting: bool = false
var epoch: int = 0
var endpoint: String = "wss://smash.xedoc.ru/coop"
var sequence: int = 0
var host_recovery: float = 0
var _pending: Dictionary = {}
var _edges: Array = []
var _send_clock: float = 0
var _last_packet: int = 0
var _connect_started: int = 0
var _guest_epoch: int = -1
var _inside_context: bool = false
var _start_automatically: bool = false
var _qa_players: int = 0
var _solo_endpoint: String = ""


func _ready() -> void:
	run = get_parent()
	_solo_endpoint = run.scores.endpoint
	process_priority = -100
	lobby = Lobby.new()
	lobby.chapters = run.route.chapters
	add_child(lobby)
	lobby.create_requested.connect(create_room)
	lobby.join_requested.connect(join_room)
	lobby.start_requested.connect(
		func(chapter: int) -> void: send({"type": "start", "chapter": chapter})
	)
	lobby.leave_requested.connect(leave)
	lobby.back_requested.connect(_back)
	var invitation := ""
	if OS.has_feature("web"):
		invitation = str(
			JavaScriptBridge.eval("new URLSearchParams(location.search).get('room') || ''", true)
		)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--coop-url="):
			endpoint = arg.trim_prefix("--coop-url=")
		elif arg.begins_with("--coop-create="):
			_qa_players = int(arg.trim_prefix("--coop-create="))
		elif arg.begins_with("--coop-join="):
			invitation = arg.trim_prefix("--coop-join=")
		elif arg == "--coop-autostart":
			_start_automatically = true
	if not invitation.is_empty():
		open()
		lobby.invite(invitation)
		if not OS.has_feature("web"):
			join_room("Гость", invitation)
	if _qa_players >= 2:
		create_room("Ведущий", _qa_players)


func open() -> void:
	run.front.hide_menu()
	lobby.open()
	if not room.is_empty():
		lobby.show_room(room, you)


func _back() -> void:
	lobby.hide_lobby()
	if not active:
		run.front.show_home(false)


func create_room(player_name: String, capacity: int) -> void:
	_connect({"type": "create", "name": player_name, "capacity": capacity, "build": _build_id()})


func join_room(player_name: String, code: String) -> void:
	_connect(
		{
			"type": "join",
			"name": player_name,
			"room": code.strip_edges().to_upper(),
			"build": _build_id()
		}
	)


func _build_id() -> String:
	return (
		"coop2-"
		+ FileAccess.get_file_as_string("res://data/district_rooms.json").sha256_text().left(12)
	)


func _connect(request: Dictionary) -> void:
	if is_instance_valid(socket):
		socket.close()
	socket = WebSocketPeer.new()
	socket.inbound_buffer_size = 1048576
	socket.outbound_buffer_size = 1048576
	_pending = request
	_connect_started = Time.get_ticks_msec()
	_last_packet = _connect_started
	lobby.open()
	lobby.set_busy("Соединяюсь с двором…")
	if socket.connect_to_url(endpoint) != OK:
		_fail("Не удалось соединиться. Попробуй ещё раз.")


func send(packet: Dictionary) -> void:
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if socket.get_current_outbound_buffered_amount() < 524288:
			socket.send_text(JSON.stringify(packet))


func _process(delta: float) -> void:
	if socket == null:
		return
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if not _pending.is_empty():
			send(_pending)
			_pending = {}
		while socket != null and socket.get_available_packet_count() > 0:
			var packet = JSON.parse_string(socket.get_packet().get_string_from_utf8())
			if packet is Dictionary:
				_last_packet = Time.get_ticks_msec()
				_receive(packet)
				if socket == null:
					return
	elif socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		_fail("Соединение потеряно. Можно создать новую комнату или войти снова.")
		return
	if (
		(active and not hosting and Time.get_ticks_msec() - _last_packet > 12000)
		or (not _pending.is_empty() and Time.get_ticks_msec() - _connect_started > 12000)
	):
		_fail("Двор не отвечает. Проверь сеть и подключись снова.")
		return
	if not active:
		_sync_metrics()
		return
	_send_clock += delta
	if _send_clock >= 0.05:
		_send_clock = 0
		if hosting:
			send({"type": "snapshot", "state": _snapshot()})
		else:
			var held := {}
			for action: String in ACTIONS:
				held[action] = Input.is_action_pressed(action) and not lobby.root.visible
			sequence += 1
			send({"type": "input", "seq": sequence, "held": held, "pressed": _edges.duplicate()})
			_edges.clear()
		_sync_metrics()


func _receive(packet: Dictionary) -> void:
	match str(packet.get("type", "")):
		"error":
			lobby.show_error(str(packet.message))
		"closed":
			_fail(str(packet.reason))
		"room":
			you = str(packet.you)
			room = packet.room
			hosting = str(room.host) == you
			_sync_members()
			if not active or lobby.root.visible:
				lobby.show_room(room, you)
			if (
				_start_automatically
				and hosting
				and not active
				and room.players.size() >= _qa_players
			):
				send({"type": "start", "chapter": 0})
				_start_automatically = false
		"start":
			if room.is_empty():
				return
			_start(int(packet.chapter))
		"input":
			if hosting and active and actors.has(str(packet.id)):
				var actor: Actor = actors[str(packet.id)]
				actor.held_input = packet.held
				for action: String in packet.pressed:
					if not actor.pressed_input.has(action):
						actor.pressed_input.append(action)
				actor.last_input = Time.get_ticks_msec()
		"snapshot":
			if not hosting:
				_apply_snapshot(packet.state)


func _start(chapter: int) -> void:
	active = true
	starting = true
	_guest_epoch = -1
	lobby.hide_lobby()
	run.scores.endpoint = ""
	run._select_chapter(chapter)
	starting = false
	run.front.hide_menu()
	_sync_members()
	if hosting:
		room_loaded()
	else:
		for enemy: Node2D in run.enemies:
			enemy.set_physics_process(false)


func _sync_members() -> void:
	var present := []
	for member: Dictionary in room.get("players", []):
		var id := str(member.id)
		if id == you:
			continue
		present.append(id)
		if not actors.has(id):
			var actor := Actor.new()
			actor.peer_id = id
			actor.player_name = str(member.name)
			actors[id] = actor
			run.add_child(actor)
			actor.armory._serial -= int(id) * 100000
			actor.armory.projectile_hit.connect(_remote_bullet.bind(actor))
			actor.visible = active
			actor.reset_at(Vector2(140 + int(id) * 38, float(run.rooms[run.room_index].floor)))
			actor.armory.pickups = run.armory.pickups
		actors[id].compact_tag = room.players.size() > 6
	for id: String in actors.keys():
		if not present.has(id):
			var actor: Actor = actors[id]
			for enemy: Node2D in run.enemies:
				if enemy.target == actor.moose:
					enemy.target = run.moose
			run.remove_child(actor)
			actor.queue_free()
			actors.erase(id)


func room_loaded() -> void:
	if not active or not hosting:
		return
	epoch += 1
	host_recovery = 0
	for actor: Actor in actors.values():
		actor.reset_at(
			Vector2(clampf(run.moose.position.x + int(actor.peer_id) * 32, 70, 1150), run.floor_y)
		)
		actor.armory.pickups = run.armory.pickups
		actor.visible = true


func before_step(delta: float) -> bool:
	if not active:
		return false
	if not hosting:
		run.touch_controls.set_context("menu" if lobby.root.visible else "playing")
		return true
	run.network_input = lobby.root.visible
	run.held_input = {}
	run.pressed_input = []
	if run.run_state != "playing":
		return false
	if _living_count() == 0:
		run.run_state = "lost"
		for enemy: Node2D in run.enemies:
			enemy.paused = true
		return true
	for actor: Actor in actors.values():
		if actor.health <= 0:
			actor.recovery -= delta
			if actor.recovery <= 0:
				actor.reset_at(Vector2(_safe_spawn(), float(run.rooms[run.room_index].floor)))
			continue
		actor.step(delta, run)
		_context(actor, "combat", delta)
		if actor.pressed_input.has("interact"):
			_context(actor, "interact", delta)
		actor.pressed_input.clear()
		if run.cleared[run.room_index] and actor.moose.position.x > 1230 and exit_ready():
			if run.room_index < int(run.route.current().end):
				run._load_room(run.room_index + 1, 110)
				break
	for enemy: Node2D in run.enemies:
		if not enemy.dead and (enemy.state == "approach" or not is_instance_valid(enemy.target)):
			var nearest: Node2D = run.moose if run.health > 0 else null
			var distance := (
				enemy.position.distance_to(run.moose.position) if run.health > 0 else INF
			)
			for actor: Actor in actors.values():
				var gap := enemy.position.distance_to(actor.moose.position)
				if actor.health > 0 and gap < distance:
					distance = gap
					nearest = actor.moose
			if nearest != null:
				enemy.target = nearest
	if run.health <= 0:
		host_recovery -= delta
		if host_recovery <= 0:
			_revive_host()
		else:
			run.continuation.advance_lift(run, delta, false)
			run.campaign_rules.advance(run, delta, false)
			_advance_terrain(false)
			run.armory.advance(delta, run.enemies, true)
			run._move_projectiles(delta)
			return true
	return false


func _context(actor: Actor, operation: String, delta: float = 0, payload: Array = []) -> void:
	var saved := {}
	for field: String in CONTEXT:
		saved[field] = run.get(field)
	run.moose = actor.moose
	run.armory = actor.armory
	run.night = actor.night
	run.health = actor.health
	run.floor_y = actor.floor_y
	run.speed = actor.speed
	run.lift = actor.lift
	run.vertical_speed = actor.vertical_speed
	run._tip_serial = actor.tip_serial
	run._previous_tip = actor.previous_tip
	_inside_context = true
	match operation:
		"combat":
			if actor.night.advance(delta):
				run._release_impulse()
			CampaignContact.intercept_player_fire(run, run.campaign_rules, delta)
			actor.armory.advance(delta, run.enemies, true, false)
			run._resolve_attacks()
		"interact":
			run._interact()
		"bullet":
			run.continuation.weapon_contact.callv(payload + [run])
	actor.health = run.health
	actor.tip_serial = run._tip_serial
	actor.previous_tip = run._previous_tip
	for field: String in CONTEXT:
		run.set(field, saved[field])
	_inside_context = false


func _remote_bullet(
	target: Node2D, serial: int, amount: int, at: Vector2, axis: Vector2, kind: String, actor: Actor
) -> void:
	if _inside_context:
		run.continuation.weapon_contact(target, serial, amount, at, axis, kind, run)
	else:
		_context(actor, "bullet", 0, [target, serial, amount, at, axis, kind])


func damage_target(target: Node2D, amount: int, source: Vector2, high: bool) -> void:
	if target == run.moose:
		if run.health > 0:
			run._hurt_player(amount, source, high)
		return
	for actor: Actor in actors.values():
		if actor.moose == target:
			actor.hurt(amount, source, run)
			return


func projectile_hit(swept: Rect2, item: Dictionary, source: Vector2) -> bool:
	for actor: Actor in actors.values():
		if actor.health <= 0:
			continue
		var low: bool = actor.moose.crouch > 0.5
		var box := Rect2(
			actor.moose.position + Vector2(-19, -77 if low else -149),
			Vector2(38, 74 if low else 146)
		)
		if swept.intersects(box):
			actor.hurt(int(item.damage), source, run)
			return true
	return false


func host_down() -> void:
	host_recovery = 6


func _revive_host() -> void:
	if is_instance_valid(run.player_corpse):
		run.player_corpse.set_process(false)
		run.player_corpse.set_physics_process(false)
		run.moose.remove_child(run.player_corpse)
		run.player_corpse.queue_free()
		run.player_corpse = null
	run.moose.ragdoll_active = false
	run.moose.visible = true
	run.moose.skeleton.modulate = Color.WHITE
	for bone: Bone2D in run.moose.bones.values():
		bone.transform = bone.rest
	run.health = 100
	run.moose.position = Vector2(_safe_spawn(), float(run.rooms[run.room_index].floor))
	run.speed = 0
	run.vertical_speed = 0
	run.lift = 0


func _safe_spawn() -> float:
	for actor: Actor in actors.values():
		if actor.health > 0:
			return clampf(actor.moose.position.x - 60, 100, 1100)
	return 170


func _living_count() -> int:
	var count := 1 if run.health > 0 else 0
	for actor: Actor in actors.values():
		count += 1 if actor.health > 0 else 0
	return count


func exit_ready() -> bool:
	if run.health > 0 and run.moose.position.x < 1050:
		return false
	for actor: Actor in actors.values():
		if actor.health > 0 and actor.moose.position.x < 1050:
			return false
	return true


func handle_input(event: InputEvent) -> bool:
	if not active:
		return lobby.root.visible
	if event.is_action_pressed("pause_run"):
		if lobby.root.visible:
			lobby.hide_lobby()
		else:
			open()
		return true
	if hosting:
		return lobby.root.visible
	if not lobby.root.visible:
		for action: String in ACTIONS:
			if event.is_action_pressed(action) and not _edges.has(action):
				_edges.append(action)
	return true


func leave() -> void:
	send({"type": "leave"})
	if socket != null:
		socket.close()
	socket = null
	_clear()
	lobby.open()


func _fail(reason: String) -> void:
	if socket != null:
		socket.close()
	socket = null
	_clear()
	lobby.open()
	lobby.show_error(reason)


func _clear() -> void:
	active = false
	_guest_epoch = -1
	hosting = false
	room = {}
	you = ""
	_edges.clear()
	run.network_input = false
	run.scores.endpoint = _solo_endpoint
	for actor: Actor in actors.values():
		run.remove_child(actor)
		actor.queue_free()
	actors.clear()
	run.run_state = "menu"
	run.moose.visible = true
	for enemy: Node2D in run.enemies:
		enemy.target = run.moose
		enemy.paused = true
		enemy.set_physics_process(true)


func _snapshot() -> Dictionary:
	var players := [
		Codec.hero(you, _player_name(you), run.moose, run.armory, run.night, run.health)
	]
	for actor: Actor in actors.values():
		players.append(
			Codec.hero(
				actor.peer_id,
				actor.player_name,
				actor.moose,
				actor.armory,
				actor.night,
				actor.health
			)
		)
	var foes := []
	for enemy: Node2D in run.enemies:
		foes.append(Codec.enemy(enemy))
	var pickups := []
	for item: Dictionary in run.armory.pickups:
		var entry := {
			"id": item.id, "x": item.at.x, "y": item.at.y + 18, "reserve": item.get("reserve", -1)
		}
		pickups.append(entry)
	var projectiles := []
	for item: Dictionary in run.effects.projectiles:
		projectiles.append(
			[item.at.x, item.at.y, item.velocity.x, item.velocity.y, item.damage, item.age]
		)
	var lift_state := {}
	if is_instance_valid(run.carrier):
		for key: String in ["_y", "_target", "_speed", "previous_y", "delta_y", "moving", "upper"]:
			lift_state[key] = run.carrier.get(key)
	return {
		"epoch": epoch,
		"chapter": run.route.chapter,
		"room": run.room_index,
		"cleared": run.cleared,
		"state": run.run_state,
		"seconds": run.elapsed_run,
		"wave": run.route.wave,
		"wave_wait": run.route.wave_wait,
		"kills": run.kills,
		"night": run.world_night,
		"players": players,
		"enemies": foes,
		"pickups": pickups,
		"projectiles": projectiles,
		"lift": lift_state,
		"rules": run.campaign_rules.network_state()
	}


func _player_name(id: String) -> String:
	for member: Dictionary in room.get("players", []):
		if str(member.id) == id:
			return str(member.name)
	return "Лось"


func _apply_snapshot(state: Dictionary) -> void:
	if not active:
		active = true
		run.scores.endpoint = ""
		lobby.hide_lobby()
		run.front.hide_menu()
	if int(state.epoch) != _guest_epoch:
		_guest_epoch = int(state.epoch)
		run._finish_shown = false
		Metrics.completed = false
		run.route.chapter = int(state.chapter)
		run.cleared.assign(state.cleared)
		run._load_room(int(state.room), 170)
		run.campaign_rules.set_physics_process(false)
		run.front.hide_menu()
	_sync_members()
	for data: Dictionary in state.players:
		if str(data.id) == you:
			Codec.apply_hero(data, run.moose, run.armory, run.night)
			run.health = int(data.health)
			run.floor_y = float(run.rooms[run.room_index].floor)
			run.lift = run.moose.position.y - run.floor_y
		elif actors.has(str(data.id)):
			var actor: Actor = actors[str(data.id)]
			Codec.apply_hero(data, actor.moose, actor.armory, actor.night)
			actor.health = int(data.health)
			actor.visible = true
	while run.enemies.size() < state.enemies.size():
		var data: Dictionary = state.enemies[run.enemies.size()]
		run._spawn_enemy([data.kind, data.x, data.y])
	for index in range(mini(run.enemies.size(), state.enemies.size())):
		Codec.apply_enemy(state.enemies[index], run.enemies[index])
	run.cleared.assign(state.cleared)
	run.kills = int(state.kills)
	run.elapsed_run = float(state.seconds)
	run.route.wave = int(state.get("wave", 0))
	run.route.wave_wait = float(state.get("wave_wait", -1))
	run.world_night = bool(state.night)
	run.quarantine = not run.cleared[run.room_index]
	run.run_state = str(state.state)
	run.campaign_rules.apply_network_state(state.get("rules", {}))
	_advance_terrain(run.run_state != "playing")
	if run.run_state == "won":
		run.route.finish()
		run.front.completed_chapters = run.route.completed
		Metrics.completed = true
	run.armory.spawn_pickups(state.pickups)
	run.effects.projectiles.clear()
	for item: Array in state.projectiles:
		run.effects.projectiles.append(
			{
				"at": Vector2(item[0], item[1]),
				"velocity": Vector2(item[2], item[3]),
				"damage": item[4],
				"age": item[5]
			}
		)
	if is_instance_valid(run.carrier) and not state.lift.is_empty():
		for key: String in state.lift:
			run.carrier.set(key, state.lift[key])
		run.carrier.body.position.y = run.carrier._y + float(run.carrier.tuning.shoe_offset)
		run.carrier.queue_redraw()


func _advance_terrain(paused: bool) -> void:
	if is_instance_valid(run.terrain) and run.terrain.has_method("advance"):
		run.terrain.advance(paused)


func _sync_metrics() -> void:
	var info := {
		"connected": not room.is_empty(),
		"active": active,
		"host": hosting,
		"you": you,
		"code": room.get("code", ""),
		"capacity": room.get("capacity", 0),
		"players": room.get("players", []),
		"epoch": epoch if hosting else _guest_epoch
	}
	if active:
		info["world"] = _snapshot()
	Metrics.rig["coop"] = info
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			(
				"document.body.setAttribute('data-coop-metrics', "
				+ JSON.stringify(JSON.stringify(info))
				+ ");"
			),
			true
		)
