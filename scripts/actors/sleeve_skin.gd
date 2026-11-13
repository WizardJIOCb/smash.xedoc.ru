extends Polygon2D


func setup(rig: Skeleton2D, bones: Dictionary, depth: int) -> void:
	name = "near_sleeve"
	texture = load("res://assets/characters/los/sleeve.png")
	z_index = depth
	z_as_relative = false
	rig.add_child(self)
	skeleton = get_path_to(rig)
	var size := Vector2(28, 72)
	var origin: Vector2 = bones.hips.position + bones.body.position
	origin += bones.near_arm.position + Vector2(-14, -6)
	var points := PackedVector2Array()
	var texcoords := PackedVector2Array()
	var upper_weights := PackedFloat32Array()
	var lower_weights := PackedFloat32Array()
	var faces: Array[PackedInt32Array] = []
	for row in range(25):
		var v := row / 24.0
		var lower := smoothstep(24.0, 38.0, v * size.y - 6.0)
		for col in range(7):
			var u := col / 6.0
			points.append(origin + Vector2(u, v) * size)
			texcoords.append(Vector2(u, v) * texture.get_size())
			upper_weights.append(1.0 - lower)
			lower_weights.append(lower)
	for row in range(24):
		for col in range(6):
			var a := row * 7 + col
			faces.append(PackedInt32Array([a, a + 1, a + 8]))
			faces.append(PackedInt32Array([a, a + 8, a + 7]))
	polygon = points
	uv = texcoords
	polygons = faces
	add_bone(rig.get_path_to(bones.near_arm), upper_weights)
	add_bone(rig.get_path_to(bones.near_fore), lower_weights)
