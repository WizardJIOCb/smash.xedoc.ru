extends Node2D
## Room-local rules for the custom rig floor controller. Free this node on room change.

const RuleArt = preload("res://scripts/world/campaign_rule_art.gd")

var kind: String = ""
var tuning: Dictionary = {}
var objects: Array[Dictionary] = []
var elapsed: float = 0.0
var deck_x: float = 0.0
var deck_delta: float = 0.0
var dock_wait: float = 0.0
var deck_right: bool = true
var riding: bool = false
var carried_distance: float = 0.0
var falls: int = 0
var wave_state: String = "idle"
var wave_time: float = 0.0
var wave_x: float = 0.0
var wave_previous_x: float = 0.0
var wave_direction: float = 1.0
var waves: int = 0
var player_wave_hits: int = 0
var enemy_wave_hits: int = 0
var broken: int = 0
var cover_blocks: int = 0
var bridge_progress: float = 0.0
var bridge_down: bool = false

var _view: Node2D
var _player_states: Dictionary = {}
var _enemy_wave: Dictionary = {}
var _bridge_falling: bool = false
var _projectile_serial: int = -800000
var _run: Node
var _paused: bool = true
var _ride_offset: float = 0.0
var _last_carried_x: float = 0.0
var _enemy_previous: Dictionary = {}


func configure(room: Dictionary) -> void:
	var settings: Dictionary = room.get("mechanic", {})
	kind = str(settings.get("kind", ""))
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/campaign_rules.json")
	)
	if kind not in ["port", "metro", "vines", "roofs"]:
		kind = ""
		return
	tuning = data.common.duplicate(true)
	tuning.merge(data[kind].duplicate(true), true)
	tuning.floor = float(room.get("floor", tuning.floor))
	tuning.merge(settings.duplicate(true), true)
	if kind == "port":
		deck_x = _dock_x(false)
		dock_wait = float(tuning.dock_seconds)
	if kind == "metro":
		wave_time = float(tuning.first_warning)
	if kind == "vines":
		for spec: Dictionary in tuning.barriers:
			_add_object(spec, "vine", int(tuning.barrier_health))
	if kind == "roofs":
		for spec: Dictionary in tuning.covers:
			_add_object(spec, "cover", int(tuning.cover_health))
		for spec: Dictionary in tuning.supports:
			_add_object(spec, "support", int(tuning.support_health))


func _ready() -> void:
	z_index = -1
	process_physics_priority = 100
	_view = RuleArt.new()
	_view.rules = self
	add_child(_view)


func advance(run, delta: float, paused: bool) -> void:
	_run = run
	_paused = paused
	deck_delta = 0
	if kind.is_empty() or paused or delta <= 0:
		return
	elapsed += delta
	for enemy in run.enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			_enemy_previous[enemy.get_instance_id()] = enemy.position
	if kind == "port":
		_advance_port(run, delta)
	elif kind == "metro":
		_advance_metro(run, delta)
	for item: Dictionary in objects:
		item.flash = maxf(0, float(item.flash) - delta)
		item.debris = maxf(0, float(item.debris) - delta)
		if item.health > 0 or item.required or kind != "vines":
			continue
		var regrow := float(tuning.optional_regrow_seconds)
		if regrow > 0:
			item.cleared_age += delta
			if item.cleared_age >= regrow and not _occupied(run, item.rect):
				item.health = item.maximum
				item.last_serial = -1
	if kind == "roofs":
		_intercept_projectiles(run, delta)
		if _bridge_falling:
			bridge_progress = minf(
				1, bridge_progress + delta / maxf(0.01, float(tuning.bridge_drop_seconds))
			)
			if bridge_progress >= 1 and not bridge_down:
				bridge_down = true
				_feedback(run, Vector2(_gap_center(), tuning.floor - 35), "МОСТ ГОТОВ →", "relay")
	if is_instance_valid(_view):
		_view.queue_redraw()


func _physics_process(_delta: float) -> void:
	# Enemies have their own movement tick; constrain their feet after that tick.
	if is_instance_valid(_run) and not _paused and kind in ["port", "vines", "roofs"]:
		_ground_enemies(_run)


func floor_at(run, base_floor: float) -> float:
	if kind not in ["port", "roofs"] or base_floor < float(tuning.floor) - 1:
		return base_floor
	var feet: Vector2 = run.moose.position
	if kind == "port":
		var deck := deck_rect()
		if (
			_contains_x(deck, feet.x)
			and feet.y <= deck.position.y + float(tuning.boarding_tolerance)
		):
			return minf(base_floor, deck.position.y)
	if not _in_gap(feet.x) or (kind == "roofs" and bridge_down):
		return base_floor
	return float(tuning.floor) + float(tuning.fall_depth)


func after_move(run, previous: Vector2, _delta: float) -> void:
	if kind.is_empty() or _paused:
		return
	if kind == "metro":
		_hit_player_wave(run)
		return
	_block_passage(run, previous)
	if kind not in ["port", "roofs"]:
		return
	var feet: Vector2 = run.moose.position
	var player := _player_state(run.moose)
	if (
		not _in_gap(feet.x)
		and absf(feet.y - float(tuning.floor)) < float(tuning.boarding_tolerance)
	):
		var side: float = -1 if feet.x < _gap_center() else 1
		player.safe_x = (
			float(tuning.gap[0 if side < 0 else 1]) + side * float(tuning.recovery_inset)
		)
	if (
		feet.y > float(tuning.floor) + float(tuning.recover_depth)
		and elapsed >= player.recover_until
	):
		_recover(run)


func attack(run, serial: int, area: Rect2, damage: int) -> bool:
	if kind not in ["vines", "roofs"] or damage <= 0 or _paused:
		return false
	var touched := false
	for item: Dictionary in objects:
		if item.health <= 0 or not area.intersects(item.rect.grow(float(tuning.attack_padding))):
			continue
		touched = true
		if item.last_serial != serial:
			item.last_serial = serial
			_hit_object(run, item, damage)
	return touched


func interact(run) -> bool:
	if kind != "port" or _paused:
		return false
	var feet: Vector2 = run.moose.position
	if absf(feet.y - float(tuning.floor)) > float(tuning.boarding_tolerance):
		return false
	if _contains_x(deck_rect(), feet.x):
		dock_wait = 0
		_notice(run, "Груз идёт к другому причалу. На берег можно сойти шагом.")
		return true
	var gap: Array = tuning.gap
	var bank := float(gap[0] if feet.x < _gap_center() else gap[1])
	if absf(feet.x - bank) > float(tuning.interact_distance):
		return false
	deck_right = feet.x > _gap_center()
	dock_wait = 0
	_notice(run, "Платформа вызвана к этому причалу.")
	return true


func metrics() -> Dictionary:
	var remaining := 0
	var required_open := true
	var healths: Array[int] = []
	for item: Dictionary in objects:
		healths.append(int(item.health))
		if item.health > 0:
			remaining += 1
			if item.required:
				required_open = false
	return {
		"kind": kind,
		"enabled": not kind.is_empty(),
		"seconds": elapsed,
		"deck_x": deck_x,
		"deck_delta": deck_delta,
		"riding": riding,
		"carried_distance": carried_distance,
		"docked": dock_wait > 0,
		"falls": falls,
		"wave_state": wave_state,
		"wave_x": wave_x,
		"waves": waves,
		"player_wave_hits": player_wave_hits,
		"enemy_wave_hits": enemy_wave_hits,
		"objects_remaining": remaining,
		"object_health": healths,
		"broken": broken,
		"required_open": required_open,
		"cover_blocks": cover_blocks,
		"bridge_down": bridge_down,
		"bridge_progress": bridge_progress
	}


func deck_rect() -> Rect2:
	return Rect2(
		deck_x - float(tuning.deck_width) / 2,
		float(tuning.floor) + float(tuning.deck_offset),
		float(tuning.deck_width),
		20
	)


func wave_rect() -> Rect2:
	return Rect2(
		minf(wave_previous_x, wave_x) - float(tuning.wave_width) / 2,
		float(tuning.floor) - float(tuning.wave_top),
		absf(wave_x - wave_previous_x) + float(tuning.wave_width),
		float(tuning.wave_top) - float(tuning.wave_bottom)
	)


func sheltered(feet: Vector2) -> bool:
	if absf(feet.y - float(tuning.floor)) > float(tuning.niche_tolerance):
		return false
	for niche: Array in tuning.niches:
		if feet.x >= float(niche[0]) and feet.x <= float(niche[0]) + float(niche[1]):
			return true
	return false


func _advance_port(run, delta: float) -> void:
	var old_deck := deck_rect()
	var feet: Vector2 = run.moose.position
	var was_riding := riding
	riding = (
		not run.moose.airborne
		and _contains_x(old_deck, feet.x)
		and absf(feet.y - old_deck.position.y) <= float(tuning.boarding_tolerance)
	)
	if riding:
		if was_riding:
			_ride_offset += feet.x - _last_carried_x
		else:
			_ride_offset = feet.x - deck_x
	var before := deck_x
	var remaining := delta
	while remaining > 0:
		if dock_wait > 0:
			var waited := minf(dock_wait, remaining)
			dock_wait -= waited
			remaining -= waited
		else:
			var target := _dock_x(deck_right)
			var speed := maxf(1, float(tuning.deck_speed))
			var travel_time := absf(target - deck_x) / speed
			var travelled := minf(remaining, travel_time)
			deck_x = move_toward(deck_x, target, speed * travelled)
			remaining -= travelled
			if is_equal_approx(deck_x, target):
				deck_right = not deck_right
				dock_wait = maxf(0.01, float(tuning.dock_seconds))
	deck_delta = deck_x - before
	if riding:
		# Keep an exact local offset; summing small deltas into Vector2 drifts at 144 Hz.
		run.moose.position.x = deck_x + _ride_offset
		_last_carried_x = run.moose.position.x
		carried_distance += absf(deck_delta)
	for actor in _party(run):
		var hero: Node2D = actor.moose
		var state := _player_state(hero)
		var aboard: bool = (
			actor.health > 0
			and not hero.airborne
			and _contains_x(old_deck, hero.position.x)
			and absf(hero.position.y - old_deck.position.y) <= float(tuning.boarding_tolerance)
		)
		if aboard:
			if state.riding:
				state.offset += hero.position.x - float(state.last_x)
			else:
				state.offset = hero.position.x - before
			hero.position.x = deck_x + float(state.offset)
			state.last_x = hero.position.x
		state.riding = aboard
	for enemy in run.enemies:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if (
			_contains_x(old_deck, enemy.position.x)
			and absf(enemy.position.y - old_deck.position.y) <= float(tuning.boarding_tolerance)
		):
			enemy.position.x += deck_delta


func _advance_metro(run, delta: float) -> void:
	wave_previous_x = wave_x
	wave_time -= delta
	if wave_state == "idle" and wave_time <= 0:
		wave_state = "warning"
		wave_time += float(tuning.warning_seconds)
		_feedback(run, Vector2(640, 295), "ПОЕЗД · ПРИСЯДЬ ИЛИ В НИШУ", "warn")
		_notice(run, "Воздушная волна: S/↓ или зелёная ниша. Она заденет и охрану.")
	elif wave_state == "warning" and wave_time <= 0:
		waves += 1
		wave_direction = 1 if waves % 2 else -1
		wave_state = "wave"
		wave_time += float(tuning.wave_seconds)
		wave_x = (
			-float(tuning.wave_width)
			if wave_direction > 0
			else float(tuning.world_width) + float(tuning.wave_width)
		)
		wave_previous_x = wave_x
		_enemy_wave.clear()
	elif wave_state == "wave":
		var progress := clampf(1 - wave_time / maxf(0.01, float(tuning.wave_seconds)), 0, 1)
		var start := -float(tuning.wave_width)
		var finish := float(tuning.world_width) + float(tuning.wave_width)
		wave_x = (
			lerpf(start, finish, progress) if wave_direction > 0 else lerpf(finish, start, progress)
		)
		for enemy in run.enemies:
			if not is_instance_valid(enemy) or enemy.dead or sheltered(enemy.position):
				continue
			var id: int = enemy.get_instance_id()
			if _enemy_wave.has(id) or not wave_rect().intersects(enemy.hurtbox()):
				continue
			_enemy_wave[id] = true
			var source: Vector2 = enemy.position - Vector2(wave_direction * tuning.wave_width, 0)
			if enemy.receive_hit(-500000 - waves, "wind", int(tuning.enemy_damage), source):
				enemy_wave_hits += 1
				enemy.push = (
					wave_direction
					* float(tuning.enemy_push)
					* (float(tuning.boss_push_multiplier) if enemy.boss else 1.0)
				)
		if wave_time <= 0:
			# after_move gets the final swept section before the following idle tick.
			wave_time = 0
	if wave_state == "wave" and wave_time == 0:
		_hit_player_wave(run)
		for actor in _party(run):
			if actor.health > 0:
				_hit_player_wave(actor)
		wave_state = "idle"
		wave_time = float(tuning.interval_seconds)


func _hit_player_wave(run) -> void:
	var player := _player_state(run.moose)
	if wave_state != "wave" or player.wave == waves:
		return
	var feet: Vector2 = run.moose.position
	var crouching: bool = (
		not run.moose.airborne
		and (run.moose.crouch_requested or run.moose.crouch >= float(tuning.crouch_threshold))
	)
	if crouching or sheltered(feet):
		return
	var body := Rect2(
		feet - Vector2(tuning.body_half_width, tuning.body_height),
		Vector2(float(tuning.body_half_width) * 2, tuning.body_height)
	)
	if wave_rect().intersects(body):
		player.wave = waves
		player_wave_hits += 1
		run._hurt_player(
			int(tuning.player_damage), feet - Vector2(wave_direction * tuning.wave_width, 0), true
		)


func _add_object(spec: Dictionary, type: String, health: int) -> void:
	var rect := Rect2(
		float(spec.x),
		float(tuning.floor) - float(spec.height),
		float(spec.width),
		float(spec.height) + float(tuning.foot_offset)
	)
	objects.append(
		{
			"rect": rect,
			"type": type,
			"health": int(spec.get("health", health)),
			"maximum": int(spec.get("health", health)),
			"required": bool(spec.get("required", true)),
			"last_serial": -1,
			"flash": 0.0,
			"debris": 0.0,
			"cleared_age": 0.0
		}
	)


func _hit_object(run, item: Dictionary, damage: int) -> void:
	item.health = maxi(0, int(item.health) - damage)
	item.flash = float(tuning.flash_seconds)
	_feedback(run, item.rect.get_center(), str(damage), "hit")
	if item.health > 0:
		return
	broken += 1
	item.debris = float(tuning.debris_seconds)
	item.cleared_age = 0.0
	_feedback(
		run,
		item.rect.position + Vector2(0, -15),
		"ПРОХОД ОТКРЫТ" if item.type == "vine" else "СЛОМАНО",
		"down"
	)
	if item.type == "support":
		_bridge_falling = true
		for other: Dictionary in objects:
			if other.type == "support" and other.health > 0:
				_bridge_falling = false
		if _bridge_falling:
			_notice(run, "Щит падает в заранее подготовленный пролёт. Дождись настила.")


func _intercept_projectiles(run, delta: float) -> void:
	var survivors: Array[Dictionary] = []
	for projectile: Dictionary in run.effects.projectiles:
		var at: Vector2 = projectile.at
		var sweep := Rect2(at, Vector2.ZERO).expand(at + projectile.velocity * delta).grow(
			float(tuning.projectile_radius)
		)
		var hit: Dictionary = {}
		var nearest := INF
		for item: Dictionary in objects:
			if item.type != "cover" or item.health <= 0 or not sweep.intersects(item.rect):
				continue
			var distance: float = at.distance_squared_to(item.rect.get_center())
			if distance < nearest:
				hit = item
				nearest = distance
		if hit.is_empty():
			survivors.append(projectile)
		else:
			_projectile_serial -= 1
			hit.last_serial = _projectile_serial
			_hit_object(run, hit, int(projectile.damage))
			cover_blocks += 1
	run.effects.projectiles = survivors


func _block_passage(run, previous: Vector2) -> void:
	for item: Dictionary in objects:
		if item.health <= 0:
			continue
		var rect: Rect2 = item.rect
		var feet: Vector2 = run.moose.position
		if feet.y <= rect.position.y or feet.y - float(tuning.body_height) >= rect.end.y:
			continue
		var half := float(tuning.body_half_width)
		if (
			maxf(previous.x, feet.x) + half < rect.position.x
			or minf(previous.x, feet.x) - half > rect.end.x
		):
			continue
		run.moose.position.x = (
			rect.position.x - half if previous.x < rect.get_center().x else rect.end.x + half
		)
		run.speed = 0
		run.moose.horizontal_speed = 0
		run._stride_stop.active = false
		run._direction_was_held = false
		run.moose.finishing_step = false
		run.moose.stop_cycle_distance = 0


func _recover(run) -> void:
	falls += 1
	var player := _player_state(run.moose)
	player.recover_until = elapsed + float(tuning.recovery_cooldown)
	var facing: float = run.moose.facing
	if run.health > 1 and int(tuning.fall_damage) > 0:
		run._hurt_player(mini(int(tuning.fall_damage), run.health - 1), run.moose.position, false)
	run.moose.position = Vector2(player.safe_x, tuning.floor)
	run.floor_y = float(tuning.floor)
	run.lift = 0
	run.vertical_speed = 0
	run.speed = 0
	run._stride_stop.active = false
	run._direction_was_held = false
	run._jump_buffer = 0
	run._preparation_time = -1
	run.moose.finishing_step = false
	run.moose.stop_cycle_distance = 0
	run.moose.preparation = 0
	run.moose.airborne = false
	run.moose.vertical_speed = 0
	run.moose.horizontal_speed = 0
	run.moose.facing = facing
	run.moose.land(0)
	riding = false
	_notice(
		run,
		(
			"Выбрались на безопасный край. Дождись платформы."
			if kind == "port"
			else "Вернулись на крышу. Сначала опусти щит-мост."
		)
	)
	_feedback(run, run.moose.position + Vector2(0, -180), "НА БЕЗОПАСНЫЙ КРАЙ", "block")


func _occupied(run, rect: Rect2) -> bool:
	var feet: Vector2 = run.moose.position
	if _contains_x(rect.grow(float(tuning.body_half_width)), feet.x):
		return true
	for actor in _party(run):
		if (
			actor.health > 0
			and _contains_x(rect.grow(float(tuning.body_half_width)), actor.moose.position.x)
		):
			return true
	for enemy in run.enemies:
		if is_instance_valid(enemy) and not enemy.dead and rect.intersects(enemy.hurtbox()):
			return true
	return false


func _dock_x(right: bool) -> float:
	var inset := float(tuning.deck_width) / 2 - float(tuning.bank_overlap)
	return float(tuning.gap[1]) + inset if right else float(tuning.gap[0]) - inset


func _in_gap(x: float) -> bool:
	return bool(tuning.gap_enabled) and x > float(tuning.gap[0]) and x < float(tuning.gap[1])


func _ground_enemies(run) -> void:
	for enemy in run.enemies:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		var box: Rect2 = enemy.hurtbox()
		var half := box.size.x / 2
		var previous: Vector2 = _enemy_previous.get(enemy.get_instance_id(), enemy.position)
		for item: Dictionary in objects:
			var rect: Rect2 = item.rect
			if item.health <= 0 or box.end.y <= rect.position.y or box.position.y >= rect.end.y:
				continue
			if (
				maxf(previous.x, enemy.position.x) + half < rect.position.x
				or minf(previous.x, enemy.position.x) - half > rect.end.x
			):
				continue
			enemy.position.x = (
				rect.position.x - half if previous.x < rect.get_center().x else rect.end.x + half
			)
			enemy.push = 0
		if kind not in ["port", "roofs"] or not bool(tuning.gap_enabled):
			continue
		if (kind == "roofs" and bridge_down) or enemy.kind == "drone":
			continue
		if not _in_gap(enemy.position.x):
			continue
		if kind == "port" and _contains_x(deck_rect(), enemy.position.x):
			enemy.position.y = deck_rect().position.y
			continue
		enemy.position.x = (
			float(tuning.gap[0]) - half
			if enemy.position.x < _gap_center()
			else float(tuning.gap[1]) + half
		)
		enemy.position.y = float(tuning.floor)
		enemy.push = 0


func _gap_center() -> float:
	return (float(tuning.gap[0]) + float(tuning.gap[1])) / 2


func _contains_x(rect: Rect2, x: float) -> bool:
	return x >= rect.position.x and x <= rect.end.x


func _feedback(run, at: Vector2, caption: String, sound: String) -> void:
	run._feedback(at, caption, Color("e3c07f"), sound)


func _notice(run, caption: String) -> void:
	run._notice = caption
	run._notice_left = float(tuning.notice_seconds)


func _party(run) -> Array:
	var coop = run.get("coop")
	if is_instance_valid(coop) and coop.active and coop.hosting:
		return coop.actors.values()
	return []


func _player_state(hero: Node2D) -> Dictionary:
	var id := hero.get_instance_id()
	if not _player_states.has(id):
		_player_states[id] = {
			"safe_x": float(tuning.get("gap", [0])[0]) - float(tuning.recovery_inset),
			"recover_until": 0.0,
			"wave": -1,
			"riding": false,
			"offset": 0.0,
			"last_x": 0.0
		}
	return _player_states[id]


func network_state() -> Dictionary:
	var state := {}
	for key: String in [
		"elapsed",
		"deck_x",
		"deck_delta",
		"dock_wait",
		"deck_right",
		"riding",
		"falls",
		"carried_distance",
		"wave_state",
		"wave_time",
		"wave_x",
		"wave_previous_x",
		"wave_direction",
		"waves",
		"player_wave_hits",
		"enemy_wave_hits",
		"broken",
		"cover_blocks",
		"bridge_progress",
		"bridge_down"
	]:
		state[key] = get(key)
	var healths := []
	for item: Dictionary in objects:
		healths.append([item.health, item.flash, item.debris])
	state["objects"] = healths
	return state


func apply_network_state(state: Dictionary) -> void:
	for key: String in state:
		if key != "objects":
			set(key, state[key])
	var healths: Array = state.get("objects", [])
	for index in range(mini(healths.size(), objects.size())):
		objects[index].health = int(healths[index][0])
		objects[index].flash = float(healths[index][1])
		objects[index].debris = float(healths[index][2])
	if is_instance_valid(_view):
		_view.queue_redraw()
