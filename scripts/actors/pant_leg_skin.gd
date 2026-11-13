extends Polygon2D
## One continuous painted pant leg, skinned from waist through hip and knee.


func setup(rig: Skeleton2D, bones: Dictionary, side: String, depth: int) -> void:
	name = side + "_trousers"
	var art := "pant_leg" if side == "near" else "pant_leg_inner"
	texture = load("res://assets/characters/los/%s.png" % art)
	z_index = depth
	z_as_relative = false
	modulate = Color.WHITE if side == "near" else Color(0.78, 0.83, 0.85)
	rig.add_child(self)
	skeleton = get_path_to(rig)
	var thigh: Bone2D = bones[side + "_thigh"]
	var shin: Bone2D = bones[side + "_shin"]
	var points := PackedVector2Array()
	var texcoords := PackedVector2Array()
	var hip_weights := PackedFloat32Array()
	var thigh_weights := PackedFloat32Array()
	var shin_weights := PackedFloat32Array()
	var faces: Array[PackedInt32Array] = []
	# The far cuff reaches below the ankle joint, covering the top of its shoe.
	var size := Vector2(34, 87 if side == "near" else 90)
	var origin: Vector2 = bones.hips.position + thigh.position + Vector2(-17, -10)
	for row in range(19):
		var v := row / 18.0
		var height := v * size.y - 10.0
		var waist := 1.0 - smoothstep(-4.0, 13.0, height)
		var lower := smoothstep(30.0, 46.0, height) * (1.0 - waist)
		for col in range(7):
			var u := col / 6.0
			points.append(origin + Vector2(u, v) * size)
			texcoords.append(Vector2(u, v) * texture.get_size())
			hip_weights.append(waist)
			shin_weights.append(lower)
			thigh_weights.append(1.0 - waist - lower)
	for row in range(18):
		for col in range(6):
			var a := row * 7 + col
			faces.append(PackedInt32Array([a, a + 1, a + 8]))
			faces.append(PackedInt32Array([a, a + 8, a + 7]))
	polygon = points
	uv = texcoords
	polygons = faces
	add_bone(rig.get_path_to(bones.hips), hip_weights)
	add_bone(rig.get_path_to(thigh), thigh_weights)
	add_bone(rig.get_path_to(shin), shin_weights)
