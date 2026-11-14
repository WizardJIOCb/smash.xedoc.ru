extends RefCounted

const ArmIK = preload("res://scripts/core/arm_ik.gd")
var tuning: Dictionary = JSON.parse_string(
	FileAccess.get_file_as_string("res://data/enemy_weapon_pose.json")
)


func apply(rig: Node2D) -> void:
	if not rig.pose_style.is_empty():
		_apply_profile(rig)
		return
	if rig.kind not in ["fox", "lynx", "firewall", "foreman", "beaver", "hare"]:
		return
	var origin: Vector2 = rig.bones.hips.position + rig.bones.body.position
	rig.arm_meshes.far.z_index = 15 if rig.kind in ["fox", "lynx", "firewall"] else 5
	rig.arm_meshes.far.hand_mesh.z_index = (
		17 if rig.kind == "foreman" else rig.arm_meshes.far.z_index + 2
	)
	if rig.kind in ["fox", "lynx", "firewall"]:
		var hold: Array = tuning.gun_grip_by_kind.get(rig.kind, tuning.gun_grip)
		var grip := Vector2(hold[0], hold[1]) + Vector2(rig.recoil * 2, 0)
		var support: Array = tuning.gun_support_by_kind.get(rig.kind, tuning.gun_support)
		var angle: float = -rig.recoil * 0.08
		_arm(rig, "near", origin + grip, PI / 2 + angle)
		var handle: Vector2 = rig.to_local(rig.bones.near_hand.global_position)
		_arm(rig, "far", handle + Vector2(support[0], support[1]).rotated(angle), PI / 2 + angle)
		rig.bones.weapon.rotation = rig._grip_rotation("near") + angle
		return
	var heavy: bool = rig.kind in ["foreman", "beaver"]
	var prefix := "heavy_" if heavy else "light_"
	var wind: Array = tuning.wind_by_kind.get(rig.kind, tuning[prefix + "wind"])
	var rest := _point(prefix + "rest")
	var contact := _point(prefix + "strike")
	var angles: Array = tuning[prefix + "angles"]
	if rig.kind == "foreman":
		rest = Vector2(tuning.foreman.rest[0], tuning.foreman.rest[1])
		wind = tuning.foreman.wind
		contact = Vector2(tuning.foreman.strike[0], tuning.foreman.strike[1])
		angles = tuning.foreman.angles
	var grip := rest.lerp(Vector2(wind[0], wind[1]), rig.wind)
	grip = grip.lerp(contact, rig.strike)
	var angle: float = lerpf(float(angles[0]), float(angles[1]), rig.wind)
	angle = lerpf(angle, float(angles[2]), rig.strike)
	_arm(rig, "near", origin + grip, PI / 2 + angle)
	if rig.kind == "foreman":
		var support := Vector2(tuning.foreman.support[0], tuning.foreman.support[1])
		_arm(rig, "far", origin + grip + support.rotated(angle), PI / 2 + angle)
	else:
		_arm(rig, "far", origin + _point("free_guard"))
	rig.bones.weapon.rotation = rig._grip_rotation("near") + angle


func _apply_profile(rig: Node2D) -> void:
	var profile: Dictionary = tuning.profiles[rig.pose_style]
	var custom: Dictionary = tuning.by_kind.get(rig.kind, {})
	var origin: Vector2 = rig.bones.hips.position + rig.bones.body.position
	var gun: bool = rig.pose_style == "gun"
	var both_hands: bool = profile.has("support")
	rig.arm_meshes.far.z_index = 15 if both_hands else 5
	rig.arm_meshes.far.hand_mesh.z_index = 19 if both_hands else 6
	var grip: Vector2
	var angle: float
	if gun:
		var hold: Array = custom.get("grip", profile.grip)
		grip = Vector2(hold[0], hold[1]) + Vector2(rig.recoil * 2 - rig.strike * 8, 0)
		angle = rig.aim_pitch - rig.recoil * 0.08
	else:
		var rest: Array = custom.get("rest", profile.rest)
		var wind: Array = custom.get("wind", profile.wind)
		var strike: Array = custom.get("strike", profile.strike)
		var angles: Array = custom.get("angles", profile.angles)
		grip = Vector2(rest[0], rest[1]).lerp(Vector2(wind[0], wind[1]), rig.wind)
		grip = grip.lerp(Vector2(strike[0], strike[1]), rig.strike)
		angle = lerpf(float(angles[0]), float(angles[1]), rig.wind)
		angle = lerpf(angle, float(angles[2]), rig.strike)
	_arm(rig, "near", origin + grip, PI / 2 + angle)
	if both_hands:
		var support: Array = custom.get("support", profile.support)
		var handle: Vector2 = rig.to_local(rig.bones.near_hand.global_position)
		_arm(rig, "far", handle + Vector2(support[0], support[1]).rotated(angle), PI / 2 + angle)
	else:
		_arm(rig, "far", origin + _point("free_guard"))
	rig.bones.weapon.rotation = rig._grip_rotation("near") + angle


func _point(key: String) -> Vector2:
	return Vector2(tuning[key][0], tuning[key][1])


func _arm(rig: Node2D, side: String, target: Vector2, hand_angle: float = PI / 2) -> void:
	var body: Bone2D = rig.bones.body
	ArmIK.solve(
		rig.bones,
		side,
		body.to_local(rig.to_global(target)),
		1.0,
		hand_angle,
		float(tuning.wrist_limit)
	)
