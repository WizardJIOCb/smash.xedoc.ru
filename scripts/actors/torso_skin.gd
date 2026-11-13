extends Polygon2D
## Small native skinned mesh: waist follows hips, shoulders follow chest.


func setup(rig: Skeleton2D, hips: Bone2D, chest: Bone2D) -> void:
	name = "JacketSkin"
	texture = load("res://assets/characters/los/torso.png")
	z_index = 10
	z_as_relative = false
	rig.add_child(self)
	skeleton = get_path_to(rig)
	var points := PackedVector2Array()
	var texcoords := PackedVector2Array()
	var waist_weights := PackedFloat32Array()
	var chest_weights := PackedFloat32Array()
	var faces: Array[PackedInt32Array] = []
	var size := Vector2(68, 79)
	var origin := hips.position + chest.position - size * Vector2(0.5, 0.88)
	for row in range(7):
		var v := row / 6.0
		for col in range(5):
			var u := col / 4.0
			points.append(origin + Vector2(u, v) * size)
			texcoords.append(Vector2(u, v) * texture.get_size())
			var weight := 1.0 - smoothstep(0.38, 1.0, v)
			chest_weights.append(weight)
			waist_weights.append(1.0 - weight)
	for row in range(6):
		for col in range(4):
			var a := row * 5 + col
			faces.append(PackedInt32Array([a, a + 1, a + 6]))
			faces.append(PackedInt32Array([a, a + 6, a + 5]))
	polygon = points
	uv = texcoords
	polygons = faces
	add_bone(rig.get_path_to(hips), waist_weights)
	add_bone(rig.get_path_to(chest), chest_weights)
