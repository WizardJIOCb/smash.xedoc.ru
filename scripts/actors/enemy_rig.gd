extends Node2D
## Original painterly parts on native bones; continuous two-bone leg meshes.

const ArmSkin = preload("res://scripts/actors/enemy_arm_skin.gd")

var kind: String = "shield"
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


func _ready() -> void:
	skeleton = Skeleton2D.new()
	add_child(skeleton)
	_bone("hips", skeleton, Vector2(0, -70), 8)
	_bone("body", bones.hips, Vector2.ZERO, 65)
	if kind == "drone":
		_part("body", bones.body, Vector2(103, 51), Vector2(0.5, 0.5), 10)
		return
	_part("torso", bones.body, Vector2(66, 79), Vector2(0.5, 0.94), 10)
	_bone("head", bones.body, Vector2(-9, -59), 30)
	_part("head", bones.head, Vector2(83, 75), Vector2(0.65, 0.87), 13)
	for side: String in ["far", "near"]:
		var near_side := side == "near"
		_bone(side + "_leg", bones.hips, Vector2(-9 if near_side else 10, -2), 36)
		_bone(side + "_shin", bones[side + "_leg"], Vector2(0, 36), 34)
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
		arm.setup(skeleton, bones, kind, side)
		arm_meshes[side] = arm
	if kind == "shield":
		_bone("shield", bones.near_hand, Vector2.ZERO, 50)
		_part("weapon", bones.shield, Vector2(59, 99), Vector2(0.84, 0.47), 16)
		_bone("baton", bones.far_hand, Vector2.ZERO, 20)
		_part("extra", bones.baton, Vector2(54, 19), Vector2(0.86, 0.5), 6)
	else:
		_part("extra", bones.body, Vector2(26, 32), Vector2(0.5, 0), 11).position += Vector2(22, -7)
		_bone("cable", bones.near_hand, Vector2.ZERO, 20)
		_part("weapon", bones.cable, Vector2(31, 30), Vector2(0.32, 0.12), 16)


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
	sprite.texture = load("res://assets/enemies/%s/%s.png" % [kind, id])
	sprite.centered = false
	sprite.scale = size / sprite.texture.get_size()
	sprite.position = -size * pivot
	sprite.z_index = depth
	sprite.z_as_relative = false
	parent.add_child(sprite)
	return sprite


func _leg_skin(side: String) -> void:
	var mesh := Polygon2D.new()
	mesh.texture = load("res://assets/enemies/%s/%s_leg.png" % [kind, side])
	skeleton.add_child(mesh)
	mesh.skeleton = mesh.get_path_to(skeleton)
	mesh.z_index = 3 if side == "near" else 1
	mesh.z_as_relative = false
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var upper := PackedFloat32Array()
	var lower := PackedFloat32Array()
	var triangles: Array[PackedInt32Array] = []
	var hip: Vector2 = bones.hips.position + bones[side + "_leg"].position
	for row in range(11):
		for col in range(4):
			var unit := Vector2(col / 3.0, row / 10.0)
			points.append(hip + Vector2((unit.x - 0.58) * 38, unit.y * 74 - 3))
			uv.append(unit * mesh.texture.get_size())
			var weight := smoothstep(0.35, 0.65, unit.y)
			upper.append(1.0 - weight)
			lower.append(weight)
			if row < 10 and col < 3:
				var index := row * 4 + col
				triangles.append(PackedInt32Array([index, index + 1, index + 5]))
				triangles.append(PackedInt32Array([index, index + 5, index + 4]))
	mesh.polygon = points
	mesh.uv = uv
	mesh.polygons = triangles
	mesh.add_bone(skeleton.get_path_to(bones[side + "_leg"]), upper)
	mesh.add_bone(skeleton.get_path_to(bones[side + "_shin"]), lower)
	if side == "far":
		mesh.modulate = Color(0.79, 0.85, 0.85)


func _process(delta: float) -> void:
	clock += delta
	phase += absf(pace) * delta / 56 * TAU
	scale.x = -facing
	if kind == "drone":
		bones.body.rotation = sin(clock * 6) * 0.06 + wind * 0.18 - strike * 0.35
		bones.hips.position.y = -70 + sin(clock * 4) * 5 + collapse * 45
		return
	var walk := clampf(absf(pace) / 50, 0, 1)
	bones.hips.position.y = -70 + sin(clock * 2.4) * 0.6 + absf(sin(phase)) * walk * 2
	bones.body.rotation = -wind * 0.18 + strike * 0.38 - hurt * 0.24 + collapse * 1.3
	bones.head.rotation = -bones.body.rotation * 0.65
	for side: String in ["far", "near"]:
		var cycle := phase + (PI if side == "far" else 0.0)
		bones[side + "_leg"].rotation = sin(cycle) * 0.36 * walk
		bones[side + "_shin"].rotation = -maxf(0, cos(cycle)) * walk * 0.42
		bones[side + "_arm"].rotation = upper_rest + sin(cycle + PI) * 0.17 * walk
		bones[side + "_fore"].rotation = fore_rest + sin(cycle) * 0.1 * walk
	bones.near_arm.rotation += -wind * 0.75 + strike * 1.05
	bones.near_fore.rotation += wind * 0.5 - strike * 0.75
	bones.far_arm.rotation += -wind * 0.65 + strike * 0.9
	bones.far_fore.rotation += wind * 0.35 - strike * 0.55
	if kind == "shield":
		bones.shield.rotation = _grip_rotation("near") + (0.45 if shield_down else 0.0)
		bones.baton.rotation = _grip_rotation("far") - wind * 0.65 + strike * 0.3
	else:
		bones.cable.rotation = _grip_rotation("near") + strike * 0.35


func _grip_rotation(side: String) -> float:
	return -bones.body.rotation - bones[side + "_arm"].rotation - bones[side + "_fore"].rotation
