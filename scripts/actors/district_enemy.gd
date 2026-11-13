extends Node2D

signal hit_player(amount: int, source: Vector2, high: bool)
signal shot(origin: Vector2, aim: Vector2, damage: int)
signal feedback(at: Vector2, label: String, color: Color, sound: String)
signal defeated

const PaintedRig = preload("res://scripts/actors/enemy_rig.gd")
const Contact = preload("res://scripts/core/combat_contact.gd")

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
var _contact := Contact.new()
var _clock: float = 0.0
var _base_y: float = 0.0
var _attack_fired: bool = false


func _ready() -> void:
	maximum_health = int(tuning.health)
	health = maximum_health
	_base_y = position.y
	rig = PaintedRig.new()
	rig.kind = kind
	add_child(rig)


func hurtbox() -> Rect2:
	if kind == "drone":
		return Rect2(position + Vector2(-46, -95), Vector2(92, 52))
	return Rect2(position + Vector2(-31, -170), Vector2(62, 167))


func receive_hit(serial: int, kind_hit: String, damage: int, source: Vector2) -> bool:
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
	stun = 0.24 if kind_hit == "punch" else 0.42
	guard_down = maxf(guard_down, stun)
	push = signf(position.x - source.x) * (90 if kind_hit == "punch" else 155)
	state = "recovery"
	elapsed = 0
	feedback.emit(hurtbox().get_center(), str(damage), Color("e7d3ac"), "hit")
	if health <= 0:
		dead = true
		elapsed = 0
		defeated.emit()
		feedback.emit(hurtbox().get_center(), "ВЫРУБЛЕН", Color("e2b36e"), "down")
	return true


func _physics_process(delta: float) -> void:
	if paused:
		rig.pace = 0
		return
	_clock += delta
	elapsed += delta
	flash = maxf(0, flash - delta)
	guard_down = maxf(0, guard_down - delta)
	stun = maxf(0, stun - delta)
	rig.modulate = Color(1.6, 1.15, 0.7) if flash > 0 else Color.WHITE
	rig.hurt = flash * 5
	rig.shield_down = guard_down > 0 or state == "recovery"
	position.x = clampf(position.x + push * delta, 70, 1175)
	push = move_toward(push, 0, delta * 430)
	if dead:
		rig.pace = 0
		rig.collapse = minf(1, elapsed * 2.8)
		rig.modulate.a = clampf(1 - (elapsed - 0.6), 0, 1)
		queue_redraw()
		return
	if not is_instance_valid(target):
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
		feedback.emit(position + Vector2(0, -180), "!", Color("e44a42"), "warn")


func _attack(delta: float) -> void:
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
		if kind == "drone":
			draw_line(center, to_local(aim), Color(0.9, 0.22, 0.17, 0.3), 1, true)
	if kind == "whip" and state == "attack":
		var points := PackedVector2Array()
		for index in range(17):
			var progress := index / 16.0
			points.append(
				Vector2(
					facing * progress * float(tuning.reach),
					-108 + sin(progress * PI * 2 + elapsed * 25) * 9
				)
			)
		draw_polyline(points, Color("132630"), 5, true)
		draw_polyline(points, Color("e2b36e"), 1, true)
