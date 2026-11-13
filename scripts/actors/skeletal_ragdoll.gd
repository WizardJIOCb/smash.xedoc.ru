extends Node2D
## Native rigid bodies and constrained joints drive the existing painted bones.
## Physics lives in world space; bind transforms retain mirrored/scaled artwork.

const TERRAIN_LAYER = 8
const CORPSE_LAYER = 16

static var leased_layers: int = 0

var bodies: Dictionary = {}
var bindings: Dictionary = {}
var joints: Array[PinJoint2D] = []

var physical_bodies: Array[RigidBody2D] = []
var skin_bindings: Array[Dictionary] = []
var constraints: Array[Dictionary] = []
var impact_centers: Dictionary = {}
var hit_shapes: Array[CollisionShape2D] = []
var hits: int = 0
var self_layer: int = 0
var settled: bool = false
var still_time: float = 0.0
var pose_dirty: bool = true
var settled_joint_error: float = 0.0
var rig: Node2D
var age: float = 0.0
var paused: bool = false
var lifetime: float = 12.0
var impact_bone: String = ""
var tuning: Dictionary = (
	JSON.parse_string(FileAccess.get_file_as_string("res://data/physical_combat.json")).ragdoll
)


func start(painted_rig: Node2D, hit: Vector2, impulse: Vector2, velocity: Vector2) -> void:
	rig = painted_rig
	lifetime = float(tuning.lifetime)
	top_level = true
	global_transform = Transform2D.IDENTITY
	process_priority = 50
	_relax_legs()
	var bones: Dictionary = rig.bones
	if bones.size() <= 2:
		_segment("body", Vector2(-35, -17), Vector2(35, 17), 14, 5)
	else:
		_segment("hips", Vector2(-12, 0), Vector2(12, 0), 9, 6)
		var head_local: Vector2 = bones.body.to_local(bones.head.global_position)
		_segment("body", Vector2.ZERO, head_local, 15, 9)
		var is_moose := bones.has("near_thigh")
		_segment(
			"head",
			Vector2(0 if is_moose else -15, -22),
			Vector2(29 if is_moose else 10, -39),
			22,
			3
		)
		if is_moose:
			# Rounded brow contact; broad decorative tips must not prop up the torso.
			_extra_shape("head", Vector2(0, -49), float(tuning.antler_root_radius))
			_extra_shape("head", Vector2(48, -26), 19)
		for side: String in ["far", "near"]:
			var thigh := side + ("_thigh" if bones.has(side + "_thigh") else "_leg")
			_limb(thigh, side + "_shin", 8, 1.5)
			if bones.has(side + "_foot"):
				_limb(side + "_shin", side + "_foot", 7, 1.1)
				_segment(
					side + "_foot",
					Vector2(-7 if is_moose else -13, 8 if is_moose else -5),
					Vector2(25 if is_moose else 9, 8 if is_moose else -5),
					7 if is_moose else 6,
					0.8
				)
			else:
				_segment(side + "_shin", Vector2.ZERO, Vector2(0, 32), 8, 1.5)
			_limb(side + "_arm", side + "_fore", 8, 1.0)
			_limb(side + "_fore", side + "_hand", 7, 0.8)
			_segment(side + "_hand", Vector2.ZERO, Vector2(0, 13), 7, 0.6)
		if bones.has("shield"):
			_segment("shield", Vector2(-20, -27), Vector2(-20, 30), 15, 2.5)
			_segment("baton", Vector2(-39, 0), Vector2(-3, 0), 4, 0.5)
		_weld_core()
		for side: String in ["far", "near"]:
			var thigh := side + ("_thigh" if is_moose else "_leg")
			_weld_leg(thigh, side + "_shin", side + "_foot")
		# Insertion order is parent before child, required when copying transforms.
		for id: String in bodies:
			var parent: Node = bones[id].get_parent()
			if (
				parent is Bone2D
				and bodies.has(str(parent.name))
				and bodies[str(parent.name)] != bodies[id]
			):
				_joint(str(parent.name), id, bones[id].global_position)
		_setup_self_contacts()
	for body: RigidBody2D in physical_bodies:
		for child: Node in body.get_children():
			if child is CollisionShape2D:
				hit_shapes.append(child)
	var nearest_distance := INF
	for body: RigidBody2D in physical_bodies:
		body.linear_velocity = (
			velocity
			+ Vector2(
				impulse.x * float(tuning.launch_horizontal),
				impulse.y * 0.4 - float(tuning.launch_lift)
			)
		)
	for id: String in bodies:
		skin_bindings.append({"bone": bones[id], "body": bodies[id], "offset": bindings[id]})
		var distance: float = impact_centers[id].distance_squared_to(hit)
		if distance < nearest_distance:
			nearest_distance = distance
			impact_bone = id
	if not impact_bone.is_empty():
		var struck: RigidBody2D = bodies[impact_bone]
		struck.apply_impulse(
			impulse * minf(struck.mass, 2.0) * 0.6, (hit - struck.global_position).limit_length(12)
		)
		if bodies.size() > 1:
			var trunk: RigidBody2D = bodies.body
			trunk.apply_impulse(
				impulse * float(tuning.core_impulse_share),
				(hit - trunk.global_position).limit_length(75)
			)


func _extra_shape(id: String, at: Vector2, radius: float) -> void:
	var body: RigidBody2D = bodies[id]
	var bone: Bone2D = rig.bones[id]
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius * bone.global_transform.x.length()
	shape.shape = circle
	shape.position = body.to_local(bone.to_global(at))
	body.add_child(shape)


func _relax_legs() -> void:
	if not rig.bones.has("near_shin"):
		return
	var bend := 1.0 if rig.bones.has("near_thigh") else -1.0
	for side: String in ["far", "near"]:
		var knee: Bone2D = rig.bones[side + "_shin"]
		var ankle: Bone2D = rig.bones[side + "_foot"]
		knee.rotation = (
			clampf(knee.rotation * bend, tuning.death_knee_min, tuning.death_knee_max) * bend
		)
		ankle.rotation = (
			clampf(ankle.rotation * bend, tuning.death_ankle_min, tuning.death_ankle_max) * bend
		)


func _weld_leg(thigh: String, shin: String, foot: String) -> void:
	# A semi-rigid leg keeps its captured anatomical bend through a heavy fall.
	# Each leg still swings independently at the hip; arms remain articulated.
	var upper: RigidBody2D = bodies[thigh]
	for id: String in [shin, foot]:
		var lower: RigidBody2D = bodies[id]
		upper.mass += lower.mass
		for child: Node in lower.get_children():
			if child is CollisionShape2D:
				child.reparent(upper, true)
		physical_bodies.erase(lower)
		remove_child(lower)
		lower.free()
		bodies[id] = upper
		bindings[id] = upper.global_transform.affine_inverse() * rig.bones[id].global_transform
	upper.set_meta("inertia_estimate", upper.mass * 450.0)


func _limb(id: String, child_id: String, radius: float, mass_value: float) -> void:
	var bone: Bone2D = rig.bones[id]
	_segment(
		id, Vector2.ZERO, bone.to_local(rig.bones[child_id].global_position), radius, mass_value
	)


func _segment(id: String, from: Vector2, to: Vector2, radius: float, mass_value: float) -> void:
	var bone: Bone2D = rig.bones[id]
	var a := bone.to_global(from)
	var b := bone.to_global(to)
	var body := RigidBody2D.new()
	body.name = id + "_physics"
	body.position = (a + b) * 0.5
	body.rotation = (b - a).angle() - PI / 2
	body.mass = mass_value
	body.set_meta(
		"inertia_estimate", mass_value * (a.distance_squared_to(b) + radius * radius * 2) / 12.0
	)
	body.gravity_scale = float(tuning.gravity_scale)
	body.linear_damp = float(tuning.linear_damp)
	body.angular_damp = float(tuning.angular_damp)
	body.collision_layer = CORPSE_LAYER
	body.collision_mask = TERRAIN_LAYER
	var material := PhysicsMaterial.new()
	material.friction = 0.7
	material.bounce = 0.05
	body.physics_material_override = material
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	var size_factor := bone.global_transform.x.length()
	capsule.radius = radius * size_factor
	capsule.height = a.distance_to(b) + capsule.radius * 2
	shape.shape = capsule
	body.add_child(shape)
	add_child(body)
	bodies[id] = body
	physical_bodies.append(body)
	impact_centers[id] = body.global_position
	bindings[id] = body.global_transform.affine_inverse() * bone.global_transform


func _joint(parent_id: String, child_id: String, anchor: Vector2) -> void:
	var joint := PinJoint2D.new()
	joint.position = anchor
	joint.bias = 0.3
	joint.softness = 0.0
	# Godot's pin angular limits measure the WORLD center-to-center direction.
	# That fights a falling articulated chain. Use relative torsion below instead.
	joint.angular_limit_enabled = false
	var profile := _anatomy_profile(child_id)
	add_child(joint)
	joint.node_a = joint.get_path_to(bodies[parent_id])
	joint.node_b = joint.get_path_to(bodies[child_id])
	joint.set_meta("a", bodies[parent_id].to_local(anchor))
	joint.set_meta("b", bodies[child_id].to_local(anchor))
	var bone: Bone2D = rig.bones[child_id]
	var mirror := signf(bone.global_transform.determinant())
	var captured: float = bodies[child_id].rotation - bodies[parent_id].rotation
	var displacement := angle_difference(bone.rest.get_rotation(), bone.rotation)
	var neutral := captured - displacement * mirror
	if child_id in ["shield", "baton"]:
		neutral = captured
	joint.set_meta("capture_rest", captured)
	joint.set_meta("relative_rest", neutral)
	joint.set_meta("mirror", mirror)
	joint.set_meta("profile", profile)
	joints.append(joint)
	var a: RigidBody2D = bodies[parent_id]
	var b: RigidBody2D = bodies[child_id]
	var ia: float = a.get_meta("inertia_estimate")
	var ib: float = b.get_meta("inertia_estimate")
	constraints.append(
		{
			"joint": joint,
			"a": a,
			"b": b,
			"capture": captured,
			"rest": neutral,
			"mirror": mirror,
			"profile": profile,
			"inertia": ia * ib / maxf(1.0, ia + ib)
		}
	)


func _weld_core() -> void:
	# A compound rigid trunk supports pelvis, chest and neck without two nearly
	# coincident joints fighting each other. Limbs remain fully articulated.
	var trunk: RigidBody2D = bodies.body
	for id: String in ["hips", "head"]:
		var part: RigidBody2D = bodies[id]
		trunk.mass += part.mass
		for child: Node in part.get_children():
			if child is CollisionShape2D:
				child.reparent(trunk, true)
		physical_bodies.erase(part)
		remove_child(part)
		part.free()
		bodies[id] = trunk
		bindings[id] = trunk.global_transform.affine_inverse() * rig.bones[id].global_transform
	trunk.set_meta("inertia_estimate", trunk.mass * 900.0)


func _anatomy_profile(id: String) -> Dictionary:
	var moose: bool = rig.bones.has("near_thigh")
	var bounds := Vector2(-1.6, 1.6)
	var spring := 0.0
	var stiffness := float(tuning.torsion_stiffness)
	var damping := float(tuning.torsion_damping)
	var cap := float(tuning.torsion_cap)
	if id == "body" or id == "head":
		var limit := float(tuning.spine_limit if id == "body" else tuning.neck_limit)
		bounds = Vector2(-limit, limit)
		stiffness = float(tuning.core_stiffness)
		damping = float(tuning.core_damping)
		spring = float(tuning.core_spring if id == "body" else tuning.neck_spring)
	elif "thigh" in id or id.ends_with("_leg"):
		bounds = Vector2(-float(tuning.hip_flexion), float(tuning.hip_extension))
		if not moose:
			bounds = Vector2(-bounds.y, -bounds.x)
		spring = float(tuning.hip_spring)
		stiffness = float(tuning.hip_stiffness)
		damping = float(tuning.hip_damping)
		cap = float(tuning.hip_torsion_cap)
	elif "shin" in id:
		bounds = Vector2(-0.04, float(tuning.knee_flexion))
		if not moose:
			bounds = Vector2(-bounds.y, -bounds.x)
	elif "fore" in id:
		bounds = Vector2(-2.3, -0.04)
		if not moose:
			var rest: float = rig.bones[id].rest.get_rotation()
			bounds = Vector2(0.04 - rest, 2.3 - rest)
	elif "foot" in id or "hand" in id:
		bounds = Vector2(-0.5, 0.5)
	return {
		"bounds": bounds, "spring": spring, "stiffness": stiffness, "damping": damping, "cap": cap
	}


func _setup_self_contacts() -> void:
	# Isolate each articulated corpse. Overlapping near/far artwork and separate
	# corpses must not create a quadratic pile of colliding limb pairs.
	for index in range(5, 25):
		var candidate := 1 << index
		if not leased_layers & candidate:
			self_layer = candidate
			leased_layers |= candidate
			break
	for body: RigidBody2D in physical_bodies:
		body.collision_layer = CORPSE_LAYER | self_layer
		body.collision_mask = TERRAIN_LAYER | self_layer
	for index in range(physical_bodies.size()):
		var a := physical_bodies[index]
		for other in range(index + 1, physical_bodies.size()):
			var b := physical_bodies[other]
			var core := a if a == bodies.body else b
			var limb := b if core == a else a
			var distal := "_shin_" in limb.name or "_foot_" in limb.name
			if core != bodies.body or not distal:
				a.add_collision_exception_with(b)


func _exit_tree() -> void:
	leased_layers &= ~self_layer


func contact(area: Rect2, tip: Vector2) -> Vector2:
	if age >= lifetime or not rig.visible:
		return Vector2.INF
	var nearest := Vector2.INF
	var distance := INF
	for shape: CollisionShape2D in hit_shapes:
		var box: Rect2 = shape.global_transform * shape.shape.get_rect()
		if not area.intersects(box):
			continue
		var point := Vector2(
			clampf(tip.x, box.position.x, box.end.x), clampf(tip.y, box.position.y, box.end.y)
		)
		if point.distance_squared_to(tip) < distance:
			nearest = point
			distance = point.distance_squared_to(tip)
	return nearest


func react(at: Vector2, direction: Vector2, kind: String) -> bool:
	if paused or age >= lifetime or not rig.visible:
		return false
	if settled:
		for constraint: Dictionary in constraints:
			var joint: PinJoint2D = constraint.joint
			var a: RigidBody2D = constraint.a
			var b: RigidBody2D = constraint.b
			var anchor := (
				(a.to_global(joint.get_meta("a")) + b.to_global(joint.get_meta("b"))) * 0.5
			)
			joint.position = anchor
			joint.node_a = joint.get_path_to(a)
			joint.node_b = joint.get_path_to(b)
			joint.set_meta("a", a.to_local(anchor))
			joint.set_meta("b", b.to_local(anchor))
	settled = false
	still_time = 0
	pose_dirty = true
	lifetime = maxf(lifetime, age + float(tuning.hit_life))
	hits += 1
	var power := float(tuning.hit_kick_push if kind != "punch" else tuning.hit_punch_push)
	var lift := float(tuning.hit_kick_lift if kind != "punch" else tuning.hit_punch_lift)
	var kick := Vector2(signf(direction.x) * power, -lift)
	var nearest: RigidBody2D
	var distance := INF
	for body: RigidBody2D in physical_bodies:
		body.freeze = false
		body.collision_layer = CORPSE_LAYER | self_layer
		body.collision_mask = TERRAIN_LAYER | self_layer
		body.linear_velocity = (body.linear_velocity + kick).limit_length(
			float(tuning.hit_speed_cap)
		)
		if body.global_position.distance_squared_to(at) < distance:
			nearest = body
			distance = body.global_position.distance_squared_to(at)
	if is_instance_valid(nearest):
		nearest.apply_impulse(
			kick * nearest.mass * 0.12, (at - nearest.global_position).limit_length(10)
		)
	set_physics_process(true)
	set_process(true)
	return true


func _physics_process(delta: float) -> void:
	for body: RigidBody2D in physical_bodies:
		var should_freeze := paused or settled or age > lifetime
		if body.freeze != should_freeze:
			body.freeze = should_freeze
	if paused:
		return
	age += delta
	if not settled:
		_constrain_angles()
		var quiet := age > 1.0
		for body: RigidBody2D in physical_bodies:
			quiet = (
				quiet
				and body.linear_velocity.length_squared() < 2025
				and absf(body.angular_velocity) < 2.0
			)
		var core: RigidBody2D = bodies.body
		quiet = (
			quiet
			and core.linear_velocity.length_squared() < pow(float(tuning.settle_core_speed), 2)
			and absf(core.angular_velocity) < float(tuning.settle_core_spin)
		)
		still_time = still_time + delta if quiet else 0.0
		if still_time >= 0.45:
			settled_joint_error = joint_error()
			settled = true
			pose_dirty = true
			for joint: PinJoint2D in joints:
				joint.node_a = NodePath("")
				joint.node_b = NodePath("")
			for body: RigidBody2D in physical_bodies:
				body.linear_velocity = Vector2.ZERO
				body.angular_velocity = 0
				body.freeze = true
				body.collision_layer = 0
				body.collision_mask = 0
	if age > lifetime:
		for body: RigidBody2D in physical_bodies:
			body.freeze = true
		visible = false
		rig.visible = false
		set_physics_process(false)
		set_process(false)


func _constrain_angles() -> void:
	for constraint: Dictionary in constraints:
		var a: RigidBody2D = constraint.a
		var b: RigidBody2D = constraint.b
		var reference := lerp_angle(
			float(constraint.capture),
			float(constraint.rest),
			smoothstep(0, float(tuning.pose_release), age)
		)
		var mirror: float = constraint.mirror
		var angle := angle_difference(reference, b.rotation - a.rotation) * mirror
		var profile: Dictionary = constraint.profile
		var bounds: Vector2 = profile.bounds
		var excess := angle - clampf(angle, bounds.x, bounds.y)
		if absf(excess) < 0.001 and float(profile.spring) == 0:
			continue
		var effective: float = constraint.inertia
		var torque := (
			clampf(
				(
					(-excess * float(profile.stiffness) - angle * float(profile.spring)) * mirror
					- (b.angular_velocity - a.angular_velocity) * float(profile.damping)
				),
				-float(profile.cap),
				float(profile.cap)
			)
			* effective
		)
		b.apply_torque(torque)
		a.apply_torque(-torque)


func _process(_delta: float) -> void:
	if not is_instance_valid(rig) or not rig.ragdoll_active:
		return
	if not settled or pose_dirty:
		for binding: Dictionary in skin_bindings:
			binding.bone.global_transform = binding.body.global_transform * binding.offset
		pose_dirty = false
	# Each owner may tint its artwork; fading belongs to the skeleton alone.
	rig.skeleton.modulate.a = 1.0 - smoothstep(lifetime - float(tuning.fade), lifetime, age)


func joint_error() -> float:
	if settled:
		return settled_joint_error
	var worst := 0.0
	for joint: PinJoint2D in joints:
		var a: RigidBody2D = joint.get_node(joint.node_a)
		var b: RigidBody2D = joint.get_node(joint.node_b)
		worst = maxf(
			worst, a.to_global(joint.get_meta("a")).distance_to(b.to_global(joint.get_meta("b")))
		)
	return worst
