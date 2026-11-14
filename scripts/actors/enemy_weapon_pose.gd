extends RefCounted

const ArmIK = preload("res://scripts/core/arm_ik.gd")
var tuning: Dictionary = JSON.parse_string(
	FileAccess.get_file_as_string("res://data/enemy_weapon_pose.json")
)


func apply(rig: Node2D) -> void:
	if rig.kind not in ["fox", "lynx", "firewall", "foreman", "beaver", "hare"]:
		return
	var origin: Vector2 = rig.bones.hips.position + rig.bones.body.position
	rig.arm_meshes.far.z_index = 15 if rig.kind in ["fox", "lynx", "firewall", "foreman"] else 5
	if rig.kind in ["fox", "lynx", "firewall"]:
		var hold: Array = tuning.gun_grip_by_kind.get(rig.kind, tuning.gun_grip)
		var grip := Vector2(hold[0], hold[1]) + Vector2(rig.recoil * 2, 0)
		var support: Array = tuning.gun_support_by_kind.get(rig.kind, tuning.gun_support)
		_arm(rig, "near", origin + grip)
		_arm(rig, "far", origin + grip + Vector2(support[0], support[1]))
		rig.bones.weapon.rotation = rig._grip_rotation("near") - rig.recoil * 0.08
		return
	var heavy: bool = rig.kind in ["foreman", "beaver"]
	var prefix := "heavy_" if heavy else "light_"
	var wind: Array = tuning.wind_by_kind.get(rig.kind, tuning[prefix + "wind"])
	var grip := _point(prefix + "rest").lerp(Vector2(wind[0], wind[1]), rig.wind)
	grip = grip.lerp(_point(prefix + "strike"), rig.strike)
	var angle: float = rig.wind * 0.8 - rig.strike * (1.4 if heavy else 1.1)
	_arm(rig, "near", origin + grip, PI / 2 + angle)
	if rig.kind == "foreman":
		_arm(rig, "far", origin + grip + Vector2(0, -11).rotated(rig.wind * 0.8 - rig.strike * 1.4))
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
