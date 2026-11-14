extends RefCounted
## Shared, data-driven moves for the aftermath cast; existing enemy AI stays intact.

var actor: Node2D
var move: Dictionary = {}
var _selected_attack: int = -1
var _travel: float = 0.0


func setup(host: Node2D) -> void:
	actor = host
	_select_move()


func value(key: String, fallback: Variant = 0.0) -> Variant:
	return move.get(key, actor.tuning.get(key, fallback))


func is_ranged() -> bool:
	return value("attack_style", "") == "shot"


func phase_changed() -> void:
	actor._attack_index = 0
	_selected_attack = -1
	actor._events_fired = 0
	actor.guard_down = maxf(actor.guard_down, float(value("phase_open", 1.0)))


func _select_move() -> void:
	var patterns: Array = actor.tuning.get("phase_patterns", [[0]])
	var sequence: Array = patterns[mini(actor.phase - 1, patterns.size() - 1)]
	var index: int = sequence[actor._attack_index % sequence.size()]
	move = actor.tuning.get("moves", [{}])[index]
	_selected_attack = actor._attack_index


func guards_hit(kind_hit: String, frontal: bool) -> bool:
	if not frontal or not _guarding():
		return false
	if kind_hit != "punch":
		actor.guard_down = float(value("guard_break", 1.8))
		actor.feedback.emit(
			actor.position + Vector2(0, -145), "ЗАЩИТА РАСКРЫТА", Color("e2b36e"), "block"
		)
		return false
	actor.flash = 0.12
	actor.feedback.emit(
		actor.position + Vector2(0, -125),
		str(value("guard_label", "СПЕРЕДИ ЗАЩИТА · K / ОБХОД")),
		Color("a9cfcb"),
		"block"
	)
	return true


func _guarding() -> bool:
	if actor.guard_down > 0:
		return false
	var states: Array = value("guard_states", ["approach", "windup"])
	return bool(value("guard_front", false)) and actor.state in states


func advance(delta: float) -> void:
	actor.rig.pace = 0
	actor.rig.pose_style = str(value("pose_style", "light"))
	var covering: bool = bool(value("cover", false)) and actor.state in ["approach", "recovery"]
	actor.rig.cover_blend = move_toward(actor.rig.cover_blend, 1.0 if covering else 0.0, delta * 5)
	match actor.state:
		"approach":
			_approach(delta)
		"windup":
			actor.rig.wind = smoothstep(0, float(value("windup")), actor.elapsed)
			if actor.elapsed >= float(value("windup")):
				actor.state = "attack"
				actor.elapsed = 0
				actor._events_fired = 0
				_travel = 0
		"attack":
			_attack()
		"recovery":
			_recover(delta)


func _approach(delta: float) -> void:
	if _selected_attack != actor._attack_index:
		_select_move()
	var gap: float = actor.target.position.x - actor.position.x
	var distance := absf(gap)
	actor.facing = signf(gap) if distance > 3 else actor.facing
	actor.rig.wind = 0
	actor.rig.strike = 0
	if actor.stun > 0:
		return
	var stop := float(value("engage_range", float(value("reach")) - 18.0))
	if distance > stop:
		actor.rig.pace = float(value("speed"))
		actor.position.x += actor.facing * actor.rig.pace * delta
	elif actor.elapsed >= float(value("approach_delay", 0.4)):
		actor.state = "windup"
		actor.elapsed = 0
		actor.aim = actor.target.position + Vector2(0, -100)
		var vector: Vector2 = actor.aim - actor.rig.weapon_muzzle()
		vector.x *= -actor.facing
		actor.rig.aim_pitch = clampf(wrapf(vector.angle() - PI, -PI, PI), -0.35, 0.35)
		actor.feedback.emit(
			actor.position + Vector2(0, -185 * actor.rig.body_scale),
			str(value("warning", "!")),
			Color("e44a42"),
			"warn"
		)


func _attack() -> void:
	var duration := float(value("active"))
	var count := int(value("beats", 1))
	var interval := duration / count
	var beat := 1.0 if actor.elapsed >= duration else fposmod(actor.elapsed, interval) / interval
	var first: bool = actor.elapsed < interval
	var impact := float(value("impact", 0.42))
	var contact := impact if first else float(value("second_impact", impact))
	var rearm := 0.0 if first else float(value("rearm", 0.18))
	var forward := smoothstep(rearm, contact, beat)
	actor.rig.wind = (1.0 if first else smoothstep(0, rearm, beat)) * (1.0 - forward)
	var returning := smoothstep(float(value("return_at", 0.65)), 1, beat)
	actor.rig.strike = forward * (1.0 - returning)
	if float(value("stuck_time", 0)) > 0:
		actor.rig.strike = forward
	var travel := float(value("motion_distance", 0))
	var progress := smoothstep(0, float(value("motion_end", 0.7)), actor.elapsed / duration)
	var displacement: float = travel * (progress - _travel)
	var gap: float = (actor.target.position.x - actor.position.x) * actor.facing
	if gap >= 0 and absf(actor.target.position.y - actor.position.y) < 45:
		displacement = minf(displacement, maxf(0, gap - 72))
	actor.position.x = clampf(actor.position.x + actor.facing * displacement, 70, 1175)
	_travel = progress
	var next_time := _beat_time(actor._events_fired, interval)
	while actor._events_fired < count and actor.elapsed >= next_time:
		actor._events_fired += 1
		if is_ranged():
			actor.shot.emit(actor.rig.weapon_muzzle(), actor.aim, int(value("damage")))
			actor.shots_fired += 1
			actor.rig.recoil = 1
		else:
			_melee_beat()
		next_time = _beat_time(actor._events_fired, interval)
	if actor.elapsed >= duration:
		actor.state = "recovery"
		actor.elapsed = 0
		actor._attack_index += 1
		actor.attacks_completed += 1
		var label := str(value("recovery_label", ""))
		if not label.is_empty():
			actor.feedback.emit(actor.position + Vector2(0, -155), label, Color("e2b36e"), "")


func _beat_time(index: int, interval: float) -> float:
	var impact := float(value("impact", 0.42))
	return (index + (impact if index == 0 else float(value("second_impact", impact)))) * interval


func _melee_beat() -> void:
	var reach := float(value("reach"))
	var start: float = actor.position.x if actor.facing > 0 else actor.position.x - reach
	var top := float(value("hit_top", -156))
	var height := float(value("hit_height", 146))
	var area := Rect2(Vector2(start, actor.position.y + top), Vector2(reach, height))
	if not area.intersects(actor._player_box()):
		return
	actor.hit_player.emit(int(value("damage")), actor.position, bool(value("high", false)))
	actor.melee_contacts += 1
	var motion: float = float(value("target_motion", 0)) * actor.facing
	if not is_zero_approx(motion):
		if actor.target.get("blocking") == true:
			motion *= float(value("blocked_motion", 0.65))
		actor.forced_player_motion.emit(motion)


func _recover(delta: float) -> void:
	actor.rig.wind = move_toward(actor.rig.wind, 0, delta * 6)
	var stuck := float(value("stuck_time", 0))
	actor.rig.strike = (
		1.0 - smoothstep(0, stuck, actor.elapsed)
		if stuck > 0
		else move_toward(actor.rig.strike, 0, delta * 5)
	)
	if actor.elapsed < float(value("retreat_time", 0)) and actor.stun <= 0:
		actor.rig.pace = -float(value("retreat_speed", 0))
		actor.position.x = clampf(
			actor.position.x + actor.facing * actor.rig.pace * delta, 70, 1175
		)
	if actor.elapsed >= float(value("recovery")) and actor.stun <= 0:
		actor.state = "approach"
		actor.elapsed = 0


func draw_warning() -> void:
	var color := Color("e44a42")
	var center := Vector2(actor.facing * 30, -105)
	if _guarding():
		actor.draw_arc(
			center,
			24,
			-PI / 2 if actor.facing > 0 else PI / 2,
			PI / 2 if actor.facing > 0 else PI * 1.5,
			16,
			Color("a9cfcb"),
			3,
			true
		)
	if actor.state == "windup":
		var charge: float = clampf(actor.elapsed / float(value("windup")), 0, 1)
		actor.draw_arc(
			center, 15 + charge * 10, -PI / 2, -PI / 2 + TAU * charge, 28, color, 2, true
		)
		if is_ranged():
			var aim: Vector2 = actor.to_local(actor.aim)
			actor.draw_line(
				actor.to_local(actor.rig.weapon_muzzle()),
				aim,
				Color(0.9, 0.22, 0.17, 0.4),
				1.5,
				true
			)
			actor.draw_arc(aim, 13, 0, TAU, 24, color, 1.5, true)
		else:
			var y := float(value("warning_y", 5))
			actor.draw_line(
				Vector2(actor.facing * 35, y),
				Vector2(
					actor.facing * (float(value("reach")) + float(value("motion_distance", 0))), y
				),
				Color(0.9, 0.22, 0.17, 0.65),
				3,
				true
			)
	if value("attack_style", "") == "line" and actor.state == "attack":
		actor.draw_line(
			Vector2(0, float(value("warning_y"))),
			Vector2(actor.facing * float(value("reach")), float(value("warning_y"))),
			Color("ffba70"),
			5,
			true
		)
