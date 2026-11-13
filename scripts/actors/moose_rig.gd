extends Node2D
## Painted cutout parts attached to a native Skeleton2D hierarchy.
## Feet use two-bone IK; pose values are angles in radians, down is zero.

const RigMath = preload("res://scripts/core/rig_math.gd")
const TorsoSkin = preload("res://scripts/actors/torso_skin.gd")
const PantLegSkin = preload("res://scripts/actors/pant_leg_skin.gd")

# Camera-side anatomy stays consistent when the whole rig is mirrored.
const DEPTH_FAR_LEG = 0
const DEPTH_NEAR_LEG = 2
const DEPTH_FAR_ARM = 5
const DEPTH_NECK = 8
const DEPTH_NEAR_ARM = 20
const DEPTH_HEAD = 16

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
var horizontal_speed: float = 0.0
var horizontal_acceleration: float = 0.0
var vertical_speed: float = 0.0
var preparation: float = 0.0
var motion: Dictionary
var landing_time: float = 1.0
var landing_strength: float = 0.0
var mesh: Polygon2D
var leg_meshes: Dictionary = {}
var gaze_material: ShaderMaterial
var camera_glance: bool = false
var glance_count: int = 0

var _travel_blend: float = 0.0
var _air_blend: float = 0.0
var _body_spring := Vector2.ZERO
var _head_spring := Vector2.ZERO
var _hip_spring := Vector2(-80, 0)
var _previous_x: float = 0.0
var _previous_facing: float = 1.0
var _foot_world: Dictionary = {}
var _was_support: Dictionary = {}
var _foot_local: Dictionary = {}
var _idle_time: float = 0.0
var _next_glance: float = 4.5
var _glance_left: float = 0.0
var _forward_gaze: float = 1.0


func _ready() -> void:
	motion = JSON.parse_string(FileAccess.get_file_as_string("res://data/rig_motion.json"))
	_previous_x = position.x
	skeleton = Skeleton2D.new()
	add_child(skeleton)
	_bone("hips", skeleton, Vector2(0, -80), 12)
	_bone("body", bones.hips, Vector2(0, -9), 65)
	var neck := _part("neck", bones.body, Vector2(27, 43), Vector2(0.5, 0.18), DEPTH_NECK)
	neck.position += Vector2(12, -58)
	_bone("head", bones.body, Vector2(13, -64), 25)
	var head := _part("head", bones.head, Vector2(141, 100), Vector2(0.48, 0.9), DEPTH_HEAD)
	gaze_material = ShaderMaterial.new()
	gaze_material.shader = load("res://assets/shaders/moose_gaze.gdshader")
	gaze_material.set_shader_parameter(
		"near_eye", load("res://assets/characters/los/eye_near_forward.png")
	)
	gaze_material.set_shader_parameter(
		"far_eye", load("res://assets/characters/los/eye_far_forward.png")
	)
	head.material = gaze_material
	for side: String in ["far", "near"]:
		var near_side := side == "near"
		var depth := DEPTH_NEAR_LEG if near_side else DEPTH_FAR_LEG
		var arm_depth := DEPTH_NEAR_ARM if near_side else DEPTH_FAR_ARM
		var shade := Color.WHITE if near_side else Color(0.78, 0.83, 0.85)
		_bone(side + "_thigh", bones.hips, Vector2(-8 if near_side else 8, 5), 38)
		_bone(side + "_shin", bones[side + "_thigh"], Vector2(0, 38), 38)
		_bone(side + "_foot", bones[side + "_shin"], Vector2(0, 38), 20)
		_part("shoe", bones[side + "_foot"], Vector2(48, 27), Vector2(0.3, 0.4), depth + 1, shade)
		_bone(side + "_arm", bones.body, Vector2(-19 if near_side else 18, -54), 31)
		_bone(side + "_fore", bones[side + "_arm"], Vector2(0, 31), 30)
		_bone(side + "_hand", bones[side + "_fore"], Vector2(0, 30), 16)
		_segment(
			"upper_arm",
			bones[side + "_arm"],
			Vector2(0.61, 0.16),
			Vector2(0.43, 0.9),
			31,
			arm_depth,
			shade
		)
		_segment(
			"forearm",
			bones[side + "_fore"],
			Vector2(0.22, 0.18),
			Vector2(0.86, 0.68),
			30,
			arm_depth + 1,
			shade
		)
		if near_side:
			_segment(
				"fist_back",
				bones.near_hand,
				Vector2(0.15, 0.8),
				Vector2(0.78, 0.27),
				18,
				arm_depth + 2,
				shade
			)
		else:
			_segment(
				"fist",
				bones.far_hand,
				Vector2(0.17, 0.73),
				Vector2(0.8, 0.4),
				18,
				arm_depth + 2,
				shade
			)
	for bone: Bone2D in bones.values():
		bone.rest = bone.transform
	mesh = TorsoSkin.new()
	mesh.setup(skeleton, bones.hips, bones.body)
	for side: String in ["far", "near"]:
		var trousers := PantLegSkin.new()
		trousers.setup(skeleton, bones, side, DEPTH_NEAR_LEG if side == "near" else DEPTH_FAR_LEG)
		leg_meshes[side] = trousers
	_reset_feet()
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
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = id
	sprite.texture = load("res://assets/characters/los/%s.png" % id)
	sprite.centered = false
	sprite.scale = size / sprite.texture.get_size()
	sprite.position = -size * pivot
	sprite.z_index = depth
	sprite.z_as_relative = false
	sprite.modulate = shade
	parent.add_child(sprite)
	return sprite


func _segment(
	id: String, parent: Node, start: Vector2, end: Vector2, length: float, depth: int, shade: Color
) -> void:
	var sprite := Sprite2D.new()
	sprite.name = id
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
	_update_gaze(delta)
	landing_time += delta
	var displacement := position.x - _previous_x
	_previous_x = position.x
	if facing != _previous_facing:
		_reset_feet()
		_previous_facing = facing
	scale.x = facing
	_travel_blend = lerpf(_travel_blend, travel, 1.0 - exp(-delta * 13))
	_air_blend = lerpf(_air_blend, float(airborne), 1.0 - exp(-delta * 20))
	var cycle_distance := float(motion.stride_half) * 2.0 / float(motion.stance_ratio)
	if not airborne:
		gait += absf(displacement) / cycle_distance * TAU
	var attack := _attack_shape(delta)
	var compression := landing_strength * sin(minf(landing_time / 0.24, 1.0) * PI)
	compression *= exp(-landing_time * 2.5)
	var breath := sin(clock * 2.4) * 0.8 * (1.0 - _travel_blend)
	var bob := (1.0 - cos(gait * 2.0)) * 1.35 * _travel_blend
	var hip_target := -80.0 + breath + bob + preparation * 12.0 + compression * 14.0
	_hip_spring = RigMath.spring(_hip_spring, hip_target, 420, 33, delta)
	bones.hips.position = Vector2(attack.x * 5.0, _hip_spring.x)
	var acceleration_lean := clampf(horizontal_acceleration * facing / 1600.0, -1, 1) * 0.13
	var body_target := 0.035 + _travel_blend * 0.14 + acceleration_lean
	body_target += attack.x * 0.22 - attack.y * 0.12 + preparation * 0.11
	body_target += compression * 0.1 - clampf(vertical_speed / 600.0, -1, 1) * 0.06
	_body_spring = RigMath.spring(
		_body_spring, body_target, float(motion.body_stiffness), float(motion.body_damping), delta
	)
	bones.body.rotation = _body_spring.x
	var head_target: float = -bones.body.rotation * 0.83 + sin(clock * 2.4 - 0.5) * 0.017
	_head_spring = RigMath.spring(
		_head_spring, head_target, float(motion.head_stiffness), float(motion.head_damping), delta
	)
	bones.head.rotation = _head_spring.x
	for side: String in ["far", "near"]:
		_pose_leg(side, delta)
		var phase := gait + (PI if side == "far" else 0.0)
		var swing := cos(phase) * 0.62 * _travel_blend
		bones[side + "_arm"].rotation = 0.32 + swing - bones.body.rotation
		bones[side + "_fore"].rotation = -1.55 - absf(swing) * 0.25 - _air_blend * 0.18
		bones[side + "_hand"].rotation = 0.0
	if strike >= 0.0:
		var recovery := smoothstep(float(motion.attack_hold), float(motion.attack_duration), strike)
		var arm := lerpf(0.32, 0.82, attack.y)
		var fore := lerpf(-1.55, -2.05, attack.y)
		arm = lerpf(arm, -1.49 - bones.body.rotation, attack.x)
		fore = lerpf(fore, 0.035, attack.x)
		bones.near_arm.rotation = lerpf(arm, bones.near_arm.rotation, recovery)
		bones.near_fore.rotation = lerpf(fore, bones.near_fore.rotation, recovery)
		bones.near_hand.rotation = 0.0
	debug_layer.queue_redraw()


func _update_gaze(delta: float) -> void:
	var active := absf(horizontal_speed) > 8 or airborne or strike >= 0 or preparation > 0
	if active:
		_idle_time = 0
		_glance_left = 0
	else:
		_idle_time += delta
		_glance_left = maxf(0, _glance_left - delta)
		if _idle_time >= _next_glance:
			_glance_left = 0.75
			_idle_time = 0
			glance_count += 1
			_next_glance = 8.0 + fmod(glance_count * 2.3, 4.0)
			Metrics.record("camera_glance")
	camera_glance = _glance_left > 0
	_forward_gaze = move_toward(_forward_gaze, 0.0 if camera_glance else 1.0, delta * 10)
	gaze_material.set_shader_parameter("forward_gaze", _forward_gaze)


func _attack_shape(delta: float) -> Vector2:
	if strike < 0:
		return Vector2.ZERO
	strike += delta
	if strike >= float(motion.attack_duration):
		strike = -1.0
		return Vector2.ZERO
	var wind := smoothstep(0, float(motion.attack_windup), strike)
	var extend := smoothstep(float(motion.attack_windup), float(motion.attack_extension), strike)
	var recover := smoothstep(float(motion.attack_hold), float(motion.attack_duration), strike)
	return Vector2(extend * (1.0 - recover), wind * (1.0 - extend))


func land(impact: float) -> void:
	landing_time = 0.0
	landing_strength = clampf(impact / float(motion.jump_speed), 0.25, 1.0)
	_hip_spring.y += landing_strength * 55.0
	_reset_feet()


func _reset_feet() -> void:
	gait = TAU * 0.18
	for side: String in ["far", "near"]:
		var hip_x: float = bones[side + "_thigh"].position.x
		var rest := 19.0 if side == "near" else -19.0
		_foot_world[side] = position.x + facing * (hip_x + rest)
		var cycle := fposmod(gait + (PI if side == "far" else 0.0), TAU) / TAU
		_was_support[side] = cycle < float(motion.stance_ratio)
		_foot_local[side] = Vector2(hip_x + rest, -6)


func _pose_leg(side: String, delta: float) -> void:
	var cycle := fposmod(gait + (PI if side == "far" else 0.0), TAU) / TAU
	var stance := float(motion.stance_ratio)
	var hip_x: float = bones[side + "_thigh"].position.x
	var stride := float(motion.stride_half)
	var moving := absf(horizontal_speed) > 8.0
	var supporting := cycle < stance and moving and not airborne
	var target := Vector2(hip_x + (19 if side == "near" else -19), -6)
	var foot_angle := 0.0
	if moving:
		if supporting:
			if not _was_support[side]:
				_foot_world[side] = position.x + facing * (hip_x + stride)
			target.x = (float(_foot_world[side]) - position.x) * facing
		else:
			var swing := clampf((cycle - stance) / (1.0 - stance), 0, 1)
			target.x = hip_x + lerpf(-stride, stride, smoothstep(0, 1, swing))
			target.y -= sin(swing * PI) * float(motion.foot_clearance)
			foot_angle = sin(swing * PI) * 0.22
	else:
		# Settle a stopped stride into the guard stance rather than snapping.
		target = _foot_local[side].lerp(target, 1.0 - exp(-delta * 12))
	_was_support[side] = supporting
	var relative: Vector2 = target - bones.hips.position - bones[side + "_thigh"].position
	var air_target := Vector2(
		25 if side == "near" else -20, 46 + clampf(vertical_speed / 80, -5, 6)
	)
	relative = relative.lerp(air_target, _air_blend)
	_foot_local[side] = relative + bones.hips.position + bones[side + "_thigh"].position
	var angles := RigMath.leg_angles(relative)
	bones[side + "_thigh"].rotation = angles.x
	bones[side + "_shin"].rotation = angles.y
	bones[side + "_foot"].rotation = -angles.x - angles.y + foot_angle * (1 - _air_blend)


func _draw_skeleton() -> void:
	if not show_bones:
		return
	for bone: Bone2D in bones.values():
		var start := to_local(bone.global_position)
		var end := to_local(bone.to_global(Vector2(0, bone.length)))
		debug_layer.draw_line(start, end, Color(0.3, 1.0, 0.9, 0.8), 1.4, true)
		debug_layer.draw_circle(start, 2, Color.WHITE)
