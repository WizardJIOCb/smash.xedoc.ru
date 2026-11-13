extends MultiMeshInstance2D
## One instanced draw for an entire particle class, with pooled GPU storage.

static var textures: Dictionary = {}


func setup(kind: String, capacity: int) -> void:
	if not textures.has(kind):
		textures[kind] = _make_texture(kind)
	texture = textures[kind]
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = quad
	multimesh.instance_count = capacity
	multimesh.visible_instance_count = 0
	multimesh.custom_aabb = AABB(Vector3(-512, -512, -1), Vector3(2304, 1744, 2))


func put(index: int, at: Vector2, size: Vector2, angle: float, color: Color) -> void:
	multimesh.set_instance_transform_2d(index, Transform2D(angle, size, 0, at))
	multimesh.set_instance_color(index, color)


static func _make_texture(kind: String) -> Texture2D:
	# Generated once on scene load, never during a hit. White masks take instance tint.
	var pixels := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var q := (Vector2(x, y) + Vector2(0.5, 0.5) - Vector2(32, 32)) / 30.0
			var alpha: float
			var brightness := 1.0
			if kind == "mist":
				alpha = pow(maxf(0, 1.0 - q.length()), 2.0)
			elif kind == "rain_ring":
				alpha = 1.0 - smoothstep(0.04, 0.15, absf(q.length() - 0.77))
			elif kind == "drop":
				var head := 0.48 - q.distance_to(Vector2(0.25, 0))
				var tail := minf(minf(q.x + 0.95, 0.25 - q.x), (q.x + 0.95) * 0.35 - absf(q.y))
				alpha = smoothstep(-0.07, 0.04, maxf(head, tail))
			else:
				var edge := 0.65 - q.length()
				for lobe: Vector3 in [
					Vector3(-0.58, -0.1, 0.34),
					Vector3(0.5, 0.25, 0.38),
					Vector3(-0.2, 0.58, 0.28),
					Vector3(0.2, -0.52, 0.3)
				]:
					edge = maxf(edge, lobe.z - q.distance_to(Vector2(lobe.x, lobe.y)))
				alpha = smoothstep(-0.04, 0.04, edge)
				var grain := fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)
				brightness = 0.83 + grain * 0.12
				brightness += 0.05 * exp(-q.distance_squared_to(Vector2(-0.2, -0.2)) * 18)
			pixels.set_pixel(x, y, Color(brightness, brightness, brightness, alpha))
	return ImageTexture.create_from_image(pixels)
