extends RefCounted
## Both wrists solve toward actual grip points; sleeves use the existing bones.

const ArmIK = preload("res://scripts/core/arm_ik.gd")

var tuning: Dictionary = JSON.parse_string(
	FileAccess.get_file_as_string("res://data/firearm_pose.json")
)
var _far_parts: Array[Sprite2D] = []
var _armed: bool = false


func apply(rig: Node2D) -> void:
	var armed: bool = not rig.held_firearm.is_empty() or rig.held_melee == "bat"
	if _far_parts.is_empty():
		for id: String in ["far_arm", "far_fore", "far_hand"]:
			for child: Node in rig.bones[id].get_children():
				if child is Sprite2D:
					_far_parts.append(child)
	if armed != _armed:
		_armed = armed
		for index in range(_far_parts.size()):
			_far_parts[index].z_index = 17 + index if armed else 5 + index
	if rig.held_firearm.is_empty() or rig.blocking or rig.power_pose.length_squared() > 0.001:
		return
	if rig.strike >= 0 and rig.combat.kind == "kick":
		return
	var spec: Dictionary = tuning[rig.held_firearm]
	var grip: Array = tuning.reload_grip if rig.firearm_reloading else spec.grip
	var support: Array = tuning.reload_support if rig.firearm_reloading else spec.support
	var origin: Vector2 = rig.bones.hips.position + rig.bones.body.position
	var at := origin + Vector2(grip[0], grip[1])
	at.x -= rig.firearm_recoil * float(spec.recoil)
	rig.firearm_angle = (
		float(tuning.reload_angle)
		if rig.firearm_reloading
		else rig.firearm_recoil * float(tuning.recoil_angle)
	)
	var hand_angle: float = -PI / 2 + (0.0 if rig.firearm_reloading else rig.firearm_angle)
	_arm(rig, "near", at - Vector2(0, 7).rotated(hand_angle), hand_angle)
	var handle: Vector2 = rig.to_local(rig.bones.near_hand.to_global(Vector2(0, 7)))
	var support_at := Vector2(support[0], support[1])
	if not rig.firearm_reloading:
		support_at = support_at.rotated(rig.firearm_angle)
	_arm(rig, "far", handle + support_at - Vector2(0, 9).rotated(hand_angle), hand_angle)


func _arm(rig: Node2D, side: String, target: Vector2, hand_angle: float) -> void:
	var body: Bone2D = rig.bones.body
	ArmIK.solve(rig.bones, side, body.to_local(rig.to_global(target)), -1.0, hand_angle)
