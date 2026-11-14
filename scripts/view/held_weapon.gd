extends Node2D
## Small hand-painted-looking silhouettes; all dimensions are in rig pixels.

var weapon_id: String = "fists"
var flash: float = 0.0
var painting: Texture2D
var grip_active: bool = false
var bat_length: float = 1.0
var bat_grip: Texture2D = load("res://assets/weapons/bat-held-v3.png")
var grip_data: Dictionary = (
	JSON.parse_string(FileAccess.get_file_as_string("res://data/weapon_grips.json")).bat
)


func equip(id: String) -> void:
	weapon_id = id
	var path := "res://assets/weapons/" + id + ".png"
	painting = load(path) if ResourceLoader.exists(path) else null
	queue_redraw()


func _draw() -> void:
	if weapon_id == "bat" and grip_active:
		var factor := float(grip_data.scale)
		var pivot := Vector2(grip_data.pivot[0], grip_data.pivot[1])
		var pixels := bat_grip.get_size()
		var split := float(grip_data.shaft_start)
		var start := -pivot * factor
		draw_texture_rect_region(
			bat_grip, Rect2(start, Vector2(split, pixels.y) * factor), Rect2(0, 0, split, pixels.y)
		)
		start.x += split * factor
		draw_texture_rect_region(
			bat_grip,
			Rect2(start, Vector2((pixels.x - split) * bat_length, pixels.y) * factor),
			Rect2(split, 0, pixels.x - split, pixels.y)
		)
		return
	if painting != null:
		var widths := {
			"bat": 112.0,
			"shovel": 96.0,
			"hockey": 102.0,
			"knuckles": 23.0,
			"pistol": 52.0,
			"rifle": 98.0
		}
		var width: float = widths[weapon_id]
		var height := width * painting.get_height() / painting.get_width()
		var grip := -22.0 if weapon_id == "rifle" else -10.0
		draw_texture_rect(painting, Rect2(grip, -height / 2, width, height), false)
	else:
		match weapon_id:
			"knuckles":
				_knuckles()
			"bat":
				_bat()
			"shovel":
				_shovel()
			"hockey":
				_hockey()
			"pistol", "rifle":
				_gun(weapon_id == "rifle")
	if flash > 0:
		var muzzle := muzzle().x
		draw_set_transform(Vector2(0, self.muzzle().y + 3))
		_poly(
			[
				Vector2(muzzle, -9),
				Vector2(muzzle + 8, -13),
				Vector2(muzzle + 5, -5),
				Vector2(muzzle + 24, -4),
				Vector2(muzzle + 7, 0),
				Vector2(muzzle + 13, 8),
				Vector2(muzzle + 2, 3),
				Vector2(muzzle - 2, 5)
			],
			Color(1, 0.63, 0.18, minf(1, flash * 18))
		)
		draw_circle(Vector2(muzzle + 4, -2), 4, Color(1, 0.93, 0.65))


func _poly(points: Array, color: Color) -> void:
	var packed := PackedVector2Array(points)
	draw_colored_polygon(packed, color)
	packed.append(packed[0])
	draw_polyline(packed, color.darkened(0.48), 1.4, true)


func _bat() -> void:
	_poly(
		[
			Vector2(-10, -3),
			Vector2(10, -3),
			Vector2(27, -6),
			Vector2(57, -8),
			Vector2(63, -5),
			Vector2(64, 3),
			Vector2(58, 7),
			Vector2(27, 6),
			Vector2(10, 3),
			Vector2(-10, 3)
		],
		Color("996438")
	)
	draw_line(Vector2(16, -1), Vector2(59, -3), Color("d1a369"), 2, true)
	draw_line(Vector2(26, 3), Vector2(55, 4), Color("694524"), 1, true)
	for x in range(-7, 12, 3):
		draw_line(Vector2(x, -3), Vector2(x + 2, 3), Color("4b3930"), 2, true)
	draw_line(Vector2(-10, -5), Vector2(-10, 5), Color("bf8950"), 4, true)


func _shovel() -> void:
	draw_line(Vector2(-10, 0), Vector2(51, 0), Color("3e2c20"), 7, true)
	draw_line(Vector2(-10, -1), Vector2(51, -1), Color("b38958"), 4, true)
	_poly(
		[
			Vector2(43, -7),
			Vector2(56, -15),
			Vector2(71, -13),
			Vector2(77, -5),
			Vector2(77, 8),
			Vector2(61, 15),
			Vector2(46, 9)
		],
		Color("6c7774")
	)
	draw_line(Vector2(47, 0), Vector2(69, -1), Color("b6bbb0"), 2, true)
	draw_line(Vector2(71, -11), Vector2(75, 6), Color("d0c7ac"), 2, true)
	for point in [Vector2(59, 8), Vector2(68, 5), Vector2(55, -8)]:
		draw_circle(point, 2, Color("8b5432"))
	draw_arc(Vector2(-12, 0), 8, PI / 2, PI * 1.5, 12, Color("4d5651"), 4, true)


func _hockey() -> void:
	_poly(
		[
			Vector2(-12, -3),
			Vector2(63, -3),
			Vector2(77, -23),
			Vector2(88, -24),
			Vector2(76, 4),
			Vector2(66, 7),
			Vector2(-12, 3)
		],
		Color("aa8354")
	)
	draw_line(Vector2(10, -1), Vector2(65, -1), Color("dbba87"), 1.5, true)
	for x in range(-10, 11, 3):
		draw_line(Vector2(x, -3), Vector2(x + 2, 3), Color("d2c5a8"), 2, true)
	for x in range(70, 82, 3):
		draw_line(Vector2(x, -15), Vector2(x + 2, -9), Color("393e3a"), 3, true)


func _knuckles() -> void:
	for y in [-9, -3, 3, 9]:
		draw_circle(Vector2(11, y), 4.2, Color("a37f36"))
		draw_arc(Vector2(11, y), 2.6, -PI / 2, PI / 2, 8, Color("ead28b"), 1.3, true)
	draw_line(Vector2(8, -10), Vector2(8, 10), Color("b9954e"), 3, true)


func _gun(long_gun: bool) -> void:
	var steel := Color("394648")
	if long_gun:
		_poly(
			[
				Vector2(-31, -9),
				Vector2(-12, -8),
				Vector2(-8, -4),
				Vector2(13, -9),
				Vector2(43, -8),
				Vector2(46, -4),
				Vector2(73, -4),
				Vector2(73, 1),
				Vector2(40, 1),
				Vector2(35, 5),
				Vector2(14, 6),
				Vector2(19, 20),
				Vector2(6, 21),
				Vector2(0, 7),
				Vector2(-6, 6),
				Vector2(-12, 17),
				Vector2(-19, 15),
				Vector2(-14, 2),
				Vector2(-31, 6)
			],
			steel
		)
		_poly([Vector2(18, -7), Vector2(42, -7), Vector2(40, 1), Vector2(18, 2)], Color("8c5436"))
		_poly(
			[Vector2(-30, -7), Vector2(-16, -6), Vector2(-15, 0), Vector2(-30, 4)], Color("8c5436")
		)
		draw_line(Vector2(46, -3), Vector2(72, -3), Color("95a19b"), 1, true)
		draw_line(Vector2(28, -12), Vector2(28, -8), steel, 3, true)
	else:
		_poly(
			[
				Vector2(-8, -11),
				Vector2(36, -11),
				Vector2(39, -7),
				Vector2(38, -1),
				Vector2(14, 0),
				Vector2(10, 5),
				Vector2(3, 6),
				Vector2(0, 17),
				Vector2(-12, 15),
				Vector2(-6, 0)
			],
			steel
		)
		draw_line(Vector2(-5, -9), Vector2(33, -9), Color("9da7a0"), 2, true)
		draw_line(Vector2(-8, 6), Vector2(0, 7), Color("645340"), 5, true)
		for x in range(17, 33, 4):
			draw_line(Vector2(x, -8), Vector2(x - 1, -3), Color("182326"), 1, true)
	draw_circle(Vector2(5, -3), 1.4, Color("c5ac70"))


func muzzle() -> Vector2:
	return Vector2(74, -11) if weapon_id == "rifle" else Vector2(39, -11)
