extends Node2D
## Painted cutout parts attached to a native Skeleton2D hierarchy.
## Feet use two-bone IK; pose values are angles in radians, down is zero.

var skeleton: Skeleton2D
var debug_layer: Node2D
var bones: Dictionary = {}
var clock: float = 0.0
var gait: float = 0.0
var travel: float = 0.0
var airborne: bool = false
var strike: float = -1.0
var facing: float = 1.0
var show_bones: bool = false


func _ready() -> void:
	skeleton = Skeleton2D.new()
	add_child(skeleton)
	_bone("hips", skeleton, Vector2(0, -80), 12)
	_bone("body", bones.hips, Vector2(0, -9), 65)
	_part("pelvis", bones.hips, Vector2(54, 32), Vector2(0.5, 0.23), 2)
	_part("torso", bones.body, Vector2(80, 74), Vector2(0.5, 0.88), 4)
	_bone("head", bones.body, Vector2(13, -64), 25)
	_part("head", bones.head, Vector2(141, 100), Vector2(0.48, 0.9), 8)
	for side: String in ["far", "near"]:
		var near_side := side == "near"
		var depth := 6 if near_side else 0
		var shade := Color.WHITE if near_side else Color(0.65, 0.73, 0.77)
		_bone(side + "_thigh", bones.hips, Vector2(9 if near_side else -14, 5), 38)
		_bone(side + "_shin", bones[side + "_thigh"], Vector2(0, 38), 38)
		_bone(side + "_foot", bones[side + "_shin"], Vector2(0, 38), 20)
		_segment(
			"thigh",
			bones[side + "_thigh"],
			Vector2(0.43, 0.12),
			Vector2(0.62, 0.88),
			38,
			depth,
			shade
		)
		_segment(
			"shin", bones[side + "_shin"], Vector2(0.53, 0.1), Vector2(0.48, 0.91), 38, depth, shade
		)
		_part("shoe", bones[side + "_foot"], Vector2(48, 27), Vector2(0.3, 0.4), depth + 1, shade)
		_bone(side + "_arm", bones.body, Vector2(23 if near_side else -24, -54), 31)
		_bone(side + "_fore", bones[side + "_arm"], Vector2(0, 31), 30)
		_bone(side + "_hand", bones[side + "_fore"], Vector2(0, 30), 16)
		_segment(
			"upper_arm",
			bones[side + "_arm"],
			Vector2(0.61, 0.16),
			Vector2(0.43, 0.9),
			31,
			depth + 1,
			shade
		)
		_segment(
			"forearm",
			bones[side + "_fore"],
			Vector2(0.22, 0.18),
			Vector2(0.86, 0.68),
			30,
			depth + 1,
			shade
		)
		_part("fist", bones[side + "_hand"], Vector2(23, 28), Vector2(0.47, 0.2), depth + 2, shade)
	for bone: Bone2D in bones.values():
		bone.rest = bone.transform
	debug_layer = Node2D.new()
	debug_layer.z_index = 50
	debug_layer.draw.connect(_draw_skeleton)
	add_child(debug_layer)


func _bone(id: String, parent: Node, at: Vector2, length: float) -> void:
	var bone := Bone2D.new()
	bone.name = id
	bone.position = at
	bone.set_autocalculate_length_and_angle(false)
	bone.length = length
	bone.bone_angle = PI / 2.0
	parent.add_child(bone)
	bones[id] = bone


func _part(
	id: String, parent: Node, size: Vector2, pivot: Vector2, depth: int, shade: Color = Color.WHITE
) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/characters/los/%s.png" % id)
	sprite.centered = false
	sprite.scale = size / sprite.texture.get_size()
	sprite.position = -size * pivot
	sprite.z_index = depth
	sprite.z_as_relative = false
	sprite.modulate = shade
	parent.add_child(sprite)


func _segment(
	id: String, parent: Node, start: Vector2, end: Vector2, length: float, depth: int, shade: Color
) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/characters/los/%s.png" % id)
	var size := sprite.texture.get_size()
	var axis := (end - start) * size
	var factor := length / axis.length()
	sprite.centered = false
	sprite.scale = Vector2.ONE * factor
	sprite.rotation = PI / 2.0 - axis.angle()
	sprite.position = (-start * size * factor).rotated(sprite.rotation)
	sprite.z_index = depth
	sprite.z_as_relative = false
	sprite.modulate = shade
	parent.add_child(sprite)


func _process(delta: float) -> void:
	clock += delta
	gait += delta * lerpf(3.0, 11.5, travel)
	var bounce := sin(gait * 2.0) * 2.5 * travel
	var breath := sin(clock * 2.4)
	bones.hips.position.y = -80.0 + bounce + breath * (1.0 - travel)
	bones.body.rotation = -0.08 - travel * 0.13 + sin(gait) * travel * 0.025
	bones.head.rotation = -bones.body.rotation * 0.7 + sin(clock * 2.4 - 0.4) * 0.025
	scale.x = facing
	for side: String in ["far", "near"]:
		var phase := gait + (PI if side == "far" else 0.0)
		var cycle := fposmod(phase, TAU) / TAU
		var foot_x := (
			lerpf(29, -29, cycle * 2) if cycle < 0.5 else lerpf(-29, 29, (cycle - 0.5) * 2)
		)
		var rest_x := 9.0 if side == "near" else -8.0
		var target := Vector2(lerpf(rest_x, foot_x, travel), 69.0 - bounce)
		if cycle > 0.5:
			target.y -= sin((cycle - 0.5) * TAU) * 22.0 * travel
		if airborne:
			target = Vector2(24 if side == "near" else -17, 48)
		_leg(side, target)
		var swing := cos(phase) * 0.7 * travel
		bones[side + "_arm"].rotation = 0.25 + swing
		bones[side + "_fore"].rotation = -1.1 - absf(swing) * 0.4
		bones[side + "_hand"].rotation = -0.3
	if strike >= 0.0:
		strike += delta
		var wind := smoothstep(0.0, 0.13, strike)
		var release := smoothstep(0.13, 0.21, strike)
		var recover := smoothstep(0.28, 0.55, strike)
		var punch := release * (1.0 - recover)
		bones.body.rotation += 0.18 * wind * (1.0 - release) - punch * 0.28
		var arm_pose := lerpf(0.6 * wind, -1.0, punch)
		bones.near_arm.rotation = lerpf(arm_pose, bones.near_arm.rotation, recover)
		bones.near_fore.rotation = lerpf(lerpf(-1.8, -0.12, punch), -1.1, recover)
		bones.near_hand.rotation = -0.2
		bones.head.rotation += punch * 0.1
		if strike > 0.55:
			strike = -1.0
	debug_layer.queue_redraw()


func _leg(side: String, target: Vector2) -> void:
	var distance := clampf(target.length(), 4, 75.8)
	var first := atan2(-target.x, target.y) - acos(distance / 76.0)
	var second := PI - acos(clampf((2888.0 - distance * distance) / 2888.0, -1, 1))
	bones[side + "_thigh"].rotation = first
	bones[side + "_shin"].rotation = second
	bones[side + "_foot"].rotation = -first - second


func _draw_skeleton() -> void:
	if not show_bones:
		return
	for bone: Bone2D in bones.values():
		var start := to_local(bone.global_position)
		var end := to_local(bone.to_global(Vector2(0, bone.length)))
		debug_layer.draw_line(start, end, Color(0.3, 1.0, 0.9, 0.8), 1.4, true)
		debug_layer.draw_circle(start, 2, Color.WHITE)
