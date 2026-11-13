extends Node2D
## Development-only normal-AI preview. Donor art is explicit; release uses real species.

const Enemy = preload("res://scripts/actors/district_enemy.gd")
const Moose = preload("res://scripts/actors/moose_rig.gd")
const KINDS = ["beaver", "hare", "fox", "lynx", "foreman", "firewall"]

var enemy: Enemy
var player: Moose
var clock: float = 0.0
var stage: int = -1
var contacts: int = 0
var bullets: Array[Dictionary] = []
var history: Array[Dictionary] = []
var label: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("14282c"))
	player = Moose.new()
	player.position = Vector2(450, 560)
	add_child(player)
	label = Label.new()
	label.position = Vector2(35, 25)
	label.add_theme_font_size_override("font_size", 22)
	add_child(label)
	_next()


func _next() -> void:
	if is_instance_valid(enemy):
		history.append(
			{
				"kind": enemy.kind,
				"attacks": enemy.attacks_completed,
				"shots": enemy.shots_fired,
				"contacts": enemy.melee_contacts
			}
		)
		remove_child(enemy)
		enemy.queue_free()
	stage += 1
	if stage >= KINDS.size():
		print("ENEMY_REVIEW " + JSON.stringify(history))
		if DisplayServer.get_name() == "headless":
			get_tree().quit()
		stage = 0
	enemy = Enemy.new()
	enemy.kind = KINDS[stage]
	# This fixture deliberately says DONOR ART. No fallback in the main game.
	enemy.art_profile = "whip"
	enemy.tuning = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))[
		enemy.kind
	]
	enemy.target = player
	enemy.position = Vector2(550 if stage in [0, 1, 4] else 820, 560)
	enemy.hit_player.connect(func(_damage: int, _source: Vector2, _high: bool): contacts += 1)
	enemy.shot.connect(_shot)
	add_child(enemy)
	label.text = (
		"AI PROTOTYPE · EXPLICIT DONOR ART\n%s · normal state machine · hits %d"
		% [enemy.kind, contacts]
	)
	queue_redraw()


func _physics_process(delta: float) -> void:
	clock += delta
	if clock >= (stage + 1) * 8.0 and stage < KINDS.size() - 1:
		_next()
	elif clock >= 48.0 and stage == KINDS.size() - 1:
		_next()
	# Show phase transitions in the boss sandbox; attacks remain normal AI.
	var local_time := fmod(clock, 8.0)
	if enemy.boss and local_time > 3.5 and enemy.phase == 1:
		enemy.receive_hit(
			stage * 100 + 1, "kick", 170 if enemy.kind == "foreman" else 180, Vector2(400, 560)
		)
	if enemy.kind == "firewall" and local_time > 5.3 and enemy.phase == 2:
		enemy.receive_hit(999, "kick", 130, Vector2(400, 560))
	for bullet: Dictionary in bullets:
		bullet.at += bullet.velocity * delta
	bullets = bullets.filter(
		func(bullet: Dictionary): return bullet.at.x > 0 and bullet.at.x < 1280
	)
	Metrics.rig = {
		"enemy_preview": enemy.kind,
		"phase": enemy.phase,
		"hits": contacts,
		"shots": enemy.shots_fired,
		"state": enemy.state,
		"history": history
	}
	queue_redraw()


func _shot(origin: Vector2, aim: Vector2, _damage: int) -> void:
	bullets.append({"at": origin, "velocity": origin.direction_to(aim) * 420.0})


func _draw() -> void:
	draw_rect(Rect2(0, 570, 1280, 150), Color("263c3e"))
	draw_line(Vector2(0, 570), Vector2(1280, 570), Color("d7b375"), 2)
	for bullet: Dictionary in bullets:
		draw_line(bullet.at, bullet.at + bullet.velocity.normalized() * 15, Color("ffd187"), 3)
