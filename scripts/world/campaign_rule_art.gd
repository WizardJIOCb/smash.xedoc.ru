extends Node2D
## Bounded paint-only geometry. The room controller owns every collision and timer.

const DECK = preload("res://assets/environment/service-ledge.png")
const RIVER = preload("res://assets/environment/port-embankment.webp")
const CARGO = preload("res://assets/enemies/otter/extra.png")

var rules: Node2D
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func _draw() -> void:
	if not is_instance_valid(rules) or rules.kind.is_empty():
		return
	match rules.kind:
		"port":
			_draw_port()
		"metro":
			_draw_metro()
		"vines", "roofs":
			if rules.kind == "roofs":
				_draw_roofs()
			for item: Dictionary in rules.objects:
				_draw_object(item)


func _draw_gap(water: bool) -> void:
	var t: Dictionary = rules.tuning
	if not bool(t.gap_enabled):
		return
	var left := float(t.gap[0])
	var right := float(t.gap[1])
	var y := float(t.floor)
	draw_rect(Rect2(left, y - 3, right - left, 720 - y + 3), Color("101f2c"))
	if water:
		draw_texture_rect_region(
			RIVER,
			Rect2(left, y + 3, right - left, 720 - y),
			Rect2(800, 410, 300, 70),
			Color(0.58, 0.75, 0.8)
		)
		for row in range(9):
			var line_y := y + 23 + row * 18
			for col in range(5):
				var x := (
					left
					+ fmod(
						col * 91 + sin(rules.elapsed * 1.4 + row) * 12 + row * 21, right - left - 42
					)
				)
				draw_line(Vector2(x, line_y), Vector2(x + 32, line_y), Color("52766f", 0.38), 2)
	else:
		for row in range(4):
			for col in range(7):
				var window := Vector2(left + 18 + col * 37, y + 40 + row * 35)
				draw_rect(Rect2(window, Vector2(8, 16)), Color("866e3e", 0.22))
	for x: float in [left, right]:
		draw_line(Vector2(x, y - 3), Vector2(x, 720), Color("0b171c"), 8)
		draw_line(
			Vector2(x + (-6 if x == left else 6), y + 9),
			Vector2(x + (-6 if x == left else 6), 720),
			Color("66756a"),
			3
		)


func _draw_port() -> void:
	_draw_gap(true)
	var t: Dictionary = rules.tuning
	var deck: Rect2 = rules.deck_rect()
	var y := deck.position.y + float(t.foot_offset)
	var left := deck.position.x
	var right := deck.end.x
	var rail := Color("253d3f")
	draw_line(
		Vector2(t.gap[0] - 100, y + 38), Vector2(t.gap[1] + 100, y + 38), Color("97a69b", 0.42), 2
	)
	draw_texture_rect(DECK, Rect2(left - 6, y - 4, deck.size.x + 12, 42), false)
	for x in range(int(left) + 10, int(right), 26):
		draw_line(Vector2(x, y + 10), Vector2(x + 12, y + 22), Color("9b8350", 0.5), 4)
	for side: float in [-1, 1]:
		var x: float = rules.deck_x + side * (deck.size.x / 2 - 14)
		draw_rect(Rect2(x - 4, y - 28, 8, 27), rail)
		draw_circle(Vector2(x, y - 28), 4, Color("e2c684"))
	var cargo := Rect2(rules.deck_x + 20, y - 49, 48, 47)
	draw_texture_rect(CARGO, cargo, false)
	_text(
		Vector2(left + 16, y + 51),
		"E · ГРУЗ" if rules.dock_wait > 0 else "→" if rules.deck_right else "←",
		15
	)
	if bool(t.gap_enabled):
		_text(Vector2(t.gap[0] + 12, 697), "ЧЁРНАЯ ВОДА · ЖДИ ГРУЗ", 15, Color("a2bcb0"))


func _draw_metro() -> void:
	var t: Dictionary = rules.tuning
	var floor_y := float(t.floor)
	for niche: Array in t.niches:
		var box := Rect2(niche[0], floor_y - 198, niche[1], 210)
		draw_style_box(_box(Color("122d2b"), Color("73aa81")), box)
		draw_rect(
			Rect2(box.position + Vector2(8, 8), box.size - Vector2(16, 12)), Color("091e23", 0.78)
		)
		_text(box.position + Vector2(17, 28), "НИША", 19, Color("9dcc9d"))
		_text(Vector2(box.position.x + 20, floor_y + 4), "УКРЫТИЕ", 13, Color("94ba99"))
	draw_line(Vector2(0, floor_y + 35), Vector2(1280, floor_y + 35), Color("e3b05e"), 4)
	for x in range(5, 1280, 38):
		draw_line(Vector2(x, floor_y + 39), Vector2(x + 18, floor_y + 55), Color("89724b"), 5)
	var warning: bool = rules.wave_state == "warning"
	var lamp := Color("ec9160") if warning else Color("7fae95")
	draw_style_box(_box(Color("11252a"), lamp), Rect2(502, floor_y - 249, 276, 47))
	var caption := (
		"ПОЕЗД · %.1f с" % rules.wave_time
		if warning
		else "ВОЗДУШНАЯ ВОЛНА" if rules.wave_state == "wave" else "ЛИНИЯ ОТКРЫТА"
	)
	_text(Vector2(520, floor_y - 219), caption, 20, lamp)
	if warning:
		for x in range(35, 1280, 92):
			var a := Vector2(x, floor_y - 173)
			draw_polyline(
				PackedVector2Array([a, a + Vector2(10, -10), a + Vector2(20, 0)]),
				Color(lamp, 0.5 + sin(rules.elapsed * 12) * 0.3),
				3
			)
	if rules.wave_state == "wave":
		var center := float(rules.wave_x)
		for row in range(8):
			var y := floor_y - float(t.wave_top) + row * 10
			var shift: float = (row % 3) * 13
			draw_line(
				Vector2(center - 115 + shift, y),
				Vector2(center + 83 - shift, y),
				Color("b5dfd9", 0.13 + (row % 3) * 0.1),
				3,
				true
			)
		for row in range(3):
			draw_arc(
				Vector2(center - 30 * rules.wave_direction, floor_y - 120),
				23 + row * 15,
				-1.0,
				1.0,
				16,
				Color("c3e6df", 0.28),
				2,
				true
			)


func _draw_roofs() -> void:
	_draw_gap(false)
	var t: Dictionary = rules.tuning
	if not bool(t.gap_enabled) or t.supports.is_empty():
		return
	var start := Vector2(
		float(t.gap[0]) - float(t.bridge_overlap), float(t.floor) + float(t.foot_offset)
	)
	var length := float(t.gap[1]) - float(t.gap[0]) + float(t.bridge_overlap) * 2
	var progress := smoothstep(0, 1, float(rules.bridge_progress))
	draw_set_transform(start, lerpf(-PI / 2, 0, progress))
	draw_style_box(_box(Color("354742"), Color("d1b473")), Rect2(0, 0, length, 36))
	for x in range(8, int(length) - 10, 32):
		draw_line(Vector2(x, 3), Vector2(x + 14, 17), Color("c2a163"), 5)
	_text(Vector2(37, 29), "ГОРОДУ — ГРУЗ", 17, Color("ead7a4"))
	draw_set_transform(Vector2.ZERO)
	if not rules.bridge_down:
		_text(Vector2(float(t.supports[0].x) - 25, float(t.floor) - 178), "J / K · ОПОРА", 17)


func _draw_object(item: Dictionary) -> void:
	var rect: Rect2 = item.rect
	if item.health > 0:
		if item.type == "vine":
			_draw_vines(rect, float(item.flash))
		elif item.type == "cover":
			draw_style_box(
				_box(Color("42534b") if item.flash <= 0 else Color("b9a06a"), Color("84917b")), rect
			)
			for y in range(int(rect.position.y) + 12, int(rect.end.y) - 4, 19):
				draw_line(
					Vector2(rect.position.x + 7, y), Vector2(rect.end.x - 7, y), Color("243b38"), 5
				)
			draw_line(rect.position + Vector2(8, 8), rect.end - Vector2(8, 8), Color("b2a477"), 5)
			_text(rect.position + Vector2(-4, -14), "УКРЫТИЕ", 15)
		else:
			draw_rect(rect, Color("3f514c") if item.flash <= 0 else Color("d6bc7e"))
			draw_line(rect.position + Vector2(4, 3), rect.end - Vector2(4, 3), Color("b1a875"), 6)
			draw_line(
				Vector2(rect.end.x - 4, rect.position.y + 3),
				Vector2(rect.position.x + 4, rect.end.y - 3),
				Color("879c89"),
				5
			)
			for side: float in [0.15, 0.85]:
				draw_circle(rect.position.lerp(rect.end, side), 4, Color("e0b56b"))
		var health_width := rect.size.x * float(item.health) / float(item.maximum)
		draw_rect(Rect2(rect.position.x, rect.position.y - 7, rect.size.x, 3), Color("132927"))
		draw_rect(Rect2(rect.position.x, rect.position.y - 7, health_width, 3), Color("b4ce83"))
	else:
		for index in range(5):
			var x := rect.position.x + index * rect.size.x / 5
			draw_line(
				Vector2(x, rect.end.y - 4),
				Vector2(x + 12, rect.end.y - 11 + index % 2 * 5),
				Color("5e7852") if item.type == "vine" else Color("75816a"),
				5
			)
		if item.type == "vine" and item.required:
			_text(
				Vector2(rect.position.x - 30, rect.end.y + 28), "ПРОХОД ОТКРЫТ", 13, Color("aad29a")
			)
	if item.debris > 0:
		var progress := 1 - float(item.debris) / float(rules.tuning.debris_seconds)
		for index in range(8):
			var offset := Vector2(
				(index - 3.5) * 12 * progress, -sin(progress * PI) * (25 + index % 3 * 12)
			)
			_leaf(
				Vector2(rect.get_center().x, rect.end.y - 6) + offset,
				index + progress * 3,
				Color("abc287", 1 - progress)
			)


func _draw_vines(rect: Rect2, flash: float) -> void:
	for stem in range(5):
		var x := rect.position.x + 8 + stem * (rect.size.x - 16) / 4
		var points := PackedVector2Array()
		for step in range(8):
			var progress := step / 7.0
			var at := Vector2(
				x + sin(step * 1.8 + stem) * 11, lerpf(rect.end.y, rect.position.y, progress)
			)
			points.append(at)
			if step > 0:
				_leaf(at + Vector2(-8, 0), -0.6, Color("638b58") if flash <= 0 else Color("e0c277"))
				_leaf(at + Vector2(9, -6), 0.7, Color("8ba663"))
		draw_polyline(points, Color("263f31"), 7, true)
		draw_polyline(points, Color("739052"), 2, true)
	_text(rect.position + Vector2(-1, -18), "J / K", 18)


func _leaf(at: Vector2, angle: float, color: Color) -> void:
	var axis := Vector2.from_angle(angle) * 14
	var side := axis.orthogonal().normalized() * 5
	draw_colored_polygon(PackedVector2Array([at - axis, at + side, at + axis, at - side]), color)


func _text(at: Vector2, caption: String, size: int, color: Color = Color("e6d6b0")) -> void:
	if _font != null:
		draw_string_outline(
			_font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color("10222a")
		)
		draw_string(_font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _box(fill: Color, edge: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(2)
	return box
