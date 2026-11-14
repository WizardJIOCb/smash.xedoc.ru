extends Node2D
## Root advances once per physics tick, carries grounded feet, then queries surface().

signal departed(upward: bool)
signal arrived(upper: bool)

const DECK = preload("res://assets/environment/props/port-carrier.png")
const MAST = preload("res://assets/environment/props/bridge-support.png")
const MOTOR = preload("res://assets/enemies/shield/weapon.png")
const FONT = preload("res://assets/fonts/Manrope.ttf")

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
	_font = FONT
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
	var bottom := float(tuning.bottom)
	var mast_top := float(tuning.top) - float(tuning.headroom)
	var deck_y := _y + float(tuning.shoe_offset)
	var mast_size := MAST.get_size()
	for side: float in [-1.0, 1.0]:
		var rail_x := x + side * (half + 12)
		draw_texture_rect_region(
			MAST,
			Rect2(rail_x - 8, mast_top, 16, bottom - mast_top + 35),
			Rect2(mast_size.x * 0.22, 0, mast_size.x * 0.18, mast_size.y)
		)
		var cable_x := x + side * (half - 12)
		draw_line(
			Vector2(cable_x + 1, mast_top + 12),
			Vector2(cable_x + 1, deck_y - 4),
			Color("152622"),
			3,
			true
		)
		draw_line(
			Vector2(cable_x, mast_top + 12), Vector2(cable_x, deck_y - 4), Color("829186"), 1, true
		)
	var texture_size := DECK.get_size()
	draw_texture_rect_region(
		DECK,
		Rect2(x - half - 24, mast_top - 2, float(tuning.width) + 48, 24),
		Rect2(0, texture_size.y * 0.42, texture_size.x, texture_size.y * 0.38)
	)
	draw_texture_rect(DECK, Rect2(x - half - 4, deck_y - 16, float(tuning.width) + 8, 38), false)
	draw_texture_rect(
		MOTOR, Rect2(x - half - 50, mast_top + 25, 34, 69), false, Color(0.8, 0.86, 0.81)
	)
	if _font != null:
		var text := "ВВЕРХ" if moving and _target < _y else ("ВНИЗ" if moving else "E · ЛИФТ")
		draw_string(
			_font,
			Vector2(x - 32, deck_y + 42),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color("e8d8ae")
		)
