extends "res://scripts/gyms/rig_lab.gd"
## First playable route. Keeps the accepted rig gym intact for animation reviews.

const Enemy = preload("res://scripts/actors/district_enemy.gd")
const Effects = preload("res://scripts/world/district_fx.gd")
const Sound = preload("res://scripts/core/combat_audio.gd")
const Contact = preload("res://scripts/core/combat_contact.gd")
const RELAY_TEXTURE = preload("res://assets/enemies/shield/weapon.png")
const FrontEnd = preload("res://scripts/ui/front_end.gd")
const Scores = preload("res://scripts/core/run_scores.gd")
const NightPower = preload("res://scripts/core/night_power.gd")
const NightEffects = preload("res://scripts/world/night_fx.gd")
const BloodEffects = preload("res://scripts/world/blood_fx.gd")
const Ragdoll = preload("res://scripts/actors/skeletal_ragdoll.gd")
const FpsCounter = preload("res://scripts/ui/fps_counter.gd")
const TouchControls = preload("res://scripts/ui/touch_controls.gd")

var rooms: Array
var encounter: Dictionary
var room_index: int = 0
var cleared: Array[bool] = [false, false, false]
var enemies: Array[Enemy] = []
var health: int = 100
var invincible: float = 0.0
var kills: int = 0
var deaths: int = 0
var hits_landed: int = 0
var player_hits: int = 0
var run_state: String = "playing"
var relay: Vector2
var ledges: Array[Rect2] = []
var scenery: Node2D
var effects: Effects
var audio: Sound
var objective: Label
var message: Label
var health_label: Label
var outcome: Label
var health_bar: ColorRect
var front: FrontEnd
var scores: Scores
var night := NightPower.new()
var night_fx: NightEffects
var night_label: Label
var night_bar: ColorRect
var night_damage: int = 0
var burst_hits: int = 0
var world_night: bool = false
var time_switches: int = 0
var blood: BloodEffects
var terrain: Node2D
var player_corpse: Ragdoll
var blocked_hits: int = 0
var fps_counter: FpsCounter
var touch_controls: TouchControls
var controls_hint: Label
var elapsed_run: float = 0.0
var _finish_shown: bool = false
var _tip_serial: int = -1
var _previous_tip := Vector2.ZERO
var _shake: float = 0.0
var _transition: float = 0.0
var _notice: String = "Двор закрыли? Сейчас откроем."
var _notice_left: float = 3.0


func _ready() -> void:
	rooms = JSON.parse_string(FileAccess.get_file_as_string("res://data/district_rooms.json"))
	encounter = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	super._ready()
	movement_bounds = Vector2(28, 1252)
	for pair: Array in [
		["interact", KEY_E],
		["restart", KEY_R],
		["pause_run", KEY_ESCAPE],
		["mute", KEY_M],
		["super_strike", KEY_O],
		["ultimate", KEY_Q]
	]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		var event := InputEventKey.new()
		event.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], event)
	# The gym UI is replaced with a readable game HUD.
	for child: Node in get_children():
		if child is CanvasLayer:
			for control: Node in child.get_children():
				control.hide()
	effects = Effects.new()
	effects.z_index = 30
	add_child(effects)
	blood = BloodEffects.new()
	blood.z_index = 24
	add_child(blood)
	audio = Sound.new()
	add_child(audio)
	night_fx = NightEffects.new()
	night_fx.hero = moose
	add_child(night_fx)
	_build_hud()
	Metrics.completed = false
	_load_room(0, 170)
	scores = Scores.new()
	add_child(scores)
	scores.changed.connect(_records_changed)
	scores.submitted.connect(_record_submitted)
	front = FrontEnd.new()
	front.muted = audio.muted
	fps_counter = FpsCounter.new()
	add_child(fps_counter)
	front.fps_enabled = fps_counter.enabled
	add_child(front)
	front.start_requested.connect(_start_new_run)
	front.resume_requested.connect(_resume_run)
	front.records_requested.connect(scores.refresh)
	front.submit_requested.connect(_submit_record)
	front.mute_requested.connect(func() -> void: audio.set_muted(front.muted))
	front.fps_requested.connect(fps_counter.set_enabled)
	touch_controls = TouchControls.new()
	add_child(touch_controls)
	run_state = "menu"
	for enemy: Enemy in enemies:
		enemy.paused = true
	scores.refresh()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.065, 0.08, 0.8)
	backdrop.size = Vector2(1280, 107)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(backdrop)
	health_label = _label(layer, Vector2(30, 17), 20, "ЛОСЬ / РАЙОН ЗАКРЫТ")
	health_bar = _bar(layer, Vector2(30, 52), Vector2(220, 8), Color("e2b36e"))
	night_label = _label(layer, Vector2(30, 67), 13, "Q · УЛЬТА ГОТОВА")
	night_label.add_theme_color_override("font_color", Color("ff796e"))
	night_bar = _bar(layer, Vector2(30, 92), Vector2(220, 5), Color("f04b53"))
	objective = _label(layer, Vector2(300, 16), 23, "")
	message = _label(layer, Vector2(300, 53), 17, "")
	message.size = Vector2(940, 50)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_hint = _label(
		layer,
		Vector2(30, 668),
		14,
		(
			"A/D — ход   Shift — бег   W/↑/Пробел — прыжок   S/↓ — присед"
			+ "   J/K — бой   L — блок   E — реле   T — день/ночь   Q — ульта   O — импульс   Esc — меню"
		)
	)
	outcome = _label(layer, Vector2(290, 255), 30, "")
	outcome.add_theme_color_override("font_shadow_color", Color("132630"))
	outcome.add_theme_constant_override("shadow_offset_x", 3)
	outcome.add_theme_constant_override("shadow_offset_y", 3)


func _bar(parent: Node, at: Vector2, size: Vector2, color: Color) -> ColorRect:
	var track := ColorRect.new()
	track.position = at
	track.size = size
	track.color = Color("263b40")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(track)
	var fill := ColorRect.new()
	fill.size = size
	fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	return fill


func _label(parent: Node, at: Vector2, size: int, caption: String) -> Label:
	var label := Label.new()
	label.position = at
	label.text = caption
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_font_override("font", preload("res://assets/fonts/Manrope-Semibold.tres"))
	label.add_theme_color_override("font_color", Color("e7d3ac"))
	parent.add_child(label)
	return label


func _load_room(index: int, spawn_x: float) -> void:
	if is_instance_valid(player_corpse):
		player_corpse.queue_free()
		player_corpse = null
	moose.ragdoll_active = false
	for bone: Bone2D in moose.bones.values():
		bone.transform = bone.rest
	moose.visible = true
	moose.skeleton.modulate = Color.WHITE
	moose.blocking = false
	moose.guard_blend = 0
	room_index = index
	for enemy: Enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	if is_instance_valid(scenery):
		scenery.queue_free()
	scenery = Node2D.new()
	add_child(scenery)
	ledges.clear()
	var room: Dictionary = rooms[index]
	for child: Node in get_children():
		if child is TextureRect and child != dark:
			child.texture = load("res://assets/environment/%s.png" % room.art)
	dark.material = null
	if index == 0:
		dark.texture = load("res://assets/environment/courtyard-quarantine-clean.png")
	else:
		dark.texture = load("res://assets/environment/%s.png" % room.art)
		var material := ShaderMaterial.new()
		material.shader = load("res://assets/shaders/quarantine_world.gdshader")
		dark.material = material
	floor_y = float(room.floor)
	moose.position = Vector2(spawn_x, floor_y)
	moose.land(0)
	lift = 0
	speed = 0
	vertical_speed = 0
	_stride_stop.active = false
	moose.combat.interrupt()
	moose.horizontal_speed = 0
	moose.facing = 1 if spawn_x < 640 else -1
	moose.airborne = false
	_jump_buffer = 0
	_preparation_time = -1
	relay = Vector2(room.relay[0], room.relay[1])
	for item: Array in room.ledges:
		var rect := Rect2(item[0], item[1], item[2], item[3])
		ledges.append(rect)
		var ledge := Sprite2D.new()
		ledge.texture = load("res://assets/environment/service-ledge.png")
		ledge.centered = false
		ledge.position = rect.position
		var art_size := Vector2(rect.size.x, 36)
		ledge.scale = art_size / ledge.texture.get_size()
		ledge.position.y -= 4
		ledge.z_index = -1
		scenery.add_child(ledge)
	_build_physics_surfaces(float(room.floor))
	if not cleared[index]:
		for entry: Array in room.enemies:
			_spawn_enemy(entry)
	effects.projectiles.clear()
	effects.gate = Vector2(1210, float(room.floor))
	effects.floor_y = float(room.floor)
	effects.seal = 0 if cleared[index] else 1
	quarantine = not cleared[index]
	_transition = 0.7
	_notice = str(room.hint)
	_notice_left = 6
	Metrics.record("entered_room_" + str(index + 1))
	_sync_metrics()


func _spawn_enemy(entry: Array) -> void:
	var enemy := Enemy.new()
	enemy.kind = str(entry[0])
	enemy.position = Vector2(entry[1], entry[2])
	enemy.target = moose
	enemy.tuning = encounter[enemy.kind]
	enemy.hit_player.connect(_hurt_player)
	enemy.shot.connect(_projectile)
	enemy.feedback.connect(_feedback)
	enemy.defeated.connect(_enemy_down)
	enemy.wounded.connect(blood.spill)
	add_child(enemy)
	enemies.append(enemy)


func _build_physics_surfaces(base_floor: float) -> void:
	if is_instance_valid(terrain):
		remove_child(terrain)
		terrain.queue_free()
	terrain = Node2D.new()
	add_child(terrain)
	blood.clear()
	blood.surfaces = [Rect2(-200, base_floor + 10, 1680, 24)]
	for ledge: Rect2 in ledges:
		blood.surfaces.append(Rect2(ledge.position + Vector2(0, 10), ledge.size))
	# Sort high platforms first for swept droplet impacts.
	blood.surfaces.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y < b.position.y)
	for surface: Rect2 in blood.surfaces:
		var body := StaticBody2D.new()
		body.collision_layer = Ragdoll.TERRAIN_LAYER
		body.collision_mask = Ragdoll.CORPSE_LAYER
		body.position = surface.position + Vector2(surface.size.x / 2, 12)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(surface.size.x, 24)
		shape.shape = rectangle
		shape.one_way_collision = surface.position.y < base_floor
		body.add_child(shape)
		terrain.add_child(body)


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(front) and front.is_open():
		if event.is_action_pressed("pause_run"):
			if front.page == "home" and front.can_resume:
				_resume_run()
			else:
				front.show_home(front.can_resume)
		return
	if event.is_action_pressed("restart"):
		_restart()
	elif event.is_action_pressed("pause_run") and run_state in ["playing", "lost"]:
		var resumable := run_state == "playing"
		run_state = "paused"
		front.show_home(resumable)
		for enemy: Enemy in enemies:
			enemy.paused = true
	elif event.is_action_pressed("mute"):
		audio.set_muted(not audio.muted)
		front.muted = audio.muted
	elif run_state == "playing":
		if event.is_action_pressed("ultimate"):
			_activate_ultimate()
		if night.burst_time < 0:
			super._unhandled_input(event)
		if event.is_action_pressed("interact"):
			_interact()
		if event.is_action_pressed("super_strike") and not moose.blocking and night.try_burst():
			moose.combat.interrupt()
			Metrics.record("night_impulse_windup")


func _physics_process(delta: float) -> void:
	if is_instance_valid(touch_controls):
		touch_controls.set_context("menu" if front.is_open() else run_state)
		controls_hint.visible = not touch_controls.enabled
	var simulation_paused := run_state in ["menu", "paused", "won"]
	blood.paused = simulation_paused
	if is_instance_valid(player_corpse):
		player_corpse.paused = simulation_paused
	if run_state != "playing":
		moose.horizontal_speed = 0
		moose.travel = 0
		if Engine.get_physics_frames() % 6 == 0:
			_sync_metrics()
		return
	elapsed_run += delta
	if night.advance(delta):
		_release_impulse()
	move_power = float(night.tuning.move_multiplier) if night.active() else 1.0
	combat_rate = float(night.tuning.attack_rate) if night.active() else 1.0
	moose.power_pose = night.pose()
	invincible = maxf(0, invincible - delta)
	_transition = maxf(0, _transition - delta)
	# One-way service ledges: choose the first top beneath the feet, then let the
	# proven jump controller integrate and land relative to that surface.
	var surface := float(rooms[room_index].floor)
	for ledge: Rect2 in ledges:
		if moose.position.x >= ledge.position.x and moose.position.x <= ledge.end.x:
			if moose.position.y <= ledge.position.y + 1.0:
				surface = minf(surface, ledge.position.y)
	floor_y = surface
	lift = minf(0, moose.position.y - surface)
	var before_x := moose.position.x
	super._physics_process(delta)
	for enemy: Enemy in enemies:
		if (
			not enemy.dead
			and enemy.kind != "drone"
			and absf(moose.position.y - enemy.position.y) < 45
		):
			var corrected := Contact.separate(before_x, moose.position.x, enemy.position.x)
			if not is_equal_approx(corrected, moose.position.x):
				moose.position.x = corrected
				speed = 0
				moose.horizontal_speed = 0
				_stride_stop.active = false
	_resolve_attacks()
	_move_projectiles(delta)
	if _transition <= 0:
		if moose.position.x > 1230 and cleared[room_index] and room_index < 2:
			_load_room(room_index + 1, 110)
		elif moose.position.x < 45 and room_index > 0:
			_load_room(room_index - 1, 1160)
	if moose.position.x > 1190 and not cleared[room_index]:
		moose.position.x = 1190
		speed = minf(speed, 0)


func _world_pressed() -> void:
	world_night = not world_night
	time_switches += 1
	_notice = ("НОЧЬ" if world_night else "ДЕНЬ") + " · T — сменить время · Q — ульта Лося"
	_notice_left = 2
	Metrics.record("world_night" if world_night else "world_day")


func _activate_ultimate() -> void:
	if night.activate():
		_feedback(moose.position + Vector2(0, -220), "БАГРОВАЯ ЯРОСТЬ", Color("ff685e"), "down")
		_shake = 5
		_notice = "Ульта: урон ×1,8 · O — рогатый импульс!"
		_notice_left = 3
		Metrics.record("night_activated")
	else:
		_notice = (
			"Ульта уже активна."
			if night.active()
			else "Заряд ульты: %d%%. Попадай и побеждай." % night.charge
		)
		_notice_left = 2


func _release_impulse() -> void:
	var at := moose.position + Vector2(0, -95)
	var radius := float(night.tuning.burst_radius)
	night_fx.impulse(at)
	_feedback(at + Vector2(0, -80), "РОГАТЫЙ ИМПУЛЬС", Color("ff796e"), "down")
	_shake = 9
	for enemy: Enemy in enemies:
		var box := enemy.hurtbox()
		var nearest := Vector2(
			clampf(at.x, box.position.x, box.end.x), clampf(at.y, box.position.y, box.end.y)
		)
		if not enemy.dead and at.distance_to(nearest) <= radius:
			if enemy.receive_hit(
				-1000 - night.bursts,
				"super",
				int(night.tuning.burst_damage),
				moose.position,
				{
					"at": nearest,
					"direction": (box.get_center() - at).normalized() + Vector2(0, -0.35)
				}
			):
				burst_hits += 1
				enemy.push *= 1.6
	effects.projectiles = effects.projectiles.filter(
		func(item: Dictionary) -> bool: return at.distance_to(item.at) > radius
	)
	Metrics.record("night_impulse")


func _resolve_attacks() -> void:
	var attack = moose.combat
	if not attack.is_active():
		_tip_serial = -1
		return
	var bone: Bone2D = moose.bones[attack.side + ("_foot" if attack.kind == "kick" else "_hand")]
	var tip := bone.to_global(Vector2(0, 15))
	if _tip_serial != attack.serial:
		_previous_tip = tip
		_tip_serial = attack.serial
	var area := Rect2(_previous_tip, Vector2.ZERO).expand(tip).grow(
		24 if attack.kind == "kick" else 19
	)
	var amount := Contact.damage(attack.kind, attack.kick_step, attack.in_air, encounter)
	if night.active():
		amount = roundi(amount * float(night.tuning.damage_multiplier))
	for enemy: Enemy in enemies:
		if not enemy.dead and area.intersects(enemy.hurtbox()):
			var before := enemy.health
			var box := enemy.hurtbox()
			var at := Vector2(
				clampf(tip.x, box.position.x, box.end.x), clampf(tip.y, box.position.y, box.end.y)
			)
			var motion_axis := (tip - _previous_tip).normalized()
			var direction := (Vector2(moose.facing, -0.3) + motion_axis * 0.7).normalized()
			if enemy.receive_hit(
				attack.serial,
				attack.kind,
				amount,
				moose.position,
				{"at": at, "direction": direction}
			):
				hits_landed += 1
				_shake = 4 if attack.kind == "kick" else 2
				if enemy.health < before:
					night.gain(float(night.tuning.hit_charge))
					if night.active():
						night_damage += before - enemy.health
	_previous_tip = tip


func _hurt_player(
	amount: int, source: Vector2, high: bool = false, contact: Vector2 = Vector2.INF
) -> void:
	if invincible > 0 or run_state != "playing":
		return
	if night.active():
		amount = maxi(1, roundi(amount * float(night.tuning.incoming_multiplier)))
	var guarded := moose.blocking and not moose.ragdoll_active
	if guarded:
		amount = maxi(1, ceili(amount * float(guard_tuning.damage_multiplier)))
		blocked_hits += 1
	health = maxi(0, health - amount)
	player_hits += 1
	invincible = float(encounter.invulnerability)
	var inherited_velocity := Vector2(speed, vertical_speed)
	speed = signf(moose.position.x - source.x) * (float(guard_tuning.knockback) if guarded else 190)
	moose.combat.interrupt()
	_feedback(
		moose.position + Vector2(0, -145),
		("БЛОК −" if guarded else "−") + str(amount),
		Color("e2b36e") if guarded else Color("e44a42"),
		"block" if guarded else "hurt"
	)
	_shake = 3 if guarded else 8
	var at := (
		contact if contact != Vector2.INF else moose.position + Vector2(0, -133 if high else -95)
	)
	var direction := Vector2(signf(moose.position.x - source.x), -0.35)
	if not guarded or health <= 0:
		blood.spill(at, direction, health <= 0)
	Metrics.record("player_hit")
	if health <= 0:
		night.cancel()
		deaths += 1
		run_state = "lost"
		moose.ragdoll_active = true
		moose.blocking = false
		player_corpse = Ragdoll.new()
		moose.add_child(player_corpse)
		player_corpse.start(moose, at, direction * 230, inherited_velocity)
		for enemy: Enemy in enemies:
			enemy.paused = not enemy.dead
		Metrics.record("defeated")


func _projectile(origin: Vector2, aim: Vector2, amount: int) -> void:
	effects.projectiles.append(
		{"at": origin, "velocity": origin.direction_to(aim) * 290, "damage": amount, "age": 0.0}
	)
	audio.play("swing")


func _move_projectiles(delta: float) -> void:
	var low := moose.crouch > 0.5
	var box := Rect2(
		moose.position + Vector2(-19, -77 if low else -149), Vector2(38, 74 if low else 146)
	)
	for item: Dictionary in effects.projectiles:
		var before: Vector2 = item.at
		item.age += delta
		item.at += item.velocity * delta
		var swept := Rect2(before, Vector2.ZERO).expand(item.at).grow(5)
		if swept.intersects(box):
			_hurt_player(
				int(item.damage),
				before,
				false,
				Vector2(
					clampf(item.at.x, box.position.x, box.end.x),
					clampf(item.at.y, box.position.y, box.end.y)
				)
			)
			item.age = 10
	effects.projectiles = effects.projectiles.filter(
		func(item: Dictionary) -> bool: return item.age < 4
	)


func _enemy_down() -> void:
	kills += 1
	night.gain(float(night.tuning.kill_charge))
	Metrics.record("enemy_down")
	if _remaining() == 0:
		_notice = "Порядок навели. Теперь к реле справа — E."
		_notice_left = 5


func _remaining() -> int:
	var count := 0
	for enemy: Enemy in enemies:
		if not enemy.dead:
			count += 1
	return count


func _interact() -> void:
	if cleared[room_index] or moose.position.distance_to(relay) > 110:
		return
	if _remaining() > 0:
		_notice = "Реле держит охрана. Сначала разберись с ней."
		_notice_left = 3
		return
	cleared[room_index] = true
	quarantine = false
	health = mini(int(encounter.player_health), health + 35)
	_feedback(relay, "КАРАНТИН СНЯТ", Color("e2b36e"), "relay")
	_notice = "Вот. Другое дело. Проход справа открыт →"
	_notice_left = 5
	Metrics.record("relay_disabled_" + str(room_index + 1))
	if room_index == 2:
		night.cancel()
		run_state = "won"
		Metrics.completed = true
		Metrics.record("route_completed")


func _restart() -> void:
	if run_state == "won":
		_start_new_run()
		return
	health = int(encounter.player_health)
	invincible = 1.5
	night.reset()
	run_state = "playing"
	_load_room(room_index, 170)
	Metrics.record("checkpoint_restart")


func _start_new_run() -> void:
	blocked_hits = 0
	world_night = false
	time_switches = 0
	night.reset()
	night_damage = 0
	burst_hits = 0
	cleared = [false, false, false]
	kills = 0
	deaths = 0
	hits_landed = 0
	player_hits = 0
	health = int(encounter.player_health)
	elapsed_run = 0
	_finish_shown = false
	Metrics.completed = false
	run_state = "playing"
	front.hide_menu()
	_load_room(0, 170)
	scores.begin()


func _resume_run() -> void:
	run_state = "playing"
	front.hide_menu()
	for enemy: Enemy in enemies:
		enemy.paused = false


func _run_stats() -> Dictionary:
	return {
		"seconds": snappedf(elapsed_run, 0.01),
		"health": health,
		"deaths": deaths,
		"kills": kills,
		"relays": cleared.count(true)
	}


func _submit_record(name_text: String) -> void:
	scores.finish(name_text, _run_stats())


func _records_changed() -> void:
	if not is_instance_valid(front):
		return
	front.rows = scores.rows
	front.online = scores.online
	if front.page == "records":
		front.show_records(false)


func _record_submitted(shared: bool) -> void:
	front.result_saved(shared)


func _attack_started(kind: String, side: String, in_air: bool, low: bool) -> void:
	super._attack_started(kind, side, in_air, low)
	if is_instance_valid(audio):
		audio.play("swing")


func _feedback(at: Vector2, caption: String, color: Color, sound: String) -> void:
	effects.burst(at, caption, color)
	audio.play(sound)


func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(night_fx):
		night_fx.update(delta, world_night, night.active())
		# Relay state still affects the warning wash, independently of time/power.
		var warning_light := blend * lerpf(0.25, 1.0, night_fx.world_strength)
		dark.modulate.a = warning_light
		moose.modulate = Color.WHITE.lerp(Color(0.82, 0.74, 0.78), warning_light)
		moose.power_pose = night.pose()
		moose.power_scale = lerpf(1.0, float(night.tuning.size_multiplier), night_fx.strength)
		moose.modulate = moose.modulate.lerp(Color(1.2, 0.68, 0.62), night_fx.strength * 0.35)
	night_bar.size.x = (
		220
		* (night.remaining / float(night.tuning.duration) if night.active() else night.charge / 100)
	)
	if night.active():
		night_label.text = (
			"УЛЬТА %.1fс · O %s"
			% [night.remaining, "ГОТОВ" if night.cooldown <= 0 else "%.1fс" % night.cooldown]
		)
	else:
		night_label.text = (
			"Q · УЛЬТА ГОТОВА" if night.charge >= 100 else "Q · УЛЬТА %d%%" % night.charge
		)
	_notice_left = maxf(0, _notice_left - delta)
	_shake = move_toward(_shake, 0, delta * 30)
	camera.offset = Vector2(sin(clock * 123), cos(clock * 97)) * _shake
	moose.modulate.a = 0.5 if invincible > 0 and health > 0 and fmod(clock, 0.12) < 0.06 else 1.0
	effects.seal = move_toward(effects.seal, 0.0 if cleared[room_index] else 1.0, delta * 1.8)
	health_bar.size.x = health * 2.2
	health_label.text = "ЛОСЬ  /  " + str(health) + " HP"
	objective.text = (
		str(rooms[room_index].title) + "    ·    УЗЛЫ " + str(cleared.count(true)) + "/3"
	)
	if _notice_left > 0:
		message.text = _notice
	elif cleared[room_index]:
		message.text = "Карантин снят. Иди вправо →" if room_index < 2 else "Первый маршрут открыт."
	elif _remaining() == 0:
		message.text = (
			"E — отключить реле"
			if moose.position.distance_to(relay) < 110
			else "Охрана снята. Доберись до реле справа →"
		)
	else:
		message.text = (
			"Охрана: "
			+ str(_remaining())
			+ "   ·   J/K — бой · L — блок   ·   "
			+ str(rooms[room_index].hint)
		)
	if run_state == "lost":
		outcome.text = "РОГА ЦЕЛЫ. САМ — НЕ ОЧЕНЬ.\n\nR — с контрольной точки"
	elif run_state == "won":
		outcome.text = (
			"ПЕРВЫЙ УЗЕЛ ПОГАШЕН\n\nРайон снова дышит."
			+ "\nДальше — логово Firewall.\n\nR — пройти ещё раз"
		)
	elif run_state == "paused":
		outcome.text = "ПЕРЕКУР\n\nEsc — вернуться во двор"
	else:
		outcome.text = ""
	if run_state == "won" and not _finish_shown:
		_finish_shown = true
		front.show_finish(Scores.calculate(_run_stats()), elapsed_run, scores.player_name)


func _draw() -> void:
	super._draw()
	if not is_instance_valid(effects):
		return
	var available := _remaining() == 0 and not cleared[room_index]
	var color := Color("e2b36e") if available or cleared[room_index] else Color("e44a42")
	# Painted intercom housing, with a live lens and a visibly powered cable.
	draw_texture_rect(RELAY_TEXTURE, Rect2(relay - Vector2(23, 40), Vector2(46, 80)), false)
	draw_line(
		relay + Vector2(0, 35),
		Vector2(relay.x, float(rooms[room_index].floor)),
		Color("132630"),
		6,
		true
	)
	for ring in range(4):
		draw_circle(
			relay + Vector2(3, -20),
			9 + ring * 4,
			Color(color, 0.09 if not cleared[room_index] else 0.025)
		)
	draw_circle(relay + Vector2(3, -20), 5, color)
	if available:
		draw_arc(relay, 51 + sin(clock * 3) * 2, 0, TAU, 36, Color(color, 0.65), 1, true)
		draw_string(
			ThemeDB.fallback_font,
			relay + Vector2(-37, -57),
			"E · РЕЛЕ",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			17,
			color
		)
	if cleared[room_index] and room_index < 2:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(1185, float(rooms[room_index].floor) - 90),
			"→",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			40,
			color
		)


func _sync_metrics() -> void:
	super._sync_metrics()
	Metrics.stage = "district_playtest"
	Metrics.rig.merge(
		{
			"revision": 25,
			"room": room_index + 1,
			"health": health,
			"run_state": run_state,
			"enemies_alive": _remaining(),
			"kills": kills,
			"hits_landed": hits_landed,
			"player_hits": player_hits,
			"deaths": deaths,
			"relays": cleared.count(true),
			"feet_y": moose.position.y,
			"floor_y": floor_y,
			"jump_bindings": ["W", "Up", "Space"]
		},
		true
	)
	Metrics.rig["seconds"] = elapsed_run
	Metrics.rig["blocking"] = moose.blocking
	Metrics.rig["fps_visible"] = fps_counter.enabled if is_instance_valid(fps_counter) else true
	Metrics.rig["fps"] = Engine.get_frames_per_second()
	Metrics.rig["draw_calls"] = Performance.get_monitor(
		Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
	)
	Metrics.rig["touch_controls"] = (
		touch_controls.enabled if is_instance_valid(touch_controls) else false
	)
	var active_bodies := 0
	for enemy: Enemy in enemies:
		if is_instance_valid(enemy.corpse) and not enemy.corpse.settled:
			active_bodies += enemy.corpse.physical_bodies.size()
	if is_instance_valid(player_corpse) and not player_corpse.settled:
		active_bodies += player_corpse.physical_bodies.size()
	Metrics.rig["ragdoll_active_bodies"] = active_bodies
	Metrics.rig["blocked_hits"] = blocked_hits
	Metrics.rig["player_ragdoll"] = moose.ragdoll_active
	Metrics.rig["corpses"] = enemies.filter(func(enemy: Enemy) -> bool: return enemy.dead).size()
	Metrics.rig["blood_drops"] = blood.drops.size() if is_instance_valid(blood) else 0
	Metrics.rig["blood_stains"] = blood.stains.size() if is_instance_valid(blood) else 0
	Metrics.rig["blood_landed"] = blood.landed if is_instance_valid(blood) else 0
	Metrics.rig.merge(
		{
			"world_night": world_night,
			"time_switches": time_switches,
			"world_night_strength": night_fx.world_strength if is_instance_valid(night_fx) else 0,
			"night_active": night.active(),
			"night_remaining": night.remaining,
			"night_charge": night.charge,
			"night_casts": night.casts,
			"night_bursts": night.bursts,
			"night_damage": night_damage,
			"burst_hits": burst_hits,
			"power_scale": moose.power_scale,
			"sound_muted": audio.muted if is_instance_valid(audio) else true,
			"shoe_layers": 2,
			"hand_digits": 4
		},
		true
	)
	Metrics.rig["score_online"] = scores.online if is_instance_valid(scores) else false
	Metrics.rig["score_session_ready"] = (
		not scores.token.is_empty() if is_instance_valid(scores) else false
	)
	Metrics.rig["menu"] = front.page if is_instance_valid(front) and front.is_open() else "closed"
	if OS.has_feature("web"):
		var state := Metrics.rig.duplicate()
		state.merge({"ready": true, "stage": Metrics.stage, "completed": Metrics.completed}, true)
		JavaScriptBridge.eval(
			(
				"document.body.setAttribute('data-game-metrics', "
				+ JSON.stringify(JSON.stringify(state))
				+ ");"
			),
			true
		)
