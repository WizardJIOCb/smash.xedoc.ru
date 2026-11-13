extends Node2D
## Native physics gallery: posed fixtures, not a public gameplay completion.

const Moose = preload("res://scripts/actors/moose_rig.gd")
const EnemyRig = preload("res://scripts/actors/enemy_rig.gd")
const Ragdoll = preload("res://scripts/actors/skeletal_ragdoll.gd")
const Blood = preload("res://scripts/world/blood_fx.gd")

var rigs: Array[Node2D] = []
var corpses: Array[Ragdoll] = []
var time: float = 0
var blood: Blood
var fired: bool = false
var worst_error: float = 0
var samples: Array[Dictionary] = []
var sample_at: float = 1.2


func _ready() -> void:
	var background := Sprite2D.new()
	background.texture = load("res://assets/environment/courtyard-alive-clean.png")
	background.centered = false
	background.scale = Vector2(1280, 720) / background.texture.get_size()
	background.z_index = -10
	add_child(background)
	var terrain := StaticBody2D.new()
	terrain.collision_layer = 8
	terrain.collision_mask = 16
	terrain.position = Vector2(640, 580)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(1600, 40)
	shape.shape = box
	terrain.add_child(shape)
	add_child(terrain)
	var boar := EnemyRig.new()
	boar.kind = "shield"
	boar.position = Vector2(270, 550)
	add_child(boar)
	var moose := Moose.new()
	moose.position = Vector2(630, 400)
	moose.airborne = true
	add_child(moose)
	var rat := EnemyRig.new()
	rat.kind = "whip"
	rat.facing = 1
	rat.position = Vector2(990, 550)
	add_child(rat)
	rigs = [boar, moose, rat]
	blood = Blood.new()
	blood.surfaces = [Rect2(-100, 560, 1480, 30)]
	blood.z_index = 25
	add_child(blood)
	var caption := Label.new()
	caption.text = "ФИЗИКА СКЕЛЕТА / ГАЛЕРЕЯ\nКабан: удар в голову ←     Лось: падение с высоты →     Крыса: подсечка →"
	caption.position = Vector2(60, 40)
	caption.add_theme_font_size_override("font_size", 24)
	add_child(caption)


func _physics_process(delta: float) -> void:
	time += delta
	if time > 1 and not fired:
		fired = true
		for index in range(3):
			var rig := rigs[index]
			rig.ragdoll_active = true
			var hit := rig.position + Vector2(0, -140 if index == 0 else (-90 if index == 1 else -27))
			var impulse := Vector2(-260 if index == 0 else 260, -80)
			var corpse := Ragdoll.new()
			rig.add_child(corpse)
			corpse.start(rig, hit, impulse, Vector2(80, 330) if index == 1 else Vector2.ZERO)
			corpses.append(corpse)
			blood.spill(hit, impulse, true)
	for corpse: Ragdoll in corpses:
		worst_error = maxf(worst_error, corpse.joint_error())
	if time > sample_at and not corpses.is_empty():
		sample_at += 0.5
		var item := {"t": time, "errors": []}
		for corpse: Ragdoll in corpses:
			var details := {}
			for joint: PinJoint2D in corpse.joints:
				var a: RigidBody2D = joint.get_node(joint.node_a)
				var b: RigidBody2D = joint.get_node(joint.node_b)
				details[str(b.name)] = snappedf(a.to_global(joint.get_meta("a")).distance_to(b.to_global(joint.get_meta("b"))), 0.01)
			item.errors.append(details)
		samples.append(item)
	Metrics.rig = {"ragdolls": corpses.size(), "worst_joint_error": worst_error,
		"stains": blood.stains.size(), "blood_landed": blood.landed, "time": time}
	if not corpses.is_empty():
		Metrics.rig["hips"] = corpses.map(func(c: Ragdoll) -> Vector2: return c.bodies.hips.position)
		Metrics.rig["joint_errors"] = corpses.map(func(c: Ragdoll) -> float: return c.joint_error())
		Metrics.rig["samples"] = samples
