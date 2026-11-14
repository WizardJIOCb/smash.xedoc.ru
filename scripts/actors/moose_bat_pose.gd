extends RefCounted
## Two hands share the handle; the shaft sweeps with the trunk instead of a jab.

const ArmIK = preload("res://scripts/core/arm_ik.gd")
var tuning: Dictionary = JSON.parse_string(
	FileAccess.get_file_as_string("res://data/bat_pose.json")
)


func apply(rig: Node2D) -> void:
	if rig.held_melee != "bat" or rig.blocking or rig.power_pose.length_squared() > 0.001:
		return
	var grip := _point("rest")
	var angle: float = tuning.angles[0]
	var lean := 0.0
	var attack = rig.combat
	if attack.elapsed >= 0 and attack.kind == "punch":
		var timing: Dictionary = attack.timings()
		var time: float = attack.elapsed
		if time < float(timing.windup):
			var phase := smoothstep(0, float(timing.windup), time)
			grip = grip.lerp(_point("wind"), phase)
			angle = lerpf(angle, float(tuning.angles[1]), phase)
			lean = phase * float(tuning.wind_lean)
		elif time < float(timing.extension):
			var phase := smoothstep(float(timing.windup), float(timing.extension), time)
			grip = _point("wind").lerp(_point("impact"), phase)
			angle = lerpf(float(tuning.angles[1]), float(tuning.angles[2]), phase)
			lean = lerpf(float(tuning.wind_lean), float(tuning.swing_lean), phase)
		elif time < float(timing.hold):
			var phase := smoothstep(float(timing.extension), float(timing.hold), time)
			grip = _point("impact").lerp(_point("follow"), phase)
			angle = lerpf(float(tuning.angles[2]), float(tuning.angles[3]), phase)
			lean = float(tuning.swing_lean)
		else:
			var phase := smoothstep(float(timing.hold), float(timing.duration), time)
			grip = _point("follow").lerp(grip, phase)
			angle = lerpf(float(tuning.angles[3]), angle, phase)
			lean = float(tuning.swing_lean) * (1.0 - phase)
	rig.bones.body.rotation += lean
	rig.bones.head.rotation -= lean * 0.83
	rig.melee_angle = angle
	var origin: Vector2 = rig.bones.hips.position + rig.bones.body.position
	var axis := Vector2.RIGHT.rotated(angle)
	var at := origin + grip
	_arm(rig, "near", at, angle)
	var handle: Vector2 = rig.bones.near_hand.to_global(Vector2(0, 7))
	_arm(rig, "far", rig.to_local(handle) + axis * float(tuning.hand_spacing), angle)


func _point(id: String) -> Vector2:
	return Vector2(tuning[id][0], tuning[id][1])


func _arm(rig: Node2D, side: String, target: Vector2, angle: float) -> void:
	var body: Bone2D = rig.bones.body
	var hand: Bone2D = rig.bones[side + "_hand"]
	var wrist_angle := angle
	for pass_index in range(3):
		var wrist := target - Vector2(0, 7).rotated(wrist_angle)
		ArmIK.solve(
			rig.bones,
			side,
			body.to_local(rig.to_global(wrist)),
			-1.0,
			angle,
			float(tuning.wrist_limit)
		)
		wrist_angle = rig.bones.body.rotation + rig.bones[side + "_arm"].rotation
		wrist_angle += rig.bones[side + "_fore"].rotation + hand.rotation
