extends Polygon2D
## Existing bent sleeve painting deforms continuously over upper arm and elbow.

const SIZE = Vector2(45, 69)
const SHOULDER = Vector2(0.77, 0.10)
const ELBOW = Vector2(0.65, 0.52)
const WRIST = Vector2(0.20, 0.87)
var hand_mesh: Polygon2D


static func upper_vector() -> Vector2:
	return (ELBOW - SHOULDER) * SIZE


static func lower_vector(kind: String = "", side: String = "near") -> Vector2:
	var wrist := Vector2(0.35, 0.84) if kind in ["beaver", "hare"] and side == "near" else WRIST
	return (wrist - ELBOW) * SIZE


func setup(rig: Skeleton2D, bones: Dictionary, kind: String, side: String) -> void:
	name = side + "_sleeve"
	texture = load("res://assets/enemies/%s/%s_arm.png" % [kind, side])
	z_index = 17 if side == "near" else 5
	z_as_relative = false
	modulate = Color.WHITE if side == "near" else Color(0.79, 0.85, 0.85)
	rig.add_child(self)
	skeleton = get_path_to(rig)
	var shoulder: Vector2 = bones.hips.position + bones.body.position
	shoulder += bones[side + "_arm"].position
	var origin := shoulder - SHOULDER * SIZE
	var points := PackedVector2Array()
	var texcoords := PackedVector2Array()
	var upper := PackedFloat32Array()
	var lower := PackedFloat32Array()
	var wrist := PackedFloat32Array()
	var faces: Array[PackedInt32Array] = []
	var hand_faces: Array[PackedInt32Array] = []
	var wrapped_grip := kind in ["beaver", "hare"] and side == "near"
	for row in range(19):
		for col in range(7):
			var uv_point := Vector2(col / 6.0, row / 18.0)
			if wrapped_grip:
				# Cut across the diagonal forearm at the cuff, not across image rows.
				# A horizontal cut removed the wrist but left the elbow-side sleeve.
				uv_point.y *= minf(1.0, 0.84 + (uv_point.x - 0.35) * 1.6)
			points.append(origin + uv_point * SIZE)
			texcoords.append(uv_point * texture.get_size())
			var fore_weight := smoothstep(0.38, 0.65, uv_point.y)
			var hand_weight := smoothstep(0.78, 0.89, uv_point.y)
			if kind == "foreman":
				var axis := (WRIST - ELBOW) * SIZE
				var along := ((uv_point - ELBOW) * SIZE).dot(axis) / axis.length_squared()
				hand_weight = smoothstep(0.8, 1.0, along)
			upper.append(1 - fore_weight)
			lower.append(fore_weight * (1.0 - hand_weight))
			wrist.append(hand_weight)
			if row < 18 and col < 6:
				var index := row * 7 + col
				var layer: Array[PackedInt32Array] = (
					hand_faces if row >= 14 and not wrapped_grip else faces
				)
				if kind == "foreman":
					layer = hand_faces if col < 3 and row >= 11 else faces
				layer.append(PackedInt32Array([index, index + 1, index + 8]))
				layer.append(PackedInt32Array([index, index + 8, index + 7]))
	polygon = points
	uv = texcoords
	polygons = faces
	add_bone(rig.get_path_to(bones[side + "_arm"]), upper)
	add_bone(rig.get_path_to(bones[side + "_fore"]), lower)
	add_bone(rig.get_path_to(bones[side + "_hand"]), wrist)
	hand_mesh = Polygon2D.new()
	hand_mesh.name = side + "_grip"
	hand_mesh.texture = texture
	hand_mesh.polygon = points
	hand_mesh.uv = texcoords
	hand_mesh.polygons = hand_faces
	hand_mesh.z_as_relative = false
	hand_mesh.z_index = 19 if side == "near" else 6
	hand_mesh.modulate = modulate
	rig.add_child(hand_mesh)
	hand_mesh.skeleton = hand_mesh.get_path_to(rig)
	hand_mesh.add_bone(rig.get_path_to(bones[side + "_arm"]), upper)
	hand_mesh.add_bone(rig.get_path_to(bones[side + "_fore"]), lower)
	hand_mesh.add_bone(rig.get_path_to(bones[side + "_hand"]), wrist)
