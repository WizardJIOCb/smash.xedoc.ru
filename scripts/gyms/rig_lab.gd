extends Node2D
## First art and animation playtest. No enemies or damage simulation yet.

const Moose = preload("res://scripts/actors/moose_rig.gd")
const StrideStop = preload("res://scripts/core/stride_stop.gd")
const Rain = preload("res://scripts/world/rain_fx.gd")

var moose: Moose
var rain: Rain
var dark: TextureRect
var status: Label
var speed: float = 0.0
var lift: float = 0.0
var vertical_speed: float = 0.0
var quarantine: bool = false
var blend: float = 0.0
var clock: float = 0.0
var punches: int = 0
var kicks: int = 0
var jumps: int = 0
var landings: int = 0
var motion: Dictionary
var camera: Camera2D
var closeup: bool = false
var floor_y: float = 555.0
var movement_bounds := Vector2(90, 1170)
var move_power: float = 1.0
var combat_rate: float = 1.0
var guard_tuning: Dictionary = (
	JSON.parse_string(FileAccess.get_file_as_string("res://data/physical_combat.json")).guard
)

var network_input: bool = false
var held_input: Dictionary = {}
var pressed_input: Array = []

var _jump_buffer: float = 0.0
var _preparation_time: float = -1.0
var _dust_time: float = 1.0
var _dust_x: float = 0.0
var _dust_y: float = 0.0
var _trail: Array[Vector2] = []
var _trail_serial: int = -1
var _stride_stop := StrideStop.new()
var _direction_was_held: bool = false
var _turn_axis: float = 0.0
var _manual_facing: bool = false


func _input_held(action: String) -> bool:
	return bool(held_input.get(action, false)) if network_input else Input.is_action_pressed(action)


func _input_pressed(action: String) -> bool:
	return pressed_input.has(action) if network_input else Input.is_action_just_pressed(action)


func _input_axis() -> float:
	return float(_input_held("right")) - float(_input_held("left"))


func quick_turn() -> void:
	if moose.ragdoll_active:
		return
	moose.combat.interrupt()
	moose.facing *= -1
	_turn_axis = _input_axis()
	_manual_facing = true
	_stride_stop.active = false
	_direction_was_held = false
	moose.finishing_step = false
	moose.stop_cycle_distance = 0


func _ready() -> void:
	motion = JSON.parse_string(FileAccess.get_file_as_string("res://data/rig_motion.json"))
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)
	_background("res://assets/environment/courtyard-alive-clean.png")
	dark = _background("res://assets/environment/courtyard-quarantine-clean.png")
	dark.modulate.a = 0
	rain = Rain.new()
	add_child(rain)
	moose = Moose.new()
	moose.position = Vector2(420, 555)
	add_child(moose)
	moose.combat.started.connect(_attack_started)
	for pair: Array in [
		["left", KEY_A],
		["left", KEY_LEFT],
		["right", KEY_D],
		["right", KEY_RIGHT],
		["jump", KEY_SPACE],
		["jump", KEY_W],
		["jump", KEY_UP],
		["strike", KEY_J],
		["kick", KEY_K],
		["block", KEY_L],
		["crouch", KEY_S],
		["crouch", KEY_DOWN],
		["sprint", KEY_SHIFT],
		["world", KEY_T],
		["bones", KEY_B],
		["closeup", KEY_Z]
	]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		var event := InputEventKey.new()
		event.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], event)
	var layer := CanvasLayer.new()
	add_child(layer)
	var heading := Label.new()
	heading.text = "ЛОСЬ: РАЙОН ЗАКРЫТ"
	heading.position = Vector2(30, 24)
	heading.add_theme_font_size_override("font_size", 28)
	layer.add_child(heading)
	status = Label.new()
	status.position = Vector2(31, 62)
	status.add_theme_font_size_override("font_size", 16)
	layer.add_child(status)
	var controls := Label.new()
	controls.text = (
		"A/D — ход   Shift — бег   S/↓ — присед   W/↑/Пробел — прыжок   J/K — руки/ноги"
		+ "   T — карантин   B — кости   Z — крупнее"
	)
	controls.position = Vector2(30, 668)
	controls.add_theme_font_size_override("font_size", 17)
	layer.add_child(controls)
	_sync_metrics()


func _unhandled_input(event: InputEvent) -> void:
	# Events retain quick taps between physics frames and reject keyboard repeat.
	if _input_held("block") or moose.ragdoll_active:
		return
	var low: bool = _input_held("crouch") and not moose.airborne
	if event.is_action_pressed("strike"):
		moose.combat.request("punch", moose.airborne, low)
	elif event.is_action_pressed("kick"):
		moose.combat.request("kick", moose.airborne, low)


func _attack_started(kind: String, _side: String, in_air: bool, low: bool) -> void:
	if kind == "punch":
		punches += 1
	else:
		kicks += 1
	Metrics.record(("air_" if in_air else ("crouch_" if low else "ground_")) + kind)


func _background(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = Vector2(1280, 720)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = -10
	add_child(rect)
	return rect


func _physics_process(delta: float) -> void:
	var direction := _input_axis()
	if direction == 0:
		_turn_axis = 0
	if _manual_facing and direction != 0 and direction != _turn_axis:
		_manual_facing = false
	var crouching := _input_held("crouch") and lift == 0
	moose.blocking = _input_held("block")
	if moose.blocking:
		moose.combat.interrupt()
	moose.crouch_requested = crouching
	moose.sprinting = (
		_input_held("sprint") and direction != 0 and not crouching and not moose.blocking
	)
	var previous_speed := speed
	var rate: float = motion.acceleration if direction else motion.braking
	if lift < 0:
		rate *= 0.7
	var move_scale := 1.0
	var target_speed := float(motion.run_speed) if moose.sprinting else float(motion.walk_speed)
	if crouching:
		target_speed = float(motion.crouch_speed)
	target_speed *= move_power
	if moose.blocking:
		target_speed *= float(guard_tuning.move_multiplier)
	if moose.combat.elapsed >= 0 and lift == 0:
		move_scale = minf(move_scale, 0.2 if moose.combat.kind == "kick" else 0.48)
	var previous_x := moose.position.x
	var stopping: bool = direction == 0 and lift == 0 and moose.strike < 0 and _preparation_time < 0
	if not stopping:
		_stride_stop.active = false
	moose.finishing_step = false
	moose.stop_cycle_distance = 0
	if stopping and _direction_was_held and not _stride_stop.active and absf(speed) > 25:
		var final_phase := PI if speed * moose.facing >= 0 else 0.0
		_stride_stop.begin(speed, moose.gait, moose.stride_cycle_distance(), final_phase)
	_direction_was_held = direction != 0
	var displacement: float
	if _stride_stop.active:
		moose.finishing_step = true
		moose.stop_cycle_distance = _stride_stop.cycle_distance
		displacement = _stride_stop.advance(delta)
	else:
		speed = move_toward(speed, direction * target_speed * move_scale, delta * rate)
		displacement = speed * delta
	moose.position.x = clampf(previous_x + displacement, movement_bounds.x, movement_bounds.y)
	speed = (moose.position.x - previous_x) / delta
	moose.horizontal_speed = speed
	moose.horizontal_acceleration = (speed - previous_speed) / delta
	moose.travel = absf(speed) / float(motion.run_speed)
	if (
		direction != 0
		and signf(speed) == signf(direction)
		and absf(speed) > 20
		and moose.combat.chain_length == 0
		and not moose.blocking
		and not _manual_facing
	):
		moose.facing = signf(speed)
	_jump_buffer = maxf(0, _jump_buffer - delta)
	if _input_pressed("jump"):
		_jump_buffer = float(motion.jump_buffer)
	if _jump_buffer > 0 and lift == 0 and _preparation_time < 0:
		_preparation_time = 0
		_jump_buffer = 0
	if _preparation_time >= 0:
		_preparation_time += delta
		moose.preparation = smoothstep(0, float(motion.jump_preparation), _preparation_time)
		if _preparation_time >= float(motion.jump_preparation):
			vertical_speed = -float(motion.jump_speed)
			_preparation_time = -1
			moose.preparation = 0
			jumps += 1
			Metrics.record("takeoff")
	if vertical_speed != 0 or lift < 0:
		vertical_speed += float(motion.gravity) * delta
		lift += vertical_speed * delta
		if lift >= 0:
			moose.land(vertical_speed)
			_dust_time = 0
			_dust_x = moose.position.x
			_dust_y = floor_y + 8
			lift = 0
			vertical_speed = 0
			landings += 1
			Metrics.record("landed")
	moose.position.y = floor_y + lift
	moose.airborne = lift < -0.01
	moose.vertical_speed = vertical_speed
	moose.combat.advance(delta * combat_rate, moose.airborne, crouching)
	if _input_pressed("world"):
		_world_pressed()
	if _input_pressed("bones"):
		moose.show_bones = not moose.show_bones
	if _input_pressed("closeup"):
		closeup = not closeup
	if Engine.get_physics_frames() % 6 == 0:
		_sync_metrics()


func _world_pressed() -> void:
	quarantine = not quarantine


func _process(delta: float) -> void:
	clock += delta
	_dust_time += delta
	var camera_blend := 1.0 - exp(-delta * 10)
	camera.zoom = camera.zoom.lerp(Vector2.ONE * (1.8 if closeup else 1.0), camera_blend)
	var focus: Vector2 = moose.position + Vector2(20, -115) if closeup else Vector2(640, 360)
	camera.position = camera.position.lerp(focus, camera_blend)
	blend = move_toward(blend, float(quarantine), delta * 0.75)
	dark.modulate.a = blend
	moose.modulate = Color.WHITE.lerp(Color(0.82, 0.74, 0.78), blend)
	status.text = ("КАРАНТИН FIREWALL" if quarantine else "ТИХИЙ ДВОР") + "  /  Анимация v13"
	if moose.sprinting:
		status.text += "  ·  БЕГ"
	if moose.crouch > 0.5:
		status.text += "  ·  ПРИСЕД"
	if moose.strike >= 0:
		var name_text := (
			"ПИНОК"
			if moose.combat.kind == "kick"
			else ("ЛЕВАЯ" if moose.combat.side == "near" else "ПРАВАЯ")
		)
		status.text += "  ·  " + ("В ВОЗДУХЕ: " if moose.combat.in_air else "") + name_text
		if moose.combat.kind == "kick":
			status.text += " " + str(moose.combat.kick_step + 1)
	_update_attack_trail()
	queue_redraw()


func _update_attack_trail() -> void:
	if _trail_serial != moose.combat.serial or not moose.combat.is_active():
		_trail.clear()
		_trail_serial = moose.combat.serial
		return
	var tip: String = moose.combat.side + ("_foot" if moose.combat.kind == "kick" else "_hand")
	var bone: Bone2D = moose.bones[tip]
	_trail.append(bone.to_global(Vector2(0, 17)))
	if _trail.size() > 7:
		_trail.pop_front()


func _draw() -> void:
	if not is_instance_valid(moose):
		return
	var shadow := Vector2(moose.position.x, floor_y + 14)
	var shadow_scale := clampf(1.0 + lift / 250.0, 0.55, 1.0)
	for ring in range(5):
		draw_set_transform(shadow, 0, Vector2(1, 0.17))
		draw_circle(
			Vector2.ZERO,
			(38 - ring * 4) * shadow_scale,
			Color(0.02, 0.05, 0.06, 0.07 * shadow_scale)
		)
	draw_set_transform(Vector2.ZERO)
	if _dust_time < 0.32:
		for index in range(12):
			var progress := _dust_time / 0.32
			var spread := (index - 5.5) * (4.0 + progress * 6.0)
			var drop := Vector2(
				_dust_x + spread, _dust_y - sin(progress * PI) * (5 + index % 3 * 3)
			)
			draw_circle(
				drop, (1.0 - progress) * 2.0, Color(0.72, 0.85, 0.78, (1.0 - progress) * 0.5)
			)
	for index in range(18):
		var x := fmod(index * 211.3 + clock * 8, 1280.0)
		var y := 200 + fmod(index * 63.8 + sin(clock + index) * 18, 350.0)
		var glow := Color(1, 0.73, 0.3, (0.2 + sin(clock * 2 + index) * 0.1) * (1 - blend))
		draw_circle(Vector2(x, y), 2, glow)
	for index in range(1, _trail.size()):
		var strength := float(index) / _trail.size()
		draw_line(_trail[index - 1], _trail[index], Color(1, 0.86, 0.63, strength * 0.45), 2, true)


func _sync_metrics() -> void:
	Metrics.stage = "rig_lookdev"
	Metrics.skeletal_animation = true
	Metrics.quarantine = quarantine
	Metrics.rig = {
		"x": moose.position.x,
		"lift": lift,
		"punches": punches,
		"kicks": kicks,
		"bones": moose.skeleton.get_bone_count(),
		"jumps": jumps,
		"landings": landings,
		"mesh_vertices": moose.mesh.polygon.size(),
		"revision": 13,
		"sprinting": moose.sprinting,
		"finishing_step": moose.finishing_step,
		"stop_planned": _stride_stop.planned_distance,
		"stop_travelled": _stride_stop.travelled,
		"speed": speed,
		"gait": moose.gait,
		"backpedalling": speed * moose.facing < -8,
		"facing": moose.facing,
		"kick_step": moose.combat.kick_step + 1,
		"attack": moose.combat.kind if moose.strike >= 0 else "idle",
		"attack_side": moose.combat.side,
		"attack_counts": moose.combat.counts,
		"attack_history": moose.combat.history,
		"combo": moose.combat.chain_length,
		"sleeve_vertices": moose.sleeve.polygon.size(),
		"crouching": moose.crouch > 0.5,
		"trouser_meshes": moose.leg_meshes.size(),
		"closeup": closeup,
		"camera_glance": moose.camera_glance,
		"glance_count": moose.glance_count
	}
	if not OS.has_feature("web"):
		return
	var state := {
		"ready": true,
		"stage": "rig_lookdev",
		"x": moose.position.x,
		"lift": lift,
		"quarantine": quarantine,
		"punches": punches,
		"bones": moose.skeleton.get_bone_count(),
		"skeletal_animation": true
	}
	state.merge(Metrics.rig, true)
	JavaScriptBridge.eval(
		(
			"document.body.setAttribute('data-game-metrics', "
			+ JSON.stringify(JSON.stringify(state))
			+ ");"
		),
		true
	)
