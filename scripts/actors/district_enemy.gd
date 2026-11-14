extends Node2D

signal hit_player(amount: int, source: Vector2, high: bool)
signal shot(origin: Vector2, aim: Vector2, damage: int)
signal feedback(at: Vector2, label: String, color: Color, sound: String)
signal defeated
signal wounded(at: Vector2, direction: Vector2, lethal: bool, mechanical: bool)

const PaintedRig = preload("res://scripts/actors/enemy_rig.gd")
const Contact = preload("res://scripts/core/combat_contact.gd")
const Ragdoll = preload("res://scripts/actors/skeletal_ragdoll.gd")

@export var art_profile: String = ""

var kind: String = "shield"
var target: Node2D
var tuning: Dictionary
var health: int = 100
var maximum_health: int = 100
var rig: PaintedRig
var state: String = "approach"
var elapsed: float = 0.0
var facing: float = -1.0
var stun: float = 0.0
var guard_down: float = 0.0
var flash: float = 0.0
var push: float = 0.0
var dead: bool = false
var aim := Vector2.ZERO
var paused: bool = false
var hits_received: int = 0
var corpse: Ragdoll
var boss: bool = false
var phase: int = 1
var phase_count: int = 1
var attacks_completed: int = 0
var shots_fired: int = 0
var melee_contacts: int = 0
var _events_fired: int = 0
var _attack_index: int = 0
var _phase_pause: float = 0.0
var _contact := Contact.new()
var _clock: float = 0.0
var _base_y: float = 0.0
var _attack_fired: bool = false


func _ready() -> void:
	maximum_health = int(tuning.health)
	health = maximum_health
	_base_y = position.y
	boss = bool(tuning.get("boss", false))
	phase_count = 3 if kind == "firewall" else (2 if boss else 1)
	rig = PaintedRig.new()
	rig.kind = kind
	rig.art_profile = art_profile
	rig.body_scale = float(tuning.get("scale", 1.0))
	add_child(rig)


func hurtbox() -> Rect2:
	if kind == "drone":
		return Rect2(position + Vector2(-46, -95), Vector2(92, 52))
	var size := float(tuning.get("scale", 1.0))
	return Rect2(position + Vector2(-31 * size, 10 - 180 * size), Vector2(62, 167) * size)


func receive_hit(
	serial: int, kind_hit: String, damage: int, source: Vector2, impact: Dictionary = {}
) -> bool:
	if dead or not _contact.accept(serial):
		return false
	hits_received += 1
	var frontal := (source.x - position.x) * facing > 0
	if kind == "shield" and guard_down <= 0 and state == "approach" and frontal:
		if kind_hit == "punch":
			flash = 0.12
			feedback.emit(
				position + Vector2(0, -120), "ЩИТ · K — пробить", Color("e7d3ac"), "block"
			)
			return true
		guard_down = 1.5
		feedback.emit(position + Vector2(0, -140), "ЩИТ РАСКРЫТ", Color("e2b36e"), "block")
	health = maxi(0, health - damage)
	flash = 0.16
	stun = (0.07 if boss else 0.24) if kind_hit == "punch" else (0.12 if boss else 0.42)
	guard_down = maxf(guard_down, stun)
	push = (
		signf(position.x - source.x) * (90 if kind_hit == "punch" else 155) * (0.2 if boss else 1.0)
	)
	# Boss attacks remain readable and cannot be permanently stun-locked by fast punches.
	if not boss:
		state = "recovery"
		elapsed = 0
	feedback.emit(hurtbox().get_center(), str(damage), Color("e7d3ac"), "hit")
	var at: Vector2 = impact.get("at", hurtbox().get_center())
	var direction: Vector2 = impact.get("direction", Vector2(signf(position.x - source.x), -0.3))
	wounded.emit(at, direction, health <= 0, kind in ["drone", "firewall"])
	_update_phase()
	if health <= 0:
		dead = true
		elapsed = 0
		rig.modulate = Color.WHITE
		var velocity := Vector2(facing * rig.pace, 0)
		rig.ragdoll_active = true
		corpse = Ragdoll.new()
		rig.add_child(corpse)
		corpse.start(
			rig, at, direction.normalized() * (260 if kind_hit != "punch" else 180), velocity
		)
		defeated.emit()
		feedback.emit(hurtbox().get_center(), "ВЫРУБЛЕН", Color("e2b36e"), "down")
	return true


func receive_corpse_hit(serial: int, at: Vector2, direction: Vector2, kind_hit: String) -> bool:
	if not dead or not is_instance_valid(corpse) or not _contact.accept(serial):
		return false
	if not corpse.react(at, direction, kind_hit):
		return false
	wounded.emit(at, direction, false, kind in ["drone", "firewall"])
	return true


func _physics_process(delta: float) -> void:
	if is_instance_valid(corpse):
		corpse.paused = paused
		queue_redraw()
		return
	if paused:
		rig.pace = 0
		return
	_clock += delta
	elapsed += delta
	rig.recoil = move_toward(rig.recoil, 0, delta * 8)
	rig.stomp = move_toward(rig.stomp, 0, delta * 5)
	flash = maxf(0, flash - delta)
	guard_down = maxf(0, guard_down - delta)
	stun = maxf(0, stun - delta)
	rig.modulate = Color(1.6, 1.15, 0.7) if flash > 0 else Color.WHITE
	rig.hurt = flash * 5
	rig.shield_down = guard_down > 0 or state == "recovery"
	position.x = clampf(position.x + push * delta, 70, 1175)
	push = move_toward(push, 0, delta * 430)
	if not is_instance_valid(target):
		return
	if _phase_pause > 0:
		_phase_pause = maxf(0, _phase_pause - delta)
		rig.pace = 0
		rig.wind = 0
		rig.strike = 0
		return
	if kind == "drone":
		position.y = _base_y + sin(_clock * 2.4) * 12
	if state == "approach":
		_approach(delta)
	elif state == "windup":
		rig.pace = 0
		rig.wind = smoothstep(0, float(tuning.windup), elapsed)
		if elapsed >= float(tuning.windup):
			state = "attack"
			elapsed = 0
			_attack_fired = false
			_events_fired = 0
	elif state == "attack":
		_attack(delta)
	elif state == "recovery":
		rig.wind = move_toward(rig.wind, 0, delta * 6)
		rig.strike = move_toward(rig.strike, 0, delta * 5)
		rig.pace = 0
		if elapsed >= float(tuning.recovery) and stun <= 0:
			state = "approach"
			elapsed = 0
	rig.facing = facing
	if kind != "drone" and absf(target.position.y - position.y) < 45:
		var gap := target.position.x - position.x
		if absf(gap) < 72:
			position.x = target.position.x - (signf(gap) if absf(gap) > 0.1 else facing) * 72
	queue_redraw()


func _approach(delta: float) -> void:
	var distance := absf(target.position.x - position.x)
	facing = signf(target.position.x - position.x) if distance > 3 else facing
	var stop_at := float(tuning.reach) - 18
	rig.wind = 0
	rig.strike = 0
	rig.pace = 0
	if distance > stop_at:
		rig.pace = float(tuning.speed)
		position.x += facing * rig.pace * delta
	elif elapsed > 0.4:
		state = "windup"
		elapsed = 0
		aim = target.position + Vector2(0, -100)
		var warning := "!"
		if kind in ["fox", "lynx"]:
			warning = "ПРИЦЕЛ"
		elif kind == "firewall":
			warning = "ИМПУЛЬС · ПРЫГАЙ" if _uses_pulse() else "ЗАЛП"
		elif kind == "foreman" and _uses_pulse():
			warning = "ТОПОТ · ПРЫГАЙ"
		feedback.emit(position + Vector2(0, -180), warning, Color("e44a42"), "warn")


func _attack(delta: float) -> void:
	if kind not in ["shield", "whip", "drone"]:
		_new_attack(delta)
		return
	rig.wind = 0
	rig.strike = sin(minf(elapsed / float(tuning.active), 1) * PI)
	if kind == "shield":
		position.x = clampf(position.x + facing * delta * 160, 70, 1175)
	if not _attack_fired:
		_attack_fired = true
		if kind == "drone":
			shot.emit(position + Vector2(facing * 35, -70), aim, int(tuning.damage))
		else:
			# A crouch slips under the high cable; a jump must clear the body bash.
			var height: float = 128 if kind == "shield" else 40
			var top := -150.0 if kind == "shield" else -128.0
			var start := position.x if facing > 0 else position.x - float(tuning.reach)
			var area := Rect2(Vector2(start, position.y + top), Vector2(tuning.reach, height))
			if area.intersects(_player_box()):
				hit_player.emit(int(tuning.damage), position, kind == "whip")
	if elapsed >= float(tuning.active):
		state = "recovery"
		elapsed = 0
		attacks_completed += 1


func is_ranged() -> bool:
	return kind in ["drone", "fox", "lynx", "firewall"]


func _update_phase() -> void:
	if not boss or health <= 0:
		return
	var next := 1
	if kind == "firewall":
		next = (
			3
			if health <= maximum_health / 3.0
			else (2 if health <= maximum_health * 2.0 / 3.0 else 1)
		)
	elif health <= maximum_health / 2.0:
		next = 2
	if next <= phase:
		return
	phase = next
	state = "recovery"
	elapsed = 0
	_phase_pause = 0.8
	feedback.emit(hurtbox().get_center(), "ФАЗА %d" % phase, Color("ffba70"), "warn")


func _uses_pulse() -> bool:
	return (
		(kind == "firewall" and _attack_index % 2 == 1)
		or (kind == "foreman" and phase == 2 and _attack_index % 2 == 1)
	)


func _new_attack(_delta: float) -> void:
	var duration := float(tuning.active)
	var count := 1
	if kind == "hare" or (kind == "foreman" and phase == 2 and not _uses_pulse()):
		count = 2
	elif kind == "lynx":
		count = 3
	elif kind == "firewall" and not _uses_pulse():
		count = phase + 1
	# Every beat is emitted once even if a slow frame crosses several event times.
	var interval := duration / maxf(count, 1)
	var melee := not is_ranged() and not _uses_pulse()
	var impact := float(tuning.impact) if melee else 0.0
	var next_time := _beat_time(_events_fired, interval, melee)
	rig.wind = 0
	rig.strike = sin(fposmod(elapsed, interval) / interval * PI)
	if melee:
		var beat := 1.0 if elapsed >= duration else fposmod(elapsed, interval) / interval
		var first := elapsed < interval
		var rearm := 0.0 if first else float(tuning.rearm)
		var contact := impact if first else float(tuning.second_impact)
		var forward := smoothstep(rearm, contact, beat)
		rig.wind = (1.0 if first else smoothstep(0, rearm, beat)) * (1.0 - forward)
		rig.strike = (forward * (1.0 - smoothstep(float(tuning.return_at), 1, beat)))
	while _events_fired < count and elapsed >= next_time:
		_events_fired += 1
		if is_ranged() and not _uses_pulse():
			var muzzle: Vector2 = rig.weapon_muzzle()
			shot.emit(muzzle, aim, int(tuning.damage))
			shots_fired += 1
			rig.recoil = 1.0
		elif _uses_pulse():
			_ground_pulse()
		else:
			_melee_beat()
		next_time = _beat_time(_events_fired, interval, melee)
	if elapsed >= duration:
		state = "recovery"
		elapsed = 0
		_attack_index += 1
		attacks_completed += 1
		if kind in ["fox", "lynx"]:
			feedback.emit(position + Vector2(0, -155), "ПЕРЕЗАРЯДКА", Color("e2b36e"), "")


func _beat_time(index: int, interval: float, melee: bool) -> float:
	var contact := 0.0
	if melee:
		contact = float(tuning.impact if index == 0 else tuning.second_impact)
	return (index + contact) * interval


func _melee_beat() -> void:
	var reach := float(tuning.reach)
	var start := position.x if facing > 0 else position.x - reach
	var area := Rect2(Vector2(start, position.y - 156), Vector2(reach, 146))
	if area.intersects(_player_box()):
		hit_player.emit(int(tuning.damage), position, false)
		melee_contacts += 1


func _ground_pulse() -> void:
	rig.stomp = 1.0
	feedback.emit(position + Vector2(0, -15), "УДАРНАЯ ВОЛНА", Color("ff704c"), "hit")
	var near_ground := target.position.y >= position.y - 42
	if near_ground and absf(target.position.x - position.x) <= float(tuning.reach):
		hit_player.emit(int(tuning.damage), position, false)
		melee_contacts += 1


func _player_box() -> Rect2:
	var low: bool = target.get("crouch") > 0.5
	return Rect2(
		target.position + Vector2(-22, -78 if low else -150), Vector2(44, 75 if low else 147)
	)


func _draw() -> void:
	if dead:
		return
	var box := hurtbox()
	var bar := Vector2(-28, box.position.y - position.y - 14)
	if health < maximum_health or state == "windup":
		draw_rect(Rect2(bar, Vector2(56, 3)), Color(0.03, 0.08, 0.1, 0.8))
		draw_rect(Rect2(bar, Vector2(56.0 * health / maximum_health, 3)), Color("e2b36e"))
	if state == "windup":
		var center := Vector2(facing * 30, -105 if kind != "drone" else -70)
		var charge := elapsed / float(tuning.windup)
		draw_arc(
			center, 15 + charge * 10, -PI / 2, -PI / 2 + TAU * charge, 28, Color("e44a42"), 2, true
		)
		if is_ranged() and not _uses_pulse():
			draw_line(center, to_local(aim), Color(0.9, 0.22, 0.17, 0.3), 1, true)
		if _uses_pulse():
			draw_line(
				Vector2(-float(tuning.reach), 5),
				Vector2(float(tuning.reach), 5),
				Color(1, 0.3, 0.12, 0.7),
				4
			)
	if _uses_pulse() and state == "attack":
		var radius := float(tuning.reach) * minf(elapsed / float(tuning.active), 1)
		draw_arc(Vector2(0, 8), radius, PI, TAU, 32, Color(1, 0.4, 0.2, 0.8), 3, true)
	if kind == "whip" and state == "attack":
		var points := PackedVector2Array()
		var grip := to_local(rig.bones.near_hand.global_position)
		var end := Vector2(facing * float(tuning.reach), -108)
		for index in range(17):
			var progress := index / 16.0
			points.append(
				(
					grip.lerp(end, progress)
					+ Vector2(0, sin(progress * PI) * sin(progress * PI * 2 + elapsed * 25) * 9)
				)
			)
		draw_polyline(points, Color("132630"), 5, true)
		draw_polyline(points, Color("e2b36e"), 1, true)
