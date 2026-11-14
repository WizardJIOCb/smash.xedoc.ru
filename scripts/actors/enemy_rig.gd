extends Node2D
## Original painterly parts on native bones; continuous two-bone leg meshes.

const ArmSkin = preload("res://scripts/actors/enemy_arm_skin.gd")
const WeaponPose = preload("res://scripts/actors/enemy_weapon_pose.gd")
## Explicit preview-only donor. Production loads the actual species.
@export var art_profile: String = ""

var fit: Dictionary = JSON.parse_string(
	FileAccess.get_file_as_string("res://data/enemy_rig_fit.json")
)
var kind: String = "shield"
var weapon_pose := WeaponPose.new()
var body_scale: float = 1.0
var recoil: float = 0.0
var stomp: float = 0.0
var skeleton: Skeleton2D
var bones: Dictionary = {}
var phase: float = 0.0
var clock: float = 0.0
var pace: float = 0.0
var facing: float = -1.0
var wind: float = 0.0
var strike: float = 0.0
var hurt: float = 0.0
var collapse: float = 0.0
var shield_down: bool = false
var arm_meshes: Dictionary = {}
var upper_rest: float = 0.0
var fore_rest: float = 0.0
var ragdoll_active: bool = false
var foot_support: Dictionary = {}
var _previous_facing: float = -1.0


func _ready() -> void:
	skeleton = Skeleton2D.new()
	add_child(skeleton)
	_bone("hips", skeleton, Vector2(0, -70), 8)
	_bone("body", bones.hips, Vector2.ZERO, 65)
	if kind == "drone":
		_part("body", bones.body, Vector2(103, 51), Vector2(0.5, 0.5), 10)
		return
	_part("torso", bones.body, Vector2(66, 79), Vector2(0.5, 0.94), 10)
	var anatomy: Dictionary = fit.get(kind, {}) if art_profile.is_empty() else {}
	var socket: Array = anatomy.get("head_socket", [-9, -59])
	var pivot: Array = anatomy.get("head_pivot", [0.65, 0.87])
	_bone("head", bones.body, Vector2(socket[0], socket[1]), 30)
	_part("head", bones.head, Vector2(83, 75), Vector2(pivot[0], pivot[1]), 13)
	for side: String in ["far", "near"]:
		var near_side := side == "near"
		_bone(side + "_leg", bones.hips, Vector2(-9 if near_side else 10, -2), 36)
		_bone(side + "_shin", bones[side + "_leg"], Vector2(0, 36), 34)
		_bone(side + "_foot", bones[side + "_shin"], Vector2(0, 34), 16)
		# Source art faces LEFT: the visible shoulder socket is on the RIGHT.
		var upper := ArmSkin.upper_vector()
		var lower := ArmSkin.lower_vector()
		upper_rest = upper.angle() - PI / 2
		fore_rest = lower.angle() - upper.angle()
		_bone(side + "_arm", bones.body, Vector2(20 if near_side else -17, -57), upper.length())
		bones[side + "_arm"].rotation = upper_rest
		_bone(side + "_fore", bones[side + "_arm"], Vector2(0, upper.length()), lower.length())
		bones[side + "_fore"].rotation = fore_rest
		_bone(side + "_hand", bones[side + "_fore"], Vector2(0, lower.length()), 8)
	for bone: Bone2D in bones.values():
		bone.rest = bone.transform
	for side: String in ["far", "near"]:
		_leg_skin(side)
		var arm := ArmSkin.new()
		arm.setup(skeleton, bones, kind if art_profile.is_empty() else art_profile, side)
		arm_meshes[side] = arm
	if kind == "shield":
		_bone("shield", bones.near_hand, Vector2.ZERO, 50)
		_part("weapon", bones.shield, Vector2(59, 99), Vector2(0.84, 0.47), 16)
		_bone("baton", bones.far_hand, Vector2.ZERO, 20)
		_part("extra", bones.baton, Vector2(54, 19), Vector2(0.86, 0.5), 6)
	elif kind == "whip":
		_part("extra", bones.body, Vector2(26, 32), Vector2(0.5, 0), 11).position += Vector2(22, -7)
		_bone("cable", bones.near_hand, Vector2.ZERO, 20)
		_part("weapon", bones.cable, Vector2(31, 30), Vector2(0.32, 0.12), 16)
	else:
		_bone("weapon", bones.near_hand, Vector2.ZERO, 24)
		var gun := kind in ["fox", "lynx", "firewall"]
		_part(
			"weapon",
			bones.weapon,
			Vector2(62, 25) if gun else Vector2(30, 77),
			Vector2(0.82, 0.5) if gun else Vector2(0.5, 0.8),
			16
		)
		_part("extra", bones.body, Vector2(26, 32), Vector2(0.5, 0), 11).position += Vector2(22, -7)
	_apply_scale()


func asset_path(id: String) -> String:
	return "res://assets/enemies/%s/%s.png" % [kind if art_profile.is_empty() else art_profile, id]


func _apply_scale() -> void:
	scale = Vector2(-facing * body_scale, body_scale)
	# Art's planted sole is root+10 at any body size.
	position.y = 10.0 * (1.0 - body_scale)


func _bone(id: String, parent: Node, at: Vector2, length: float) -> void:
	var bone := Bone2D.new()
	bone.name = id
	bone.position = at
	bone.set_autocalculate_length_and_angle(false)
	bone.length = length
	bone.bone_angle = PI / 2
	parent.add_child(bone)
	bone.rest = bone.transform
	bones[id] = bone


func _part(id: String, parent: Node, size: Vector2, pivot: Vector2, depth: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = id
	sprite.texture = load(asset_path(id))
	sprite.centered = false
	sprite.scale = size / sprite.texture.get_size()
	sprite.position = -size * pivot
	sprite.z_index = depth
	sprite.z_as_relative = false
	parent.add_child(sprite)
	return sprite


func _leg_skin(side: String) -> void:
	var mesh := Polygon2D.new()
	mesh.texture = load(asset_path(side + "_leg"))
	skeleton.add_child(mesh)
	mesh.skeleton = mesh.get_path_to(skeleton)
	mesh.z_index = 3 if side == "near" else 1
	mesh.z_as_relative = false
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var upper := PackedFloat32Array()
	var lower := PackedFloat32Array()
	var ankle := PackedFloat32Array()
	var triangles: Array[PackedInt32Array] = []
	var hip: Vector2 = bones.hips.position + bones[side + "_leg"].position
	for row in range(11):
		for col in range(4):
			var unit := Vector2(col / 3.0, row / 10.0)
			points.append(hip + Vector2((unit.x - 0.58) * 38, unit.y * 74 - 3))
			uv.append(unit * mesh.texture.get_size())
			var weight := smoothstep(0.35, 0.65, unit.y)
			var foot_weight := smoothstep(0.76, 0.9, unit.y)
			upper.append(1.0 - weight)
			lower.append(weight * (1.0 - foot_weight))
			ankle.append(weight * foot_weight)
			if row < 10 and col < 3:
				var index := row * 4 + col
				triangles.append(PackedInt32Array([index, index + 1, index + 5]))
				triangles.append(PackedInt32Array([index, index + 5, index + 4]))
	mesh.polygon = points
	mesh.uv = uv
	mesh.polygons = triangles
	mesh.add_bone(skeleton.get_path_to(bones[side + "_leg"]), upper)
	mesh.add_bone(skeleton.get_path_to(bones[side + "_shin"]), lower)
	mesh.add_bone(skeleton.get_path_to(bones[side + "_foot"]), ankle)
	if side == "far":
		mesh.modulate = Color(0.79, 0.85, 0.85)


func _process(delta: float) -> void:
	if ragdoll_active:
		return
	clock += delta
	if facing != _previous_facing:
		foot_support.clear()
		_previous_facing = facing
	phase += absf(pace) * delta / 56 * TAU
	_apply_scale()
	if kind == "drone":
		bones.body.rotation = sin(clock * 6) * 0.06 + wind * 0.18 - strike * 0.35
		bones.hips.position.y = -70 + sin(clock * 4) * 5 + collapse * 45
		return
	var walk := clampf(absf(pace) / 50, 0, 1)
	bones.hips.position.y = -56 + sin(clock * 2.4) * 0.6 + absf(sin(phase)) * walk * 2
	bones.body.rotation = -wind * 0.18 + strike * 0.38 - hurt * 0.24 + collapse * 1.3
	bones.head.rotation = -bones.body.rotation * 0.65
	for side: String in ["far", "near"]:
		var cycle := phase + (PI if side == "far" else 0.0)
		_pose_ground_leg(side, cycle, walk)
		bones[side + "_arm"].rotation = upper_rest + sin(cycle + PI) * 0.17 * walk
		bones[side + "_fore"].rotation = fore_rest + sin(cycle) * 0.1 * walk
	bones.near_arm.rotation += -wind * 0.75 + strike * 1.05
	bones.near_fore.rotation += wind * 0.5 - strike * 0.75
	bones.far_arm.rotation += -wind * 0.65 + strike * 0.9
	bones.far_fore.rotation += wind * 0.35 - strike * 0.55
	if kind in ["beaver", "foreman"]:
		# Raise the tool above the shoulder, then follow through with the trunk.
		bones.near_arm.rotation += -wind * 1.15 + strike * 0.55
		bones.near_fore.rotation += -wind * 0.4
		bones.body.rotation += -wind * 0.15 + strike * 0.22
	elif kind == "hare":
		bones.far_arm.rotation += strike * 0.45
		bones.body.rotation += strike * 0.1
	elif kind in ["fox", "lynx", "firewall"]:
		# Both hands stay on the gun; far arm supports the fore-end.
		bones.near_arm.rotation = upper_rest + 0.35 + wind * 0.08 - recoil * 0.2
		bones.near_fore.rotation = fore_rest - 0.6 + recoil * 0.16
		bones.far_arm.rotation = upper_rest + 0.8 - recoil * 0.1
		bones.far_fore.rotation = fore_rest - 0.8
		bones.body.rotation = -wind * 0.06 - recoil * 0.09 + stomp * 0.22
		bones.hips.position.y += stomp * 6
	if kind == "shield":
		bones.shield.rotation = _grip_rotation("near") + (0.45 if shield_down else 0.0)
		bones.baton.rotation = _grip_rotation("far") - wind * 0.65 + strike * 0.3
	elif kind == "whip":
		bones.cable.rotation = _grip_rotation("near") + strike * 0.35
	else:
		bones.weapon.rotation = _grip_rotation("near") - wind * 0.15 + strike * 0.25
	weapon_pose.apply(self)


func _grip_rotation(side: String) -> float:
	return (
		-bones.body.rotation
		- bones[side + "_arm"].rotation
		- bones[side + "_fore"].rotation
		- bones[side + "_hand"].rotation
	)


func _pose_ground_leg(side: String, cycle: float, walk: float) -> void:
	# The painted sole is 1px beyond the shin endpoint: common ground is root+10.
	var unit := fposmod(cycle, TAU) / TAU
	var support := unit < 0.6 and walk > 0.05
	var hip: Vector2 = bones.hips.position + bones[side + "_leg"].position
	var goal := Vector2(hip.x + (-10 if side == "near" else 10), 9)
	if walk > 0.05:
		if support:
			if not foot_support.get(side + "_active", false):
				foot_support[side] = global_position.x + scale.x * (hip.x - 16)
			goal.x = (
				(float(foot_support.get(side, global_position.x)) - global_position.x) / scale.x
			)
		else:
			var swing := clampf((unit - 0.6) / 0.4, 0, 1)
			goal.x = hip.x + lerpf(16, -16, smoothstep(0, 1, swing))
			goal.y -= sin(swing * PI) * 13
	foot_support[side + "_active"] = support
	var target := goal - hip
	var distance := clampf(target.length(), 2.01, 69.98)
	var thigh := (
		atan2(-target.x, target.y)
		+ acos(clampf((distance * distance + 36 * 36 - 34 * 34) / (72 * distance), -1, 1))
	)
	# Enemy paintings face left: knees bend toward the muzzle, opposite the Moose.
	var knee := -PI + acos(clampf((36 * 36 + 34 * 34 - distance * distance) / (2 * 36 * 34), -1, 1))
	var angles := Vector2(thigh, knee)
	bones[side + "_leg"].rotation = angles.x
	bones[side + "_shin"].rotation = angles.y
	bones[side + "_foot"].rotation = -angles.x - angles.y
