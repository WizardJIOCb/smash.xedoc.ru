extends Node2D
const Enemy = preload("res://scripts/actors/district_enemy.gd")
var actors = []
var clock = 0.0
var max_gap = 0.0


class Target:
	extends Node2D
	var crouch = 0.0


func _ready():
	process_priority = 80
	RenderingServer.set_default_clear_color(Color("14282c"))
	for facing in [-1.0, 1.0]:
		var actor = Enemy.new()
		actor.kind = "foreman"
		actor.tuning = (
			JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json")).foreman
		)
		actor.position = Vector2(380 if facing < 0 else 900, 610)
		actor.facing = facing
		var target = Target.new()
		target.position = actor.position + Vector2(facing * 135, 0)
		add_child(target)
		actor.target = target
		add_child(actor)
		actor.rig.body_scale = 2.6
		actors.append(actor)


func _physics_process(delta):
	clock += delta
	if clock > 5.0:
		for actor in actors:
			if actor.phase == 1:
				actor.receive_hit(
					100, "kick", 170, actor.position + Vector2(-actor.facing * 100, 0)
				)
	Metrics.rig = {
		"clock": clock,
		"state": actors[0].state,
		"phase": actors[0].phase,
		"attacks": actors[0].attacks_completed,
		"contacts": actors[0].melee_contacts,
		"max_support_gap": max_gap
	}


func _process(_delta):
	for actor in actors:
		var rig = actor.rig
		var gap = rig.bones.far_hand.global_position.distance_to(
			rig.bones.weapon.to_global(
				Vector2(
					rig.weapon_pose.tuning.foreman.support[0],
					rig.weapon_pose.tuning.foreman.support[1]
				)
			)
		)
		max_gap = maxf(max_gap, gap)
