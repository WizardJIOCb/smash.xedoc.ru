extends Node2D

var texts: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var clock: float = 0.0
var seal: float = 1.0
var gate: Vector2 = Vector2(1170, 555)
var floor_y: float = 555
var hit_flash: float = 0.0


func burst(at: Vector2, caption: String, color: Color) -> void:
	texts.append({"at": at, "text": caption, "color": color, "age": 0.0})
	for index in range(12):
		var angle := index / 12.0 * TAU + 0.2
		sparks.append(
			{
				"at": at,
				"velocity": Vector2.from_angle(angle) * (55 + index % 3 * 30),
				"age": 0.0,
				"color": color
			}
		)
	hit_flash = 0.08


func _process(delta: float) -> void:
	clock += delta
	hit_flash = maxf(0, hit_flash - delta)
	for item: Dictionary in texts:
		item.age += delta
		item.at.y -= delta * 24
	texts = texts.filter(func(item: Dictionary) -> bool: return item.age < 1.0)
	for item: Dictionary in sparks:
		item.age += delta
		item.at += item.velocity * delta
		item.velocity.y += delta * 170
	sparks = sparks.filter(func(item: Dictionary) -> bool: return item.age < 0.5)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for item: Dictionary in texts:
		var color: Color = item.color
		color.a = minf(1, (1 - item.age) * 3)
		var point: Vector2 = item.at
		point.x -= font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x / 2
		draw_string(
			font,
			point + Vector2(1, 1),
			item.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			17,
			Color(0.02, 0.04, 0.06, color.a)
		)
		draw_string(font, point, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, color)
	for item: Dictionary in sparks:
		var color: Color = item.color
		color.a = (1 - item.age / 0.5) * 0.85
		draw_line(item.at, item.at - item.velocity * 0.025, color, 2, true)
	for item: Dictionary in projectiles:
		var at: Vector2 = item.at
		draw_circle(at, 9, Color(0.9, 0.18, 0.1, 0.14))
		draw_circle(at, 3.5, Color("e2b36e"))
		draw_line(at, at - Vector2(item.velocity).normalized() * 20, Color("e44a42"), 3, true)
	if seal <= 0.01:
		return
	# The Firewall has a broad translucent glow, moving grid and branching energy.
	for index in range(6):
		var width := 14.0 + index * 11
		draw_rect(
			Rect2(gate.x - width / 2, gate.y - 244, width, 248),
			Color(0.9, 0.13, 0.08, seal * 0.015)
		)
	for index in range(5):
		var points := PackedVector2Array()
		for step in range(22):
			points.append(
				Vector2(
					gate.x + sin(step * 1.5 + clock * 7 + index * 5) * (5 + index * 2),
					gate.y - step * 11
				)
			)
		draw_polyline(points, Color(0.92, 0.22, 0.14, seal * 0.2), 1.5, true)
	for row in range(10):
		var y := gate.y - fposmod(row * 24 + clock * 35, 240)
		draw_line(
			Vector2(gate.x - 19, y),
			Vector2(gate.x + 19, y),
			Color(0.95, 0.28, 0.14, seal * 0.2),
			1,
			true
		)
