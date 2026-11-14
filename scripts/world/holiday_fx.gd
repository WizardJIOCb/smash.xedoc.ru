extends Node2D

const WARM := Color("f3bd70")
const PINE := Color("1e3435")
const ORNAMENTS := [Color("c55f50"), Color("e7b66a"), Color("6b9c99")]

static var textures: Dictionary = {}

@export_range(0, 160, 1) var snow_count: int = 84
@export var wind: float = 12.0
@export var snow_speed: float = 30.0
@export var tree_at := Vector2(1110, 555)
@export var tree_ornaments: bool = true
@export var powered: bool = false

var paused: bool = false
var clock: float = 0.0
var _brightness: float = 0.4
var _last_powered: bool = false
var _lamps: Array[Vector2] = []
var _glows: MultiMeshInstance2D
var _bulbs: MultiMeshInstance2D
var _snow: MultiMeshInstance2D
var _sparkles: MultiMeshInstance2D
var _wire_vertices := PackedVector3Array()
var _wire_colors := PackedColorArray()


func _ready() -> void:
	z_index = 1
	_brightness = 1.0 if powered else 0.4
	_last_powered = powered
	_build_wires()
	_glows = _batch("glow", 52)
	_bulbs = _batch("bulb", 39)
	_snow = _batch("snow", 160)
	_sparkles = _batch("sparkle", 15)
	for span in range(3):
		var start := Vector2(48 + span * 408, 164 - span % 2 * 24)
		for index in range(13):
			var progress := float(index) / 12.0
			_lamps.append(start + Vector2(progress * 392, sin(progress * PI) * 28 + 6))
	_animate()
	queue_redraw()


func _process(delta: float) -> void:
	if paused or not visible:
		return
	clock += delta
	_brightness = move_toward(_brightness, 1.0 if powered else 0.4, delta * 0.8)
	if powered != _last_powered:
		_last_powered = powered
		queue_redraw()
	_animate()


func set_cleared(value: bool) -> void:
	powered = value


func _draw() -> void:
	if tree_ornaments:
		_draw_ornaments()


func _build_wires() -> void:
	for span in range(3):
		var start := Vector2(48 + span * 408, 164 - span % 2 * 24)
		var before := start
		for step in range(1, 25):
			var progress := float(step) / 24.0
			var at := start + Vector2(progress * 392, sin(progress * PI) * 28)
			_wire(before, at, 2.0)
			before = at
		for index in range(13):
			var progress := float(index) / 12.0
			var at := start + Vector2(progress * 392, sin(progress * PI) * 28 + 6)
			_wire(at - Vector2(0, 7), at, 1.5)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _wire_vertices
	arrays[Mesh.ARRAY_COLOR] = _wire_colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var wires := MeshInstance2D.new()
	wires.mesh = mesh
	add_child(wires)
	_wire_vertices.clear()
	_wire_colors.clear()


func _wire(from: Vector2, to: Vector2, width: float) -> void:
	var normal := from.direction_to(to).orthogonal()
	var offsets := [-width * 0.5 - 0.5, -width * 0.5 + 0.5, width * 0.5 - 0.5, width * 0.5 + 0.5]
	var alpha := [0.0, 1.0, 1.0, 0.0]
	for band in range(3):
		for corner: int in [0, 1, 2, 2, 1, 3]:
			var edge := band + corner / 2
			var point := (from if corner % 2 == 0 else to) + normal * float(offsets[edge])
			_wire_vertices.append(Vector3(point.x, point.y, 0))
			_wire_colors.append(Color(PINE, alpha[edge]))


func _draw_ornaments() -> void:
	for index in range(12):
		var row := index / 3
		var column := index % 3
		var spread := 22.0 + row * 17.0
		var at := tree_at + Vector2((column - 1) * spread, -214 + row * 49 + column * 7)
		var color: Color = ORNAMENTS[index % ORNAMENTS.size()]
		draw_line(at - Vector2(0, 7), at, Color("7c8e7c"), 1.0, true)
		draw_circle(at + Vector2(1, 1), 5, Color("19292b"), true, -1.0, true)
		draw_circle(at, 4, color, true, -1.0, true)
		draw_circle(at + Vector2(-1.4, -1.5), 1.2, Color("f5deb8"), true, -1.0, true)
	if powered:
		var star_at := tree_at + Vector2(0, -281)
		var star := PackedVector2Array()
		for index in range(10):
			var angle := -PI * 0.5 + index * PI / 5.0
			star.append(star_at + Vector2.from_angle(angle) * (10 if index % 2 == 0 else 4))
		draw_colored_polygon(star, WARM)


func _animate() -> void:
	_glows.multimesh.visible_instance_count = 52 if powered and tree_ornaments else 39
	for slot in range(_lamps.size()):
		var index := slot % 13
		var span := slot / 13
		var shimmer := 0.9 + sin(clock * 0.8 + index * 1.4 + span) * 0.1
		var intensity := _brightness * shimmer
		_put(_glows, slot, _lamps[slot], 32, Color(WARM, intensity))
		_put(_bulbs, slot, _lamps[slot], 8, Color(WARM, 0.4 + intensity * 0.6))
	if powered and tree_ornaments:
		for index in range(12):
			var row := index / 3
			var column := index % 3
			var spread := 22.0 + row * 17.0
			var at := tree_at + Vector2((column - 1) * spread, -214 + row * 49 + column * 7)
			_put(_glows, 39 + index, at, 32, Color(ORNAMENTS[index % 3], _brightness * 0.7))
		_put(_glows, 51, tree_at + Vector2(0, -281), 32, Color(WARM, _brightness))
	var snow_slot := 0
	var sparkle_slot := 0
	for index in range(snow_count):
		var depth := 0.4 + float(index % 5) * 0.15
		var x := fposmod(index * 239.71 + clock * wind * depth, 1344.0) - 32.0
		var y := fposmod(index * 107.37 + clock * snow_speed * depth, 756.0) - 24.0
		x += sin(clock * 0.45 + index * 1.73) * 12 * depth
		var at := Vector2(x, y)
		var opacity := (0.19 + depth * 0.2) * (0.7 if y > 555 else 1.0)
		var color := Color(0.84, 0.91, 0.93, opacity)
		var size := (0.8 + depth) * 4.0 / 1.5
		if index % 11 == 0:
			_put(_sparkles, sparkle_slot, at, size, color)
			sparkle_slot += 1
		else:
			_put(_snow, snow_slot, at, size, color)
			snow_slot += 1
	_snow.multimesh.visible_instance_count = snow_slot
	_sparkles.multimesh.visible_instance_count = sparkle_slot


func _batch(kind: String, capacity: int) -> MultiMeshInstance2D:
	if not textures.has(kind):
		textures[kind] = _mask(kind)
	var batch := MultiMeshInstance2D.new()
	batch.texture = textures[kind]
	batch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	batch.multimesh = MultiMesh.new()
	batch.multimesh.transform_format = MultiMesh.TRANSFORM_2D
	batch.multimesh.use_colors = true
	batch.multimesh.mesh = quad
	batch.multimesh.instance_count = capacity
	batch.multimesh.visible_instance_count = capacity if kind == "bulb" else 0
	batch.multimesh.custom_aabb = AABB(Vector3(-64, -64, -1), Vector3(1408, 848, 2))
	add_child(batch)
	return batch


func _put(batch: MultiMeshInstance2D, index: int, at: Vector2, size: float, color: Color) -> void:
	batch.multimesh.set_instance_transform_2d(index, Transform2D(0, Vector2.ONE * size, 0, at))
	batch.multimesh.set_instance_color(index, color)


static func _mask(kind: String) -> Texture2D:
	# Four reusable soft masks replace hundreds of tessellated antialiased circles.
	var pixels := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var q := Vector2(x + 0.5, y + 0.5) - Vector2(32, 32)
			var alpha := 0.0
			if kind == "glow":
				var distance := q.length() * 0.5
				for ring in range(3):
					var coverage := 1.0 - smoothstep(12.5 - ring * 3, 13.5 - ring * 3, distance)
					alpha = 1.0 - (1.0 - alpha) * (1.0 - coverage * (0.022 + ring * 0.012))
			elif kind == "bulb":
				alpha = 1.0 - smoothstep(2.3, 3.3, q.length() * 0.125)
			else:
				q /= 16.0
				alpha = 1.0 - smoothstep(1.3, 1.7, q.length())
				if kind == "sparkle":
					var arm := minf(absf(q.x), absf(q.y))
					alpha = maxf(alpha, 1.0 - smoothstep(0.3, 0.5, arm))
			pixels.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(pixels)
