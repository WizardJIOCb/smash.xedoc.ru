extends Node2D
const Moose = preload("res://scripts/actors/moose_rig.gd")
const Armory = preload("res://scripts/systems/armory.gd")
var rigs = []
var gears = []
var clock = 0.0
var next_swing = 1.2


func _ready():
	RenderingServer.set_default_clear_color(Color("14282c"))
	for direction in [-1.0, 1.0]:
		var rig = Moose.new()
		rig.position = Vector2(390 if direction < 0 else 890, 610)
		rig.power_scale = 2.1
		rig.facing = direction
		add_child(rig)
		var gear = Armory.new()
		add_child(gear)
		gear.configure(rig)
		gear.grant("knuckles")
		rigs.append(rig)
		gears.append(gear)


func _physics_process(delta):
	clock += delta
	for i in range(rigs.size()):
		rigs[i].combat.advance(delta, false, false)
		gears[i].advance(delta, [], true)
	if clock >= next_swing:
		for rig in rigs:
			rig.combat.request("punch", false, false)
		next_swing += 0.70

	Metrics.rig = {
		"clock": clock,
		"attacks": rigs[0].combat.serial,
		"history": rigs[0].combat.history,
		"weapon": gears[0].stats()
	}
