extends Node2D

const WARM := Color("f3bd70")
const PINE := Color("1e3435")
const ORNAMENTS := [Color("c55f50"), Color("e7b66a"), Color("6b9c99")]

@export_range(0, 160, 1) var snow_count: int = 84
@export var wind: float = 12.0
@export var snow_speed: float = 30.0
@export var tree_at := Vector2(1110, 555)
@export var tree_ornaments: bool = true
@export var powered: bool = false

var paused: bool = false
var clock: float = 0.0
var _brightness: float = 0.4


func _ready() -> void:
	z_index = 1
	_brightness = 1.0 if powered else 0.4
	queue_redraw()


func _process(delta: float) -> void:
	if paused or not visible:
		return
	clock += delta
	_brightness = move_toward(_brightness, 1.0 if powered else 0.4, delta * 0.8)
	queue_redraw()


func set_cleared(value: bool) -> void:
	powered = value


func _draw() -> void:
	_draw_garlands()
	if tree_ornaments:
		_draw_ornaments()
	_draw_snow()


func _draw_garlands() -> void:
	for span in range(3):
		var start := Vector2(48 + span * 408, 164 - span % 2 * 24)
		var points := PackedVector2Array()
		for step in range(25):
			var progress := float(step) / 24.0
			points.append(start + Vector2(progress * 392, sin(progress * PI) * 28))
		draw_polyline(points, PINE, 2.0, true)
		for index in range(13):
			var progress := float(index) / 12.0
			var at := start + Vector2(progress * 392, sin(progress * PI) * 28 + 6)
			draw_line(at - Vector2(0, 7), at, PINE, 1.5, true)
			var shimmer := 0.9 + sin(clock * 0.8 + index * 1.4 + span) * 0.1
			var intensity := _brightness * shimmer
			_soft_glow(at, WARM, intensity)
			draw_circle(at, 2.8, Color(WARM, 0.4 + intensity * 0.6), true, -1.0, true)


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
			_soft_glow(at, color, _brightness * 0.7)
	if powered:
		var star_at := tree_at + Vector2(0, -281)
		_soft_glow(star_at, WARM, _brightness)
		var star := PackedVector2Array()
		for index in range(10):
			var angle := -PI * 0.5 + index * PI / 5.0
			star.append(star_at + Vector2.from_angle(angle) * (10 if index % 2 == 0 else 4))
		draw_colored_polygon(star, WARM)


func _draw_snow() -> void:
	for index in range(snow_count):
		var depth := 0.4 + float(index % 5) * 0.15
		var x := fposmod(index * 239.71 + clock * wind * depth, 1344.0) - 32.0
		var y := fposmod(index * 107.37 + clock * snow_speed * depth, 756.0) - 24.0
		x += sin(clock * 0.45 + index * 1.73) * 12 * depth
		var at := Vector2(x, y)
		var opacity := (0.19 + depth * 0.2) * (0.7 if y > 555 else 1.0)
		var color := Color(0.84, 0.91, 0.93, opacity)
		draw_circle(at, 0.8 + depth, color, true, -1.0, true)
		if index % 11 == 0:
			draw_line(at - Vector2(2, 0), at + Vector2(2, 0), color, 0.8, true)
			draw_line(at - Vector2(0, 2), at + Vector2(0, 2), color, 0.8, true)


func _soft_glow(at: Vector2, color: Color, intensity: float) -> void:
	for ring in range(3):
		draw_circle(
			at, 13 - ring * 3, Color(color, intensity * (0.022 + ring * 0.012)), true, -1.0, true
		)
