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


func _ready() -> void:
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
		["bones", KEY_B]
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
	controls.text = "A / D — бег     Пробел — прыжок     J — удар     T — карантин     B — кости"
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
	speed = move_toward(speed, direction * 235.0, delta * (1050 if direction else 1400))
	moose.position.x = clampf(moose.position.x + speed * delta, 90, 1170)
	moose.travel = absf(speed) / 235.0
	if absf(speed) > 12:
		moose.facing = signf(speed)
	if Input.is_action_just_pressed("jump") and lift == 0:
		vertical_speed = -470
	if vertical_speed != 0 or lift < 0:
		vertical_speed += 1500 * delta
		lift += vertical_speed * delta
		if lift >= 0:
			lift = 0
			vertical_speed = 0
	moose.position.y = 555 + lift
	moose.airborne = lift < -2
	if Input.is_action_just_pressed("strike") and moose.strike < 0:
		moose.strike = 0
		punches += 1
	if Input.is_action_just_pressed("world"):
		quarantine = not quarantine
	if Input.is_action_just_pressed("bones"):
		moose.show_bones = not moose.show_bones
	if Engine.get_physics_frames() % 6 == 0:
		_sync_metrics()


func _process(delta: float) -> void:
	clock += delta
	blend = move_toward(blend, float(quarantine), delta * 0.75)
	dark.modulate.a = blend
	moose.modulate = Color.WHITE.lerp(Color(0.82, 0.74, 0.78), blend)
	status.text = ("КАРАНТИН FIREWALL" if quarantine else "ТИХИЙ ДВОР") + "  /  Проба анимации"
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(moose):
		return
	var shadow := Vector2(moose.position.x, 569)
	for ring in range(5):
		draw_set_transform(shadow, 0, Vector2(1, 0.17))
		draw_circle(Vector2.ZERO, 38 - ring * 4, Color(0.02, 0.05, 0.06, 0.07))
	draw_set_transform(Vector2.ZERO)
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
	if moose.strike > 0.16 and moose.strike < 0.29:
		var center: Vector2 = moose.position + Vector2(50 * moose.facing, -122)
		draw_arc(
			center,
			39,
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
		"bones": moose.skeleton.get_bone_count()
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
	JavaScriptBridge.eval(
		(
			"document.body.setAttribute('data-game-metrics', "
			+ JSON.stringify(JSON.stringify(state))
			+ ");"
		),
		true
	)
