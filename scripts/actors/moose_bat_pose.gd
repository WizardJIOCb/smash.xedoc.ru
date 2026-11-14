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
var _entry_pose: Dictionary = {}
var _serial: int = -1
var _was_held: bool = false
var _support_art_rest: Dictionary = {}


func prepare(rig: Node2D) -> float:
	var previous: Dictionary = pose if _was_held and not pose.is_empty() else tuning.rest
	pose = tuning.rest.duplicate(true)
	_was_held = rig.held_melee == "bat"
	if rig.held_melee != "bat":
		_serial = -1
		return 0.0
	if rig.blocking:
		pose = tuning.guard
	elif rig.combat.elapsed >= 0 and rig.combat.kind == "punch":
		if _serial != rig.combat.serial:
			_serial = rig.combat.serial
			_entry_pose = previous.duplicate(true)
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
			pose = _blend_pose(_entry_pose, tuning.load, smoothstep(0, float(timing.windup), time))
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
	return float(pose.weight)


func set_grip(rig: Node2D, active: bool) -> void:
	rig.bat_grip_active = active
	rig.bones.near_hand.get_node("fist_back").visible = not active
	rig.bones.far_hand.get_node("fist").visible = not active
	# The support arm reaches around the chest; its sleeve must clear the jacket.
	var depth: int = rig.DEPTH_HEAD - 3 if active else rig.DEPTH_FAR_ARM
	rig.bones.far_arm.get_node("upper_arm_inner").z_index = depth
	rig.bones.far_fore.get_node("forearm_inner").z_index = depth + 1
	if _support_art_rest.is_empty():
		_support_art_rest.upper = rig.bones.far_arm.get_node("upper_arm_inner").transform
		_support_art_rest.lower = rig.bones.far_fore.get_node("forearm_inner").transform
	if not active:
		rig.bones.far_fore.position = rig.bones.far_fore.rest.origin
		rig.bones.far_hand.position = rig.bones.far_hand.rest.origin
		rig.bones.far_arm.get_node("upper_arm_inner").transform = _support_art_rest.upper
		rig.bones.far_fore.get_node("forearm_inner").transform = _support_art_rest.lower


func apply(rig: Node2D) -> void:
	set_grip(rig, rig.held_melee == "bat" and not rig.ragdoll_active)
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
	# The shared grip must lie within BOTH arms' reach, including their minimum bend.
	var centers: Array[Vector2] = []
	for side: String in ["near", "far"]:
		var shoulder: Vector2 = rig.to_local(
			rig.bones.body.to_global(rig.bones[side + "_arm"].position)
		)
		centers.append(shoulder - _wrist_offset(side).rotated(angle))
	at = _fit_grip(at, centers)
	rig.melee_origin = at
	for side: String in ["near", "far"]:
		_arm(rig, side, at + _wrist_offset(side).rotated(angle), angle)


func _wrist_offset(side: String) -> Vector2:
	var wrist: Array = assembly[side + "_wrist"]
	return (
		Vector2(wrist[0] - assembly.pivot[0], wrist[1] - assembly.pivot[1]) * float(assembly.scale)
	)


func _fit_grip(desired: Vector2, centers: Array[Vector2]) -> Vector2:
	# The support elbow can fold through depth; only the camera-side sleeve
	# needs the large minimum screen-space reach of a planar two-bone solve.
	var radii := [
		[float(tuning.min_arm_reach), float(tuning.max_arm_reach)],
		[0.0, sqrt(pow(float(tuning.max_arm_reach), 2) - pow(float(tuning.support_depth), 2))]
	]
	if _reachable(desired, centers, radii):
		return desired
	var candidates: Array[Vector2] = []
	var span := centers[1] - centers[0]
	var distance := span.length()
	var axis := span.normalized()
	for index in range(2):
		for radius: float in radii[index]:
			var center := centers[index]
			candidates.append(center + (desired - center).normalized() * radius)
	for radius: float in radii[0]:
		for other: float in radii[1]:
			if distance < 0.001 or distance > radius + other or distance < absf(radius - other):
				continue
			var along := (distance * distance + radius * radius - other * other) / (2 * distance)
			var height := sqrt(maxf(0, radius * radius - along * along))
			var base := centers[0] + axis * along
			candidates.append(base + axis.orthogonal() * height)
			candidates.append(base - axis.orthogonal() * height)
	var best := desired
	var closest := INF
	for candidate: Vector2 in candidates:
		if _reachable(candidate, centers, radii):
			var error := candidate.distance_squared_to(desired)
			if error < closest:
				closest = error
				best = candidate
	return best


func _reachable(point: Vector2, centers: Array[Vector2], radii: Array) -> bool:
	for index in range(2):
		var distance := point.distance_to(centers[index])
		if distance < float(radii[index][0]) - 0.001 or distance > float(radii[index][1]) + 0.001:
			return false
	return true


func _blend(from: String, to: String, amount: float) -> Dictionary:
	return _blend_pose(tuning[from], tuning[to], amount)


func _blend_pose(from: Dictionary, to: Dictionary, amount: float) -> Dictionary:
	var result := {}
	result.yaw = lerp_angle(float(from.yaw), float(to.yaw), amount)
	for key: String in ["pitch", "lean", "weight"]:
		result[key] = lerpf(float(from[key]), float(to[key]), amount)
	result.grip = [lerpf(from.grip[0], to.grip[0], amount), lerpf(from.grip[1], to.grip[1], amount)]
	return result


func _arm(rig: Node2D, side: String, target: Vector2, angle: float) -> void:
	var body: Bone2D = rig.bones.body
	var local_target: Vector2 = body.to_local(rig.to_global(target))
	if side == "far":
		_support_arm(rig, local_target, angle)
		return
	ArmIK.solve(
		rig.bones,
		side,
		local_target,
		float(tuning[side + "_bend"]),
		angle,
		float(tuning.wrist_limit)
	)


func _support_arm(rig: Node2D, target: Vector2, angle: float) -> void:
	var upper: Bone2D = rig.bones.far_arm
	var lower: Bone2D = rig.bones.far_fore
	var hand: Bone2D = rig.bones.far_hand
	var reach := Vector3(
		target.x - upper.position.x, target.y - upper.position.y, float(tuning.support_depth)
	)
	var distance := reach.length()
	var axis := reach.normalized()
	var along: float = (
		(distance * distance + upper.length * upper.length - lower.length * lower.length)
		/ (2 * distance)
	)
	var radius := sqrt(maxf(0, upper.length * upper.length - along * along))
	# The far shoulder lies behind the bat plane. A downward pole on its 3D
	# elbow circle stays continuous as the hands pass in front of the chest.
	var down := Vector3(0, 1, 0)
	var pole := (down - axis * axis.y).normalized()
	var joint := axis * along + pole * radius
	var elbow: Vector2 = upper.position + Vector2(joint.x, joint.y)
	var upper_axis: Vector2 = elbow - upper.position
	var lower_axis: Vector2 = target - elbow
	upper.rotation = upper_axis.angle() - PI / 2
	lower.rotation = wrapf(lower_axis.angle() - upper_axis.angle(), -PI, PI)
	lower.position = Vector2(0, upper_axis.length())
	hand.position = Vector2(0, lower_axis.length())
	var wrist := wrapf(angle - rig.bones.body.rotation - upper.rotation - lower.rotation, -PI, PI)
	hand.rotation = clampf(wrist, -float(tuning.wrist_limit), float(tuning.wrist_limit))
	_stretch_support(rig, upper_axis.length() / upper.length, lower_axis.length() / lower.length)


func _stretch_support(rig: Node2D, upper: float, lower: float) -> void:
	var upper_stretch := Transform2D(Vector2.RIGHT, Vector2.DOWN * upper, Vector2.ZERO)
	var lower_stretch := Transform2D(Vector2.RIGHT, Vector2.DOWN * lower, Vector2.ZERO)
	rig.bones.far_arm.get_node("upper_arm_inner").transform = (
		upper_stretch * _support_art_rest.upper
	)
	rig.bones.far_fore.get_node("forearm_inner").transform = lower_stretch * _support_art_rest.lower
