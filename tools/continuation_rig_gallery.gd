extends Node2D
## Explicit prototype art donor; checks both facing directions through attack poses.

const Rig = preload("res://scripts/actors/enemy_rig.gd")
const KINDS = ["beaver", "hare", "fox", "lynx", "foreman", "firewall"]
var actors: Array[Node2D] = []
var stage: int = -1
var clock: float = 0.0
var label: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("14282c"))
	label = Label.new()
	label.position = Vector2(30, 35)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	_show_stage(0)


func _show_stage(value: int) -> void:
	stage = value
	for actor: Node2D in actors:
		remove_child(actor)
		actor.queue_free()
	actors.clear()
	for direction: float in [-1.0, 1.0]:
		var rig := Rig.new()
		rig.kind = KINDS[stage]
		rig.art_profile = ""
		rig.body_scale = 1.35 if stage >= 4 else 1.0
		var socket := Node2D.new()
		socket.position = Vector2(390 if direction < 0 else 890, 545)
		socket.scale = Vector2.ONE * 2.5
		add_child(socket)
		rig.facing = direction
		socket.add_child(rig)
		actors.append(socket)
	label.text = "%s · FACING −1 / +1 · ORIGINAL CAMPAIGN ART" % KINDS[stage]
	queue_redraw()


func _physics_process(delta: float) -> void:
	clock += delta
	var next := mini(5, int(clock / 1.5))
	if next != stage:
		_show_stage(next)
	var phase := fmod(clock, 1.5) / 1.5
	for socket: Node2D in actors:
		var rig: Rig = socket.get_child(0)
		rig.pace = 45 if phase < 0.4 else 0
		rig.wind = sin(phase * PI)
		rig.strike = maxf(0, sin((phase - 0.5) * TAU))
		rig.recoil = maxf(0, sin(phase * TAU * 3))
	Metrics.rig = {"kind": KINDS[stage], "both_facings": true, "phase": phase}


func _draw() -> void:
	draw_rect(Rect2(0, 570, 1280, 150), Color("263c3e"))
	draw_line(Vector2(0, 570), Vector2(1280, 570), Color("d7b375"), 2)
