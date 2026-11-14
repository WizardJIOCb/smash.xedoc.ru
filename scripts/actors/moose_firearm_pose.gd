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
	_arm(rig, "near", at - Vector2(7, 0))
	_arm(rig, "far", at + Vector2(support[0], support[1]) - Vector2(7, 0))


func _arm(rig: Node2D, side: String, target: Vector2) -> void:
	var body: Bone2D = rig.bones.body
	ArmIK.solve(rig.bones, side, body.to_local(rig.to_global(target)), -1.0, -PI / 2)
