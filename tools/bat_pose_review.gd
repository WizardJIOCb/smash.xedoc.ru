extends Node2D

const Moose = preload("res://scripts/actors/moose_rig.gd")
const Armory = preload("res://scripts/systems/armory.gd")
var rigs: Array[Node2D] = []
var gears: Array[Node2D] = []
var clock: float = 0
var next_swing: float = 0.7
var max_grip_gap: float = 0.0
var max_elbow: float = 0.0
var max_shoulder_drift: float = 0.0
var worst_grip: Dictionary = {}


func _ready() -> void:
	process_priority = 80
	RenderingServer.set_default_clear_color(Color("14282c"))
	for direction: float in [-1.0, 1.0]:
		var rig := Moose.new()
		rig.position = Vector2(420 if direction < 0 else 860, 610)
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
		next_swing += 0.66 if "--chains" in OS.get_cmdline_user_args() else 1.3
	Metrics.rig = {
		"clock": clock,
		"attack_time": rigs[0].combat.elapsed,
		"angle": rigs[0].melee_angle,
		"max_grip_gap": max_grip_gap,
		"worst_grip": worst_grip,
		"max_elbow_degrees": rad_to_deg(max_elbow),
		"max_shoulder_drift": max_shoulder_drift
	}


func _process(_delta: float) -> void:
	for index in range(rigs.size()):
		var rig: Node2D = rigs[index]
		var spec: Dictionary = rig.bat_pose.assembly
		for side: String in ["near", "far"]:
			var shoulder: Bone2D = rig.bones[side + "_arm"]
			max_shoulder_drift = maxf(
				max_shoulder_drift, shoulder.position.distance_to(shoulder.rest.origin)
			)
			var wrist: Array = spec[side + "_wrist"]
			var at := (
				Vector2(wrist[0] - spec.pivot[0], wrist[1] - spec.pivot[1]) * float(spec.scale)
			)
			var target: Vector2 = gears[index].visual.to_global(at)
			var gap := target.distance_to(rig.bones[side + "_hand"].global_position)
			if gap > max_grip_gap:
				max_grip_gap = gap
				worst_grip = {
					"side": side,
					"clock": clock,
					"elapsed": rig.combat.elapsed,
					"target": str(rig.to_local(target))
				}
			max_elbow = maxf(max_elbow, absf(rig.bones[side + "_fore"].rotation))
	Metrics.rig["max_grip_gap"] = max_grip_gap
	Metrics.rig["max_elbow_degrees"] = rad_to_deg(max_elbow)
	Metrics.rig["max_shoulder_drift"] = max_shoulder_drift
