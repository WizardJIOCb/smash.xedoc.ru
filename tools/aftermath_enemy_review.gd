extends Node2D
## Isolated normal-AI/gallery review. Donor art requires --review-art=donor.

const Enemy = preload("res://scripts/actors/district_enemy.gd")
const Moose = preload("res://scripts/actors/moose_rig.gd")
const KINDS = [
	"otter",
	"seal",
	"skipper",
	"mole",
	"ferret",
	"dispatcher",
	"raccoon",
	"hedgehog",
	"agronomist",
	"crow",
	"owl",
	"manager"
]

var cast: Array = KINDS.duplicate()
var gallery: bool = false
var donor: bool = false
var stage: int = -1
var clock: float = 0.0
var stage_time: float = 0.0
var enemy: Enemy
var player: Moose
var actors: Array[Node2D] = []
var bullets: Array[Dictionary] = []
var history: Array[Dictionary] = []
var phases_seen: Array[int] = []
var label: Label
var cue: Label
var contacts: int = 0


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--review-art=donor":
			donor = true
		elif argument == "--review-mode=gallery":
			gallery = true
		elif argument.begins_with("--review-kind="):
			cast = [argument.get_slice("=", 1)]
		elif argument.begins_with("--review-cast="):
			cast = Array(argument.get_slice("=", 1).split(",", false))
	RenderingServer.set_default_clear_color(Color("14282c"))
	label = Label.new()
	label.position = Vector2(30, 25)
	label.add_theme_font_size_override("font_size", 22)
	add_child(label)
	cue = Label.new()
	cue.position = Vector2(30, 65)
	cue.add_theme_font_size_override("font_size", 21)
	add_child(cue)
	if not gallery:
		player = Moose.new()
		player.position = Vector2(490, 560)
		add_child(player)
	_next()


func _next() -> void:
	if is_instance_valid(enemy):
		history.append(
			{
				"kind": enemy.kind,
				"attacks": enemy.attacks_completed,
				"shots": enemy.shots_fired,
				"contacts": enemy.melee_contacts,
				"phases": phases_seen.duplicate()
			}
		)
	for actor: Node2D in actors:
		remove_child(actor)
		actor.queue_free()
	actors.clear()
	stage += 1
	stage_time = 0
	if stage >= cast.size():
		print("AFTERMATH_REVIEW " + JSON.stringify(history))
		if DisplayServer.get_name() == "headless":
			get_tree().quit()
		set_physics_process(false)
		return
	var tuning: Dictionary = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))[cast[stage]]
	)
	if is_instance_valid(player):
		player.position = Vector2(490, 560)
	for direction: float in [-1.0, 1.0] if gallery else [-1.0]:
		var socket := Node2D.new()
		socket.position = Vector2(380 if direction < 0 else 900, 553) if gallery else Vector2.ZERO
		socket.scale = Vector2.ONE * (1.7 if gallery else 1.0)
		add_child(socket)
		actors.append(socket)
		var actor := Enemy.new()
		actor.kind = cast[stage]
		actor.tuning = tuning
		actor.art_profile = "whip" if donor else ""
		actor.facing = direction
		actor.position = Vector2.ZERO if gallery else Vector2(690, 560)
		actor.target = player
		socket.add_child(actor)
		if gallery:
			actor.set_physics_process(false)
		else:
			actor.shot.connect(_shot)
			actor.feedback.connect(_feedback)
			actor.hit_player.connect(func(_damage: int, _at: Vector2, _high: bool): contacts += 1)
			actor.forced_player_motion.connect(func(motion: float): player.position.x += motion)
		enemy = actor
	phases_seen = [1]
	cue.text = ""
	queue_redraw()


func _physics_process(delta: float) -> void:
	clock += delta
	stage_time += delta
	if gallery:
		var unit := fmod(stage_time, 2.0) / 2.0
		for socket: Node2D in actors:
			var actor: Enemy = socket.get_child(0)
			actor.rig.facing = actor.facing
			actor.rig.pace = 35 if unit < 0.25 else 0
			actor.rig.wind = sin(unit * PI) if unit < 0.5 else 0
			actor.rig.strike = maxf(0, sin((unit - 0.5) * TAU))
			actor.rig.recoil = maxf(0, sin(unit * TAU * 3))
		if stage_time >= 2.0:
			_next()
	else:
		if enemy.boss and stage_time >= 6.0 and enemy.phase == 1:
			enemy.health = int(enemy.maximum_health * 0.49)
			enemy._update_phase()
		if enemy.phase_count == 3 and stage_time >= 13.0 and enemy.phase == 2:
			enemy.health = int(enemy.maximum_health * 0.25)
			enemy._update_phase()
		if not phases_seen.has(enemy.phase):
			phases_seen.append(enemy.phase)
		for bullet: Dictionary in bullets:
			bullet.at += bullet.velocity * delta
		bullets = bullets.filter(
			func(bullet: Dictionary): return bullet.at.x > 0 and bullet.at.x < 1280
		)
		if stage_time >= (20.0 if enemy.boss else 8.0):
			_next()
	label.text = (
		"%s · %s · %s · ФАЗА %d · УДАРЫ %d / ВЫСТРЕЛЫ %d"
		% [
			enemy.kind,
			"EXPLICIT DONOR ART" if donor else "ORIGINAL CAMPAIGN ART",
			enemy.state,
			enemy.phase,
			enemy.attacks_completed,
			enemy.shots_fired
		]
	)
	Metrics.rig = {
		"kind": enemy.kind,
		"state": enemy.state,
		"phase": enemy.phase,
		"shots": enemy.shots_fired,
		"contacts": contacts,
		"history": history,
		"donor_art": donor,
		"gallery": gallery
	}
	queue_redraw()


func _shot(origin: Vector2, aim: Vector2, _damage: int) -> void:
	bullets.append({"at": origin, "velocity": origin.direction_to(aim) * 420})


func _feedback(_at: Vector2, text: String, color: Color, _sound: String) -> void:
	cue.text = text
	cue.modulate = color


func _draw() -> void:
	draw_rect(Rect2(0, 570, 1280, 150), Color("263c3e"))
	draw_line(Vector2(0, 570), Vector2(1280, 570), Color("d7b375"), 2)
	for bullet: Dictionary in bullets:
		draw_line(bullet.at, bullet.at + bullet.velocity.normalized() * 15, Color("ffd187"), 3)
