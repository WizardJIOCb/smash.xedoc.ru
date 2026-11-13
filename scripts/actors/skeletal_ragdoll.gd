extends Node2D
## Native rigid bodies and constrained joints drive the existing painted bones.
## Physics lives in world space; bind transforms retain mirrored/scaled artwork.

const TERRAIN_LAYER = 8
const CORPSE_LAYER = 16

var bodies: Dictionary = {}
var bindings: Dictionary = {}
var joints: Array[PinJoint2D] = []
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
	var bones: Dictionary = rig.bones
	if bones.size() <= 2:
		_segment("body", Vector2(-35, -17), Vector2(35, 17), 14, 5)
	else:
		_segment("hips", Vector2(-12, 0), Vector2(12, 0), 9, 4)
		var head_local: Vector2 = bones.body.to_local(bones.head.global_position)
		_segment("body", Vector2.ZERO, head_local, 17, 6)
		var is_moose := bones.has("near_thigh")
		_segment(
			"head",
			Vector2(0 if is_moose else -15, -22),
			Vector2(29 if is_moose else 10, -39),
			22,
			3
		)
		if is_moose:
			# Antlers are part of the head silhouette and must also rest on the ground.
			_extra_shape("head", Vector2(-44, -65), 17)
			_extra_shape("head", Vector2(40, -67), 15)
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
		# Insertion order is parent before child, required when copying transforms.
		for id: String in bodies:
			var parent: Node = bones[id].get_parent()
			if parent is Bone2D and bodies.has(str(parent.name)):
				_joint(str(parent.name), id, bones[id].global_position)
	var nearest_distance := INF
	for id: String in bodies:
		var body: RigidBody2D = bodies[id]
		body.linear_velocity = velocity + impulse * 0.22
		var distance := body.global_position.distance_squared_to(hit)
		if distance < nearest_distance:
			nearest_distance = distance
			impact_bone = id
	if not impact_bone.is_empty():
		var struck: RigidBody2D = bodies[impact_bone]
		struck.apply_impulse(
			impulse * minf(struck.mass, 2.0), (hit - struck.global_position).limit_length(12)
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
	bindings[id] = body.global_transform.affine_inverse() * bone.global_transform


func _joint(parent_id: String, child_id: String, anchor: Vector2) -> void:
	var joint := PinJoint2D.new()
	joint.position = anchor
	joint.bias = 0.3
	joint.softness = 0.0
	# Godot's pin angular limits measure the WORLD center-to-center direction.
	# That fights a falling articulated chain. Use relative torsion below instead.
	joint.angular_limit_enabled = false
	var limit := 1.1
	if child_id == "head":
		limit = 0.5
	elif child_id == "body":
		limit = 0.65
	elif "fore" in child_id or "shin" in child_id:
		limit = 1.6
	elif "foot" in child_id or "hand" in child_id:
		limit = 0.55
	joint.angular_limit_lower = -limit
	joint.angular_limit_upper = limit
	add_child(joint)
	joint.node_a = joint.get_path_to(bodies[parent_id])
	joint.node_b = joint.get_path_to(bodies[child_id])
	joint.set_meta("a", bodies[parent_id].to_local(anchor))
	joint.set_meta("b", bodies[child_id].to_local(anchor))
	joint.set_meta("relative_rest", bodies[child_id].rotation - bodies[parent_id].rotation)
	joint.set_meta("limit", limit)
	joints.append(joint)


func _physics_process(delta: float) -> void:
	for body: RigidBody2D in bodies.values():
		var should_freeze := paused or age > lifetime
		if body.freeze != should_freeze:
			body.freeze = should_freeze
	if not paused:
		_constrain_angles()
		age += delta
	if age > lifetime:
		for body: RigidBody2D in bodies.values():
			body.freeze = true
		visible = false
		rig.visible = false
		set_physics_process(false)
		set_process(false)


func _constrain_angles() -> void:
	for joint: PinJoint2D in joints:
		var a: RigidBody2D = joint.get_node(joint.node_a)
		var b: RigidBody2D = joint.get_node(joint.node_b)
		var angle := angle_difference(
			float(joint.get_meta("relative_rest")), b.rotation - a.rotation
		)
		var limit: float = joint.get_meta("limit")
		var excess := angle - clampf(angle, -limit, limit)
		if absf(excess) < 0.001:
			continue
		var ia: float = a.get_meta("inertia_estimate")
		var ib: float = b.get_meta("inertia_estimate")
		var effective := ia * ib / maxf(1.0, ia + ib)
		var torque := (
			clampf(
				(
					-excess * float(tuning.torsion_stiffness)
					- (b.angular_velocity - a.angular_velocity) * float(tuning.torsion_damping)
				),
				-float(tuning.torsion_cap),
				float(tuning.torsion_cap)
			)
			* effective
		)
		b.apply_torque(torque)
		a.apply_torque(-torque)


func _process(_delta: float) -> void:
	if not is_instance_valid(rig):
		return
	for id: String in bodies:
		rig.bones[id].global_transform = bodies[id].global_transform * bindings[id]
	# Each owner may tint its artwork; fading belongs to the skeleton alone.
	rig.skeleton.modulate.a = 1.0 - smoothstep(lifetime - float(tuning.fade), lifetime, age)


func joint_error() -> float:
	var worst := 0.0
	for joint: PinJoint2D in joints:
		var a: RigidBody2D = joint.get_node(joint.node_a)
		var b: RigidBody2D = joint.get_node(joint.node_b)
		worst = maxf(
			worst, a.to_global(joint.get_meta("a")).distance_to(b.to_global(joint.get_meta("b")))
		)
	return worst
