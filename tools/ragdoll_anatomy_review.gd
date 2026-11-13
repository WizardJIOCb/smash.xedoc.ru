extends Node2D
## Bounded native gallery, mirrored road/air falls then both enemy types.

const Moose = preload("res://scripts/actors/moose_rig.gd")
const Enemy = preload("res://scripts/actors/enemy_rig.gd")
const Corpse = preload("res://scripts/actors/skeletal_ragdoll.gd")

var rigs: Array[Node2D] = []
var corpses: Array[Corpse] = []
var clock: float = 0.0
var stage: int = 0
var fired: bool = false
var next_sample: float = 2.0
var samples: Array[Dictionary] = []


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
	box.size = Vector2(2000, 40)
	shape.shape = box
	terrain.add_child(shape)
	add_child(terrain)
	_spawn()


func _spawn() -> void:
	for rig: Node2D in rigs:
		remove_child(rig)
		rig.queue_free()
	rigs.clear()
	corpses.clear()
	for index in range(2):
		var rig: Node2D = Moose.new() if stage == 0 else Enemy.new()
		if stage == 1:
			rig.kind = "shield" if index == 0 else "whip"
		rig.facing = 1 if index == 0 else -1
		rig.position = Vector2(340 if index == 0 else 900, 550 if stage == 1 or index == 0 else 350)
		add_child(rig)
		rigs.append(rig)
	fired = false


func _physics_process(delta: float) -> void:
	clock += delta
	if clock >= 6.5 and stage == 0:
		stage = 1
		_spawn()
	if clock >= (7.5 if stage == 1 else 1.0) and not fired:
		fired = true
		for index in range(2):
			var rig := rigs[index]
			rig.ragdoll_active = true
			var corpse := Corpse.new()
			rig.add_child(corpse)
			corpse.start(
				rig,
				rig.position + Vector2(0, -140 if index == 0 else -30),
				Vector2(-130 if index == 0 else 130, -60),
				Vector2(0, 180) if stage == 0 and index == 1 else Vector2.ZERO
			)
			corpses.append(corpse)
	if clock >= next_sample and not corpses.is_empty():
		next_sample += 1.0
		var sample := {"t": clock, "stage": stage, "corpses": []}
		for corpse: Corpse in corpses:
			var local_angles := {}
			var speeds := {}
			for id: String in corpse.rig.bones:
				if "shin" in id or "foot" in id or "thigh" in id or id.ends_with("_leg"):
					local_angles[id] = rad_to_deg(corpse.rig.bones[id].rotation)
			for body: RigidBody2D in corpse.physical_bodies:
				speeds[str(body.name)] = [body.linear_velocity.length(), body.angular_velocity]
			sample.corpses.append(
				{
					"local": local_angles,
					"speeds": speeds,
					"settled": corpse.settled,
					"hips": corpse.bodies.hips.position
				}
			)
		samples.append(sample)
	Metrics.rig = {"samples": samples, "stage": stage}
	if DisplayServer.get_name() == "headless" and clock >= 13:
		print("ANATOMY ", JSON.stringify(samples))
		get_tree().quit()
