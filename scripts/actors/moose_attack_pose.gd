extends RefCounted

const Sequence = preload("res://scripts/core/attack_sequence.gd")

var _serial: int = -1
var _last_pose: Dictionary = {}
var _entry_pose: Dictionary = {}


func apply(rig: Node2D) -> void:
	var attack: Sequence = rig.combat
	if attack.serial != _serial:
		_serial = attack.serial
		_entry_pose = _last_pose.duplicate()
	if attack.elapsed >= 0:
		if attack.kind == "kick":
			_kick(rig)
		else:
			_punch(rig)
		var blend := smoothstep(0, float(attack.tuning.blend_in), attack.elapsed)
		for id: String in _entry_pose:
			rig.bones[id].rotation = lerp_angle(_entry_pose[id], rig.bones[id].rotation, blend)
	for id: String in rig.bones:
		_last_pose[id] = rig.bones[id].rotation


func _punch(rig: Node2D) -> void:
	var attack: Sequence = rig.combat
	var shape: Vector2 = attack.envelope()
	var side: String = attack.side
	var other := "far" if side == "near" else "near"
	var arm := lerpf(0.32, 0.85, shape.y)
	var fore := lerpf(-1.55, -2.10, shape.y)
	var extension := -1.08 if attack.in_air else -1.49
	if attack.low:
		extension = -1.35
	arm = lerpf(arm, extension - rig.bones.body.rotation, shape.x)
	fore = lerpf(fore, 0.08 if side == "near" else -0.05, shape.x)
	var weight := 1.0 - attack.recovery()
	_blend_bone(rig, side + "_arm", arm, weight)
	_blend_bone(rig, side + "_fore", fore, weight)
	_blend_bone(rig, other + "_arm", -0.05, shape.x * 0.75)
	_blend_bone(rig, other + "_fore", -2.05, shape.x * 0.75)
	if attack.in_air:
		_blend_bone(rig, "near_thigh", -0.65, shape.x * 0.55)
		_blend_bone(rig, "near_shin", 1.7, shape.x * 0.55)
		var ankle: float = -rig.bones.near_thigh.rotation - rig.bones.near_shin.rotation
		_blend_bone(rig, "near_foot", ankle + float(rig.motion.air_front_toe), shape.x * 0.55)


func _kick(rig: Node2D) -> void:
	var attack: Sequence = rig.combat
	var shape: Vector2 = attack.envelope()
	var weight := 1.0 - attack.recovery()
	var side: String = attack.side
	var other := "far" if side == "near" else "near"
	# Chamber the knee first; the fast extension carries the shoe through the target.
	var thigh := lerpf(-0.55, -1.6, shape.y)
	var shin := lerpf(1.2, 2.35, shape.y)
	var extension := -1.62 if attack.in_air else (-1.20 if attack.low else -1.35)
	if attack.kick_step == 1:
		extension += 0.17
	elif attack.kick_step == 2:
		extension = (
			extension - 0.12
			if attack.low or attack.in_air
			else float(attack.tuning.kick_body.high_thigh)
		)
	thigh = lerpf(thigh, extension, shape.x)
	shin = lerpf(shin, 0.20 if attack.low else 0.16, shape.x)
	var toe := -0.14
	if attack.kick_step == 2 and not attack.low and not attack.in_air:
		toe = float(attack.tuning.kick_body.high_toe)
	_blend_bone(rig, side + "_thigh", thigh, weight)
	_blend_bone(rig, side + "_shin", shin, weight)
	_blend_bone(rig, side + "_foot", -thigh - shin + toe, weight)
	var balance := maxf(shape.x, shape.y * 0.6)
	_blend_bone(rig, side + "_arm", 0.9, balance)
	_blend_bone(rig, side + "_fore", -1.6, balance)
	_blend_bone(rig, other + "_arm", -0.3, balance)
	_blend_bone(rig, other + "_fore", -2.0, balance)
	if attack.in_air:
		_blend_bone(rig, other + "_thigh", 0.35, weight)
		_blend_bone(rig, other + "_shin", 1.65, weight)
		var ankle: float = -rig.bones[other + "_thigh"].rotation
		ankle -= rig.bones[other + "_shin"].rotation
		_blend_bone(rig, other + "_foot", ankle + float(rig.motion.air_rear_toe), weight)


func _blend_bone(rig: Node2D, id: String, angle: float, weight: float) -> void:
	rig.bones[id].rotation = lerp_angle(rig.bones[id].rotation, angle, weight)
