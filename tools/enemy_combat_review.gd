extends Node2D
## Actual AI timing, grip layering and return poses in both directions.

const Enemy = preload("res://scripts/actors/district_enemy.gd")
const KINDS = ["beaver", "hare", "fox", "lynx", "foreman", "firewall"]
var actors: Array[Node2D] = []
var clock: float = 0
var stage: int = -1
var label: Label


class Target:
	extends Node2D
	var crouch: float = 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("14282c"))
	label = Label.new()
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)


func _physics_process(delta: float) -> void:
	clock += delta
	var next := mini(5, int(clock / 4))
	if next != stage:
		stage = next
		for actor: Node2D in actors:
			remove_child(actor)
			actor.queue_free()
		actors.clear()
		for facing: float in [-1.0, 1.0]:
			var actor := Enemy.new()
			actor.kind = KINDS[stage]
			actor.tuning = (
				JSON
				. parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))[
					actor.kind
				]
			)
			actor.position = Vector2(380 if facing < 0 else 900, 625)
			actor.facing = facing
			var target := Target.new()
			target.position = actor.position + Vector2(facing * (float(actor.tuning.reach) - 30), 0)
			add_child(target)
			actor.target = target
			add_child(actor)
			actor.rig.body_scale = 2.2
			actors.append(actor)
			actors.append(target)
	var actor: Enemy = actors[0]
	label.text = "%s · %s · %.2f · BOTH FACINGS" % [actor.kind, actor.state, actor.elapsed]
	Metrics.rig = {
		"kind": actor.kind,
		"state": actor.state,
		"wind": actor.rig.wind,
		"strike": actor.rig.strike,
		"attacks": actor.attacks_completed,
		"shots": actor.shots_fired,
		"contacts": actor.melee_contacts
	}
