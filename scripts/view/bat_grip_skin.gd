extends Polygon2D
## Only the furry wrist ends flex; fingers and the wrapped handle stay rigid.

var wrists: Dictionary = {}
var axes: Dictionary = {}


func setup(painting: Texture2D, spec: Dictionary) -> void:
	texture = painting
	var rig := Skeleton2D.new()
	add_child(rig)
	skeleton = get_path_to(rig)
	var base := Bone2D.new()
	base.set_autocalculate_length_and_angle(false)
	base.length = 1
	rig.add_child(base)
	base.rest = base.transform
	var factor := float(spec.scale)
	var pivot := Vector2(spec.pivot[0], spec.pivot[1])
	for side: String in ["near", "far"]:
		var joint := Vector2(spec[side + "_wrist"][0], spec[side + "_wrist"][1])
		var cuff := Vector2(spec[side + "_cuff"][0], spec[side + "_cuff"][1])
		var bone := Bone2D.new()
		bone.position = (joint - pivot) * factor
		bone.set_autocalculate_length_and_angle(false)
		bone.length = 1
		rig.add_child(bone)
		bone.rest = bone.transform
		wrists[side] = bone
		axes[side] = (cuff - joint).normalized()
	var points := PackedVector2Array()
	var texcoords := PackedVector2Array()
	var weights: Array[PackedFloat32Array] = [
		PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array()
	]
	var faces: Array[PackedInt32Array] = []
	var columns := int(spec.skin_grid[0])
	var rows := int(spec.skin_grid[1])
	for row in range(rows + 1):
		for col in range(columns + 1):
			var pixel := Vector2(
				float(col) / columns * float(spec.shaft_start),
				float(row) / rows * painting.get_height()
			)
			points.append((pixel - pivot) * factor)
			texcoords.append(pixel)
			var near_weight := _weight(pixel, spec, "near")
			var far_weight := _weight(pixel, spec, "far")
			weights[0].append(1.0 - near_weight - far_weight)
			weights[1].append(near_weight)
			weights[2].append(far_weight)
	for row in range(rows):
		for col in range(columns):
			var a := row * (columns + 1) + col
			faces.append(PackedInt32Array([a, a + 1, a + columns + 2]))
			faces.append(PackedInt32Array([a, a + columns + 2, a + columns + 1]))
	polygon = points
	uv = texcoords
	polygons = faces
	add_bone(rig.get_path_to(base), weights[0])
	for index in range(2):
		add_bone(rig.get_path_to(wrists[["near", "far"][index]]), weights[index + 1])


func follow(side: String, direction: Vector2) -> void:
	wrists[side].rotation = wrapf(direction.angle() - axes[side].angle(), -PI, PI)


func _weight(pixel: Vector2, spec: Dictionary, side: String) -> float:
	var joint := Vector2(spec[side + "_wrist"][0], spec[side + "_wrist"][1])
	var cuff := Vector2(spec[side + "_cuff"][0], spec[side + "_cuff"][1])
	var along := (pixel - joint).dot((cuff - joint).normalized())
	var weight := smoothstep(0, joint.distance_to(cuff) * 0.85, along)
	var fade: Array = spec[side + "_skin_fade"]
	var horizontal := 1.0 - smoothstep(fade[0], fade[1], pixel.x)
	var vertical := smoothstep(fade[2], fade[3], pixel.y)
	if side == "near":
		return weight * vertical * horizontal
	return weight * (1.0 - vertical) * horizontal
