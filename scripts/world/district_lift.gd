extends Node2D
## Root advances once per physics tick, carries grounded feet, then queries surface().

signal departed(upward: bool)
signal arrived(upper: bool)

var tuning: Dictionary = JSON.parse_string(
	FileAccess.get_file_as_string("res://data/lift_tuning.json")
)
var previous_y: float = 555.0
var delta_y: float = 0.0
var moving: bool = false
var upper: bool = false
var body: AnimatableBody2D
var _y: float = 555.0
var _target: float = 555.0
var _speed: float = 0.0
var _font: Font


func configure(settings: Dictionary) -> void:
	tuning.merge(settings, true)
	_y = float(tuning.bottom)
	previous_y = _y
	_target = _y
	_speed = 0.0
	moving = false
	upper = false
	delta_y = 0.0
	if is_instance_valid(body):
		body.position = Vector2(float(tuning.x), _y + float(tuning.shoe_offset))
		var shape := body.get_child(0) as CollisionShape2D
		(shape.shape as RectangleShape2D).size = Vector2(tuning.width, tuning.platform_depth)
	queue_redraw()


func _ready() -> void:
	configure({})
	z_index = -1
	_font = ThemeDB.fallback_font
	body = AnimatableBody2D.new()
	body.name = "Carrier"
	body.collision_layer = int(tuning.terrain_layer)
	body.collision_mask = 0
	body.sync_to_physics = true
	body.position = Vector2(tuning.x, _y + float(tuning.shoe_offset))
	add_child(body)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(tuning.width, tuning.platform_depth)
	shape.shape = rectangle
	shape.position.y = float(tuning.platform_depth) / 2.0
	shape.one_way_collision = true
	body.add_child(shape)


func surface() -> Rect2:
	return Rect2(
		to_global(Vector2(float(tuning.x) - float(tuning.width) / 2.0, _y)),
		Vector2(tuning.width, tuning.platform_depth)
	)


func physical_surface() -> Rect2:
	var deck := surface()
	deck.position.y += float(tuning.shoe_offset)
	return deck


func board(feet: Vector2) -> bool:
	var deck := surface()
	return (
		feet.x >= deck.position.x
		and feet.x <= deck.end.x
		and absf(feet.y - deck.position.y) <= float(tuning.boarding_tolerance)
	)


func carry_delta(feet: Vector2, airborne: bool = false) -> float:
	var deck := surface()
	var old_top := to_global(Vector2(float(tuning.x), previous_y)).y
	if (
		not airborne
		and feet.x >= deck.position.x
		and feet.x <= deck.end.x
		and absf(feet.y - old_top) <= float(tuning.boarding_tolerance)
	):
		return delta_y
	return 0.0


func activate(feet: Vector2) -> bool:
	if moving:
		return false
	var near_shaft := absf(feet.x - float(tuning.x)) <= float(tuning.width) * 0.6
	var at_bottom := absf(feet.y - float(tuning.bottom)) <= float(tuning.boarding_tolerance)
	var at_top := absf(feet.y - float(tuning.top)) <= float(tuning.boarding_tolerance)
	if board(feet):
		_target = float(tuning.bottom) if upper else float(tuning.top)
	elif near_shaft and (at_bottom or at_top):
		_target = float(tuning.bottom) if at_bottom else float(tuning.top)
	else:
		return false
	moving = true
	departed.emit(not upper)
	queue_redraw()
	return true


func advance(delta: float, paused: bool = false) -> void:
	previous_y = _y
	delta_y = 0.0
	if paused or not moving or delta <= 0:
		return
	var distance := absf(_target - _y)
	var acceleration := float(tuning.acceleration)
	var desired := minf(float(tuning.speed), sqrt(2.0 * acceleration * distance))
	_speed = move_toward(_speed, desired, acceleration * delta)
	_y = move_toward(_y, _target, _speed * delta)
	delta_y = _y - previous_y
	body.position.y = _y + float(tuning.shoe_offset)
	if is_equal_approx(_y, _target):
		_speed = 0.0
		moving = false
		upper = is_equal_approx(_target, float(tuning.top))
		arrived.emit(upper)
	queue_redraw()


func _draw() -> void:
	var x := float(tuning.x)
	var half := float(tuning.width) / 2.0
	var top := float(tuning.top)
	var bottom := float(tuning.bottom)
	var mast_top := top - float(tuning.headroom)
	var deck_y := _y + float(tuning.shoe_offset)
	var steel := Color("293b3d")
	var edge := Color("648080")
	var gold := Color("c8a65a")
	for side: float in [-1.0, 1.0]:
		var rail_x := x + side * (half + 12)
		draw_rect(Rect2(rail_x - 6, mast_top, 12, bottom - mast_top + 35), Color("14292c"))
		draw_line(Vector2(rail_x - 2, mast_top + 5), Vector2(rail_x - 2, bottom + 30), edge, 2)
		draw_line(
			Vector2(x + side * (half - 12), mast_top + 18),
			Vector2(x + side * (half - 12), deck_y),
			Color("73877d"),
			3
		)
		for bolt_y in range(int(mast_top) + 20, int(bottom) + 30, 45):
			draw_circle(Vector2(rail_x + 2, bolt_y), 2.5, gold)
	draw_rect(Rect2(x - half - 24, mast_top, float(tuning.width) + 48, 22), steel)
	draw_line(Vector2(x - half - 24, mast_top), Vector2(x + half + 24, mast_top), edge, 3)
	var deck := Rect2(x - half, deck_y, float(tuning.width), float(tuning.platform_depth))
	draw_rect(deck.grow(2), Color("101d20"))
	draw_rect(deck, steel)
	for stripe_x in range(int(x - half) + 5, int(x + half) - 4, 24):
		draw_line(Vector2(stripe_x, deck_y + 15), Vector2(stripe_x + 12, deck_y + 3), gold, 7)
	draw_rect(Rect2(x - half, deck_y, float(tuning.width), 4), Color("a5afa1"))
	for side: float in [-1.0, 1.0]:
		draw_rect(Rect2(x + side * (half - 6) - 4, deck_y - 17, 8, 17), steel)
		draw_circle(Vector2(x + side * (half - 6), deck_y - 14), 3, Color("e2be75"))
	var motor := Rect2(x - half - 53, mast_top + 29, 32, 54)
	draw_rect(motor.grow(2), Color("14272a"))
	draw_rect(motor, steel)
	for index in range(4):
		draw_line(
			motor.position + Vector2(6, 10 + index * 5),
			motor.position + Vector2(25, 10 + index * 5),
			edge,
			2
		)
	draw_circle(motor.position + Vector2(16, 42), 5, Color("dda453") if moving else Color("8ebf9b"))
	if _font != null:
		var text := "ВВЕРХ" if moving and _target < _y else ("ВНИЗ" if moving else "E · ЛИФТ")
		draw_string(
			_font,
			Vector2(x - 32, deck_y + 41),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color("e8d8ae")
		)
