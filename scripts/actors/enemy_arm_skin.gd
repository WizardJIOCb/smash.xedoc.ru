extends Polygon2D
## Existing bent sleeve painting deforms continuously over upper arm and elbow.

const SIZE = Vector2(45, 69)
const SHOULDER = Vector2(0.77, 0.10)
const ELBOW = Vector2(0.65, 0.52)
const WRIST = Vector2(0.20, 0.87)


static func upper_vector() -> Vector2:
	return (ELBOW - SHOULDER) * SIZE


static func lower_vector() -> Vector2:
	return (WRIST - ELBOW) * SIZE


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
	var faces: Array[PackedInt32Array] = []
	for row in range(19):
		for col in range(7):
			var uv_point := Vector2(col / 6.0, row / 18.0)
			points.append(origin + uv_point * SIZE)
			texcoords.append(uv_point * texture.get_size())
			var fore_weight := smoothstep(0.38, 0.65, uv_point.y)
			upper.append(1 - fore_weight)
			lower.append(fore_weight)
			if row < 18 and col < 6:
				var index := row * 7 + col
				faces.append(PackedInt32Array([index, index + 1, index + 8]))
				faces.append(PackedInt32Array([index, index + 8, index + 7]))
	polygon = points
	uv = texcoords
	polygons = faces
	add_bone(rig.get_path_to(bones[side + "_arm"]), upper)
	add_bone(rig.get_path_to(bones[side + "_fore"]), lower)
