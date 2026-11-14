extends RefCounted
## Reference-led load, hip turn, barrel lag and follow-through in a projected plane.

const ArmIK = preload("res://scripts/core/arm_ik.gd")
var tuning: Dictionary = JSON.parse_string(
	FileAccess.get_file_as_string("res://data/bat_pose.json")
)
var assembly: Dictionary = (
	JSON.parse_string(FileAccess.get_file_as_string("res://data/weapon_grips.json")).bat
)
var pose: Dictionary = {}


func prepare(rig: Node2D) -> float:
	pose = tuning.rest.duplicate(true)
	rig.bones.far_arm.position.x = 18
	if rig.held_melee != "bat":
		return 0.0
	if rig.blocking:
		pose = tuning.guard
	elif rig.combat.elapsed >= 0 and rig.combat.kind == "punch":
		var timing: Dictionary = rig.combat.timings()
		var time: float = rig.combat.elapsed
		var drive: float = lerpf(
			float(timing.windup), float(timing.extension), float(tuning.drive_at)
		)
		var follow: float = lerpf(
			float(timing.hold), float(timing.duration), float(tuning.follow_at)
		)
		var finish: float = lerpf(
			float(timing.hold), float(timing.duration), float(tuning.finish_at)
		)
		if time < float(timing.windup):
			pose = _blend("rest", "load", smoothstep(0, float(timing.windup), time))
		elif time < drive:
			pose = _blend("load", "drive", smoothstep(float(timing.windup), drive, time))
		elif time < float(timing.extension):
			pose = _blend("drive", "contact", smoothstep(drive, float(timing.extension), time))
		elif time < float(timing.hold):
			pose = _blend(
				"contact",
				"follow",
				smoothstep(float(timing.extension), float(timing.hold), time) * 0.35
			)
		elif time < follow:
			pose = _blend(
				"contact", "follow", lerpf(0.35, 1.0, smoothstep(float(timing.hold), follow, time))
			)
		elif time < finish:
			pose = _blend("follow", "finish", smoothstep(follow, finish, time))
		else:
			pose = _blend("finish", "rest", smoothstep(finish, float(timing.duration), time))
	rig.bones.far_arm.position.x = float(pose.shoulder)
	return float(pose.weight)


func apply(rig: Node2D) -> void:
	rig.bat_grip_active = rig.held_melee == "bat" and not rig.ragdoll_active
	rig.bones.near_hand.get_node("fist_back").visible = not rig.bat_grip_active
	rig.bones.far_hand.get_node("fist").visible = not rig.bat_grip_active
	if not rig.bat_grip_active:
		return
	var lean: float = pose.lean
	rig.bones.body.rotation += lean
	rig.bones.head.rotation -= lean * 0.83
	var yaw: float = pose.yaw
	var pitch: float = pose.pitch
	var projected := Vector2(
		cos(yaw) * cos(pitch), -sin(pitch) - sin(yaw) * cos(pitch) * float(tuning.depth_slope)
	)
	var angle := projected.angle()
	rig.melee_angle = angle
	rig.melee_length = maxf(float(tuning.min_projection), projected.length())
	var origin: Vector2 = rig.bones.hips.position + rig.bones.body.position
	var at := origin + Vector2(pose.grip[0], pose.grip[1])
	rig.melee_origin = at
	for side: String in ["near", "far"]:
		var wrist: Array = assembly[side + "_wrist"]
		var pivot: Array = assembly.pivot
		var offset := Vector2(wrist[0] - pivot[0], wrist[1] - pivot[1]) * float(assembly.scale)
		_arm(rig, side, at + offset.rotated(angle), angle)


func _blend(from: String, to: String, amount: float) -> Dictionary:
	var result := {}
	for key: String in ["yaw", "pitch", "lean", "weight", "shoulder"]:
		result[key] = lerpf(float(tuning[from][key]), float(tuning[to][key]), amount)
	result.grip = [
		lerpf(tuning[from].grip[0], tuning[to].grip[0], amount),
		lerpf(tuning[from].grip[1], tuning[to].grip[1], amount)
	]
	return result


func _arm(rig: Node2D, side: String, target: Vector2, angle: float) -> void:
	var body: Bone2D = rig.bones.body
	ArmIK.solve(
		rig.bones,
		side,
		body.to_local(rig.to_global(target)),
		float(tuning[side + "_bend"]),
		angle,
		float(tuning.wrist_limit)
	)
