extends Node2D
## Painted cutout parts attached to a native Skeleton2D hierarchy.
## Feet use two-bone IK; pose values are angles in radians, down is zero.

const RigMath = preload("res://scripts/core/rig_math.gd")
const TorsoSkin = preload("res://scripts/actors/torso_skin.gd")
const PantLegSkin = preload("res://scripts/actors/pant_leg_skin.gd")
const SleeveSkin = preload("res://scripts/actors/sleeve_skin.gd")
const AttackSequence = preload("res://scripts/core/attack_sequence.gd")
const AttackPose = preload("res://scripts/actors/moose_attack_pose.gd")
const FirearmPose = preload("res://scripts/actors/moose_firearm_pose.gd")
const BatPose = preload("res://scripts/actors/moose_bat_pose.gd")

# Camera-side anatomy stays consistent when the whole rig is mirrored.
const DEPTH_FAR_LEG = 0
const DEPTH_NEAR_LEG = 3
const DEPTH_FAR_ARM = 5
const DEPTH_NECK = 8
const DEPTH_NEAR_ARM = 20
const DEPTH_HEAD = 16
# The fluffy paw's baked highlights are brighter/warmer than the head painting.
const NEAR_FIST_TINT = Color(0.80, 0.82, 0.84)

var skeleton: Skeleton2D
var debug_layer: Node2D
var bones: Dictionary = {}
var clock: float = 0.0
var gait: float = 0.0
var travel: float = 0.0
var airborne: bool = false
var combat := AttackSequence.new()
var attack_pose := AttackPose.new()
var firearm_pose := FirearmPose.new()
var bat_pose := BatPose.new()
var held_melee: String = ""
var melee_angle: float = -1.05
var melee_origin := Vector2.ZERO
var melee_length: float = 1.0
var bat_grip_active: bool = false
var held_firearm: String = ""
var firearm_reloading: bool = false
var firearm_recoil: float = 0.0
var firearm_angle: float = 0.0
var strike: float:
	get:
		return combat.elapsed
var facing: float = 1.0
var show_bones: bool = false
var horizontal_speed: float = 0.0
var horizontal_acceleration: float = 0.0
var vertical_speed: float = 0.0
var preparation: float = 0.0
var crouch_requested: bool = false
var crouch: float = 0.0
var finishing_step: bool = false
var stop_cycle_distance: float = 0.0
var sprinting: bool = false
var motion: Dictionary
var landing_time: float = 1.0
var landing_strength: float = 0.0
var mesh: Polygon2D
var leg_meshes: Dictionary = {}
var sleeve: Polygon2D
var gaze_material: ShaderMaterial
var camera_glance: bool = false
var glance_count: int = 0
var power_scale: float = 1.0
var power_pose := Vector2.ZERO
var ragdoll_active: bool = false
var blocking: bool = false
var guard_blend: float = 0.0

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
var _sprint_blend: float = 0.0
var _was_travelling: bool = false


func _ready() -> void:
	motion = JSON.parse_string(FileAccess.get_file_as_string("res://data/rig_motion.json"))
	_previous_x = position.x
	skeleton = Skeleton2D.new()
	add_child(skeleton)
	_bone("hips", skeleton, Vector2(0, -80), 12)
	_bone("body", bones.hips, Vector2(0, -9), 65)
	var neck := _part("neck", bones.body, Vector2(27, 43), Vector2(0.5, 0.18), DEPTH_NECK)
	neck.position += Vector2(8, -53)
	_bone("head", bones.body, Vector2(9, -59), 25)
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
		# Rear collar < trouser cuff < front collar/tongue, for EACH foot.
		for piece: String in ["shoe_back", "shoe_front"]:
			var shoe_depth := depth - 1 if piece == "shoe_back" else depth + 1
			_part(
				piece, bones[side + "_foot"], Vector2(48, 27), Vector2(0.3, 0.4), shoe_depth, shade
			)
		_bone(side + "_arm", bones.body, Vector2(-19 if near_side else 18, -54), 31)
		_bone(side + "_fore", bones[side + "_arm"], Vector2(0, 31), 30)
		_bone(side + "_hand", bones[side + "_fore"], Vector2(0, 30), 16)
		if not near_side:
			_segment(
				"upper_arm_inner",
				bones.far_arm,
				Vector2(0.64, 0.14),
				Vector2(0.32, 0.89),
				31,
				arm_depth,
				shade
			)
			_segment(
				"forearm_inner",
				bones.far_fore,
				Vector2(0.22, 0.22),
				Vector2(0.87, 0.70),
				30,
				arm_depth + 1,
				shade
			)
		if near_side:
			_segment(
				"fist_back",
				bones.near_hand,
				Vector2(0.09, 0.64),
				Vector2(0.90, 0.47),
				23,
				arm_depth + 2,
				shade * NEAR_FIST_TINT
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
	sleeve = SleeveSkin.new()
	sleeve.setup(skeleton, bones, DEPTH_NEAR_ARM)
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
	if ragdoll_active:
		return
	clock += delta
	_update_gaze(delta)
	landing_time += delta
	var displacement := position.x - _previous_x
	_previous_x = position.x
	if facing != _previous_facing:
		_reset_feet()
		_previous_facing = facing
	scale = Vector2(facing, 1) * power_scale
	var low := crouch_requested or (combat.low and strike >= 0)
	crouch = lerpf(crouch, float(low and not airborne), 1.0 - exp(-delta * 14))
	var walk_cycle := float(motion.stride_half) * 2.0 / float(motion.stance_ratio)
	var finishing_run := finishing_step and stop_cycle_distance > walk_cycle * 1.05
	_sprint_blend = lerpf(
		_sprint_blend, float((sprinting or finishing_run) and not low), 1.0 - exp(-delta * 9)
	)
	_travel_blend = lerpf(_travel_blend, travel, 1.0 - exp(-delta * 13))
	_air_blend = lerpf(_air_blend, float(airborne), 1.0 - exp(-delta * 20))
	var cycle_distance := stride_cycle_distance()
	var moving := absf(horizontal_speed) > 8.0 or finishing_step
	if moving and not _was_travelling and not airborne:
		gait = PI if horizontal_speed * facing >= 0 else 0.0
		var guard_stride := absf(float(motion.guard_far_foot))
		gait += maxf(0, _stride_half() - guard_stride) / cycle_distance * TAU
		for side: String in ["near", "far"]:
			_foot_world[side] = position.x + facing * power_scale * Vector2(_foot_local[side]).x
			var cycle := fposmod(gait + (PI if side == "far" else 0.0), TAU) / TAU
			_was_support[side] = cycle < float(motion.stance_ratio)
	_was_travelling = moving
	if not airborne:
		gait += absf(displacement) / cycle_distance * TAU
	var attack := combat.envelope()
	var high_kick := combat.kind == "kick" and combat.kick_step == 2 and strike >= 0
	high_kick = high_kick and not combat.low and not combat.in_air
	var kick_body: Dictionary = combat.tuning.kick_body
	var compression := landing_strength * sin(minf(landing_time / 0.24, 1.0) * PI)
	compression *= exp(-landing_time * 2.5)
	var breath := sin(clock * 2.4) * 0.8 * (1.0 - _travel_blend)
	var bob := (1.0 - cos(gait * 2.0)) * (1.35 + _sprint_blend * 0.65) * _travel_blend
	var hip_target := -80.0 + breath + bob + preparation * 12.0 + compression * 14.0
	hip_target += crouch * float(motion.crouch_height)
	hip_target += _sprint_blend * 6.0
	if high_kick:
		hip_target -= (attack.x + attack.y) * float(kick_body.high_knee_lift)
	_hip_spring = RigMath.spring(_hip_spring, hip_target, 420, 33, delta)
	var hip_shift := attack.x * 5.0
	if combat.kind == "kick" and strike >= 0:
		hip_shift = attack.x * float(kick_body.front_shift)
		if combat.kick_step == 1:
			hip_shift = attack.x * float(kick_body.low_shift) - attack.y * 3.0
		if high_kick:
			hip_shift = attack.x * float(kick_body.high_shift)
			hip_shift += attack.y * float(kick_body.high_chamber_shift)
			# The support foot changes when the high kick uses the far leg.
			hip_shift *= 1.0 if combat.side == "near" else -0.65
	hip_shift += bat_pose.prepare(self)
	bones.hips.position = Vector2(hip_shift - power_pose.y * 8, _hip_spring.x + power_pose.x * 7)
	var acceleration_lean := clampf(horizontal_acceleration * facing / 1600.0, -1, 1) * 0.13
	var body_target := 0.035 + _travel_blend * 0.14 + acceleration_lean
	body_target += _sprint_blend * 0.07
	body_target += crouch * 0.18
	if combat.kind == "kick" and strike >= 0:
		var lean := 0.3 if combat.in_air else 0.23
		if high_kick:
			body_target -= float(kick_body.high_lean) * (attack.x + attack.y * 0.85)
		else:
			body_target -= attack.x * lean - attack.y * 0.07
	elif held_melee != "bat":
		body_target += attack.x * (0.32 if combat.side == "far" else 0.22) - attack.y * 0.12
	body_target += preparation * 0.11 - power_pose.x * 0.18 + power_pose.y * 0.3
	body_target += compression * 0.1 - clampf(vertical_speed / 600.0, -1, 1) * 0.06
	var stiffness := float(kick_body.high_spring) if high_kick else float(motion.body_stiffness)
	var damping := float(kick_body.high_damping) if high_kick else float(motion.body_damping)
	_body_spring = RigMath.spring(_body_spring, body_target, stiffness, damping, delta)
	bones.body.rotation = _body_spring.x
	var head_target: float = -bones.body.rotation * 0.83 + sin(clock * 2.4 - 0.5) * 0.017
	_head_spring = RigMath.spring(
		_head_spring, head_target, float(motion.head_stiffness), float(motion.head_damping), delta
	)
	bones.head.rotation = _head_spring.x
	for side: String in ["far", "near"]:
		_pose_leg(side, delta)
		var phase := gait + (PI if side == "far" else 0.0)
		var swing := cos(phase) * 0.62 * _travel_blend * (1.0 - crouch * 0.65)
		bones[side + "_arm"].rotation = 0.32 + swing - bones.body.rotation
		bones[side + "_fore"].rotation = -1.55 - absf(swing) * 0.25 - _air_blend * 0.18
		bones[side + "_hand"].rotation = 0.0
	attack_pose.apply(self)
	firearm_pose.apply(self)
	guard_blend = move_toward(guard_blend, float(blocking), delta * 12)
	if guard_blend > 0:
		for side: String in ["near", "far"]:
			var arm: Bone2D = bones[side + "_arm"]
			var fore: Bone2D = bones[side + "_fore"]
			arm.rotation = lerp_angle(arm.rotation, -0.95 if side == "near" else -0.6, guard_blend)
			fore.rotation = lerp_angle(fore.rotation, -1.8, guard_blend)
			bones[side + "_hand"].rotation = -0.2 * guard_blend
	if power_pose.length_squared() > 0.001:
		for side: String in ["near", "far"]:
			bones[side + "_arm"].rotation = lerpf(
				bones[side + "_arm"].rotation,
				0.55 - power_pose.y * 1.5,
				power_pose.x + power_pose.y
			)
			bones[side + "_fore"].rotation = -1.9 + power_pose.y * 1.7
	bat_pose.apply(self)
	debug_layer.queue_redraw()


func _update_gaze(delta: float) -> void:
	var active := absf(horizontal_speed) > 8 or airborne or strike >= 0 or preparation > 0
	active = active or crouch > 0.1
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


func land(impact: float) -> void:
	if combat.in_air and strike >= 0:
		combat.elapsed = maxf(combat.elapsed, float(combat.timings().hold) + 0.08)
	landing_time = 0.0
	landing_strength = clampf(impact / float(motion.jump_speed), 0.25, 1.0)
	_hip_spring.y += landing_strength * 55.0
	_reset_feet()


func _reset_feet() -> void:
	gait = PI
	_was_travelling = false
	for side: String in ["far", "near"]:
		var hip_x: float = bones[side + "_thigh"].position.x
		var rest := float(motion["guard_" + side + "_foot"])
		_foot_world[side] = position.x + facing * power_scale * (hip_x + rest)
		var cycle := fposmod(gait + (PI if side == "far" else 0.0), TAU) / TAU
		_was_support[side] = cycle < float(motion.stance_ratio)
		_foot_local[side] = Vector2(hip_x + rest, -6)


func stride_cycle_distance() -> float:
	if stop_cycle_distance > 0:
		return stop_cycle_distance
	var stride := _stride_half()
	return stride * 2.0 / float(motion.stance_ratio)


func _stride_half() -> float:
	if finishing_step and stop_cycle_distance > 0:
		return stop_cycle_distance * float(motion.stance_ratio) * 0.5
	var stride := lerpf(float(motion.stride_half), float(motion.sprint_stride_half), _sprint_blend)
	return lerpf(stride, float(motion.crouch_stride_half), crouch)


func _pose_leg(side: String, delta: float) -> void:
	var cycle := fposmod(gait + (PI if side == "far" else 0.0), TAU) / TAU
	var stance := float(motion.stance_ratio)
	var hip_x: float = bones[side + "_thigh"].position.x
	var stride := _stride_half()
	var moving := absf(horizontal_speed) > 8.0 or finishing_step
	var step_direction := -1.0 if horizontal_speed * facing < 0 else 1.0
	var supporting := cycle < stance and moving and not airborne
	var target := Vector2(hip_x + float(motion["guard_" + side + "_foot"]), -6)
	var foot_angle := 0.0
	if moving:
		if supporting:
			if not _was_support[side]:
				_foot_world[side] = (
					position.x + facing * power_scale * (hip_x + stride * step_direction)
				)
			target.x = (float(_foot_world[side]) - position.x) * facing / power_scale
		else:
			var swing := clampf((cycle - stance) / (1.0 - stance), 0, 1)
			target.x = hip_x + lerpf(-stride, stride, smoothstep(0, 1, swing)) * step_direction
			var clearance := lerpf(
				float(motion.foot_clearance), float(motion.crouch_foot_clearance), crouch
			)
			target.y -= sin(swing * PI) * clearance
			foot_angle = sin(swing * PI) * 0.22 * step_direction
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
	var air_toe := float(motion.air_front_toe if side == "near" else motion.air_rear_toe)
	bones[side + "_foot"].rotation = (
		-angles.x - angles.y + foot_angle * (1 - _air_blend) + air_toe * _air_blend
	)


func _draw_skeleton() -> void:
	if not show_bones:
		return
	for bone: Bone2D in bones.values():
		var start := to_local(bone.global_position)
		var end := to_local(bone.to_global(Vector2(0, bone.length)))
		debug_layer.draw_line(start, end, Color(0.3, 1.0, 0.9, 0.8), 1.4, true)
		debug_layer.draw_circle(start, 2, Color.WHITE)
