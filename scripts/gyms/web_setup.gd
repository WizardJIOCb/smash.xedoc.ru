extends Node2D

const Motion = preload("res://scripts/core/probe_motion.gd")

var _probe: Vector2 = Vector2(640, 490)
var _tuning: Dictionary
var _dark: TextureRect
var _status: Label
var _blend: float = 0.0
var _quarantine: bool = false


func _ready() -> void:
	_tuning = JSON.parse_string(FileAccess.get_file_as_string("res://data/web_setup.json"))
	var camera := Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)
	_add_background("res://assets/setup/courtyard_alive.png")
	_dark = _add_background("res://assets/setup/courtyard_quarantine.png")
	_dark.modulate.a = 0.0
	_add_overlay()
	_setup_action(&"probe_left", [KEY_A, KEY_LEFT])
	_setup_action(&"probe_right", [KEY_D, KEY_RIGHT])
	_setup_action(&"probe_up", [KEY_W, KEY_UP])
	_setup_action(&"probe_down", [KEY_S, KEY_DOWN])
	_setup_action(&"quarantine", [KEY_T])
	Metrics.record("scene_ready")
	Metrics.completed = true
	_sync_web_metrics()


func _add_background(path: String) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load(path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.size = Vector2(1280, 720)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.z_index = -1
	add_child(image)
	return image


func _add_overlay() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := ColorRect.new()
	top.color = Color(0.025, 0.05, 0.065, 0.86)
	top.size = Vector2(1280, 68)
	layer.add_child(top)
	var heading := Label.new()
	heading.text = "ЛОСЬ • ПРОВЕРКА ВЕБ-СЦЕНЫ"
	heading.position = Vector2(24, 10)
	heading.add_theme_font_size_override("font_size", 22)
	layer.add_child(heading)
	_status = Label.new()
	_status.position = Vector2(24, 39)
	_status.add_theme_font_size_override("font_size", 14)
	layer.add_child(_status)
	var bottom := Label.new()
	bottom.text = (
		"WASD / стрелки — световой маркер    T — сменить состояние"
		+ "    Анимация Лося ещё не подключена"
	)
	bottom.position = Vector2(24, 684)
	bottom.add_theme_font_size_override("font_size", 17)
	layer.add_child(bottom)


func _setup_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key: int in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(&"probe_left", &"probe_right", &"probe_up", &"probe_down")
	var b: Array = _tuning["bounds"]
	_probe = Motion.step(
		_probe,
		direction,
		float(_tuning["speed"]),
		delta,
		Rect2(float(b[0]), float(b[1]), float(b[2]), float(b[3]))
	)
	if Input.is_action_just_pressed(&"quarantine"):
		_quarantine = not _quarantine
		Metrics.record("quarantine_toggled")
	Metrics.probe_x = _probe.x
	Metrics.probe_y = _probe.y
	Metrics.quarantine = _quarantine
	if Engine.get_physics_frames() % 6 == 0:
		_sync_web_metrics()
	queue_redraw()


func _process(delta: float) -> void:
	_blend = move_toward(_blend, float(_quarantine), float(_tuning["blend_speed"]) * delta)
	_dark.modulate.a = _blend
	_status.text = (
		"Godot 4.7.2 / WebGL2 • %s • Это проверка движка с концептами"
		% ("КАРАНТИН" if _quarantine else "ЖИВОЙ РАЙОН")
	)


func _draw() -> void:
	draw_circle(_probe, 18.0, Color(0.3, 0.9, 0.9, 0.18))
	draw_arc(_probe, 11.0, 0.0, TAU, 28, Color(0.65, 1.0, 0.95, 0.9), 2.0, true)
	draw_line(_probe - Vector2(5, 0), _probe + Vector2(5, 0), Color.WHITE, 1.5)
	draw_line(_probe - Vector2(0, 5), _probe + Vector2(0, 5), Color.WHITE, 1.5)


func _sync_web_metrics() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__GAME__ = {ready:true, stage:'web_setup_only'};", true)
		JavaScriptBridge.eval("window.__metrics = " + JSON.stringify(Metrics.to_dict()) + ";", true)
		JavaScriptBridge.eval(
			(
				"document.body.setAttribute('data-game-metrics', "
				+ JSON.stringify(JSON.stringify(Metrics.to_dict()))
				+ ");"
			),
			true
		)
