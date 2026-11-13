extends Node2D
## First art and animation playtest. No enemies or damage simulation yet.

const Moose = preload("res://scripts/actors/moose_rig.gd")

var moose: Node2D
var dark: TextureRect
var status: Label
var speed: float = 0.0
var lift: float = 0.0
var vertical_speed: float = 0.0
var quarantine: bool = false
var blend: float = 0.0
var clock: float = 0.0
var punches: int = 0
var jumps: int = 0
var landings: int = 0
var motion: Dictionary
var camera: Camera2D
var closeup: bool = false

var _jump_buffer: float = 0.0
var _preparation_time: float = -1.0
var _dust_time: float = 1.0
var _dust_x: float = 0.0


func _ready() -> void:
	motion = JSON.parse_string(FileAccess.get_file_as_string("res://data/rig_motion.json"))
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)
	_background("res://assets/environment/courtyard-alive-clean.png")
	dark = _background("res://assets/environment/courtyard-quarantine-clean.png")
	dark.modulate.a = 0
	moose = Moose.new()
	moose.position = Vector2(420, 555)
	add_child(moose)
	for pair: Array in [
		["left", KEY_A],
		["left", KEY_LEFT],
		["right", KEY_D],
		["right", KEY_RIGHT],
		["jump", KEY_SPACE],
		["strike", KEY_J],
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
	controls.text = "A/D — бег   Пробел — прыжок   J — удар   T — карантин   B — кости   Z — крупнее"
	controls.position = Vector2(30, 668)
	controls.add_theme_font_size_override("font_size", 19)
	layer.add_child(controls)
	_sync_metrics()


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
	var direction := Input.get_axis("left", "right")
	var previous_speed := speed
	var rate: float = motion.acceleration if direction else motion.braking
	if lift < 0:
		rate *= 0.7
	speed = move_toward(speed, direction * float(motion.run_speed), delta * rate)
	var previous_x := moose.position.x
	moose.position.x = clampf(previous_x + speed * delta, 90, 1170)
	speed = (moose.position.x - previous_x) / delta
	moose.horizontal_speed = speed
	moose.horizontal_acceleration = (speed - previous_speed) / delta
	moose.travel = absf(speed) / float(motion.run_speed)
	if absf(speed) > 20:
		moose.facing = signf(speed)
	_jump_buffer = maxf(0, _jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
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
			lift = 0
			vertical_speed = 0
			landings += 1
			Metrics.record("landed")
	moose.position.y = 555 + lift
	moose.airborne = lift < -0.01
	moose.vertical_speed = vertical_speed
	if Input.is_action_just_pressed("strike") and moose.strike < 0:
		moose.strike = 0
		punches += 1
		Metrics.record("attack_preview")
	if Input.is_action_just_pressed("world"):
		quarantine = not quarantine
	if Input.is_action_just_pressed("bones"):
		moose.show_bones = not moose.show_bones
	if Input.is_action_just_pressed("closeup"):
		closeup = not closeup
	if Engine.get_physics_frames() % 6 == 0:
		_sync_metrics()


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
	status.text = ("КАРАНТИН FIREWALL" if quarantine else "ТИХИЙ ДВОР") + "  /  Анимация v4"
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(moose):
		return
	var shadow := Vector2(moose.position.x, 569)
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
			var drop := Vector2(_dust_x + spread, 565 - sin(progress * PI) * (5 + index % 3 * 3))
			draw_circle(
				drop, (1.0 - progress) * 2.0, Color(0.72, 0.85, 0.78, (1.0 - progress) * 0.5)
			)
	for index in range(80):
		var x := fmod(index * 173.7 - clock * 34, 1340.0) - 30
		var y := fmod(index * 97.3 + clock * (310 + index % 4 * 35), 730.0)
		draw_line(
			Vector2(x, y),
			Vector2(x - 3, y + 13),
			Color(0.64, 0.85, 0.9, 0.08 + blend * 0.12),
			1,
			true
		)
	for index in range(18):
		var x := fmod(index * 211.3 + clock * 8, 1280.0)
		var y := 200 + fmod(index * 63.8 + sin(clock + index) * 18, 350.0)
		var glow := Color(1, 0.73, 0.3, (0.2 + sin(clock * 2 + index) * 0.1) * (1 - blend))
		draw_circle(Vector2(x, y), 2, glow)
	if moose.strike > float(motion.attack_extension) and moose.strike < float(motion.attack_hold):
		var center: Vector2 = moose.bones.near_hand.global_position
		draw_arc(
			center,
			24,
			-1.5 if moose.facing > 0 else 1.65,
			1.45 if moose.facing > 0 else 4.6,
			18,
			Color(1, 0.85, 0.58, 0.55),
			3,
			true
		)


func _sync_metrics() -> void:
	Metrics.stage = "rig_lookdev"
	Metrics.skeletal_animation = true
	Metrics.quarantine = quarantine
	Metrics.rig = {
		"x": moose.position.x,
		"lift": lift,
		"punches": punches,
		"bones": moose.skeleton.get_bone_count(),
		"jumps": jumps,
		"landings": landings,
		"mesh_vertices": moose.mesh.polygon.size(),
		"revision": 4,
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
