extends Node2D

const Moose = preload("res://scripts/actors/moose_rig.gd")
const Armory = preload("res://scripts/systems/armory.gd")
var rigs: Array[Node2D] = []
var gears: Array[Node2D] = []
var clock: float = 0
var next_swing: float = 0.7


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("14282c"))
	for direction: float in [-1.0, 1.0]:
		var rig := Moose.new()
		rig.position = Vector2(360 if direction < 0 else 920, 610)
		rig.power_scale = 2.1
		rig.facing = direction
		add_child(rig)
		var gear := Armory.new()
		add_child(gear)
		gear.configure(rig)
		gear.grant("bat")
		rigs.append(rig)
		gears.append(gear)


func _physics_process(delta: float) -> void:
	clock += delta
	for index in range(rigs.size()):
		var rig: Node2D = rigs[index]
		var low := clock >= 3.5 and clock < 5
		rig.crouch_requested = low
		rig.airborne = clock >= 5
		rig.combat.advance(delta, rig.airborne, low)
		gears[index].advance(delta, [], true)
	if clock >= next_swing:
		for rig: Node2D in rigs:
			rig.combat.request("punch", rig.airborne, rig.crouch_requested)
		next_swing += 1.3
	Metrics.rig = {
		"clock": clock, "attack_time": rigs[0].combat.elapsed, "angle": rigs[0].melee_angle
	}
