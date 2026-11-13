extends Node2D
## Additive embers behind the rig, shock waves in front, night grade below HUD.

var hero: Node2D
var strength: float = 0.0
var time: float = 0.0
var wave_age: float = 2.0
var wave_at := Vector2.ZERO
var back: Node2D
var front: Node2D
var grade: ShaderMaterial


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	back = Node2D.new()
	back.z_index = -2
	back.material = additive
	back.draw.connect(_draw_aura)
	add_child(back)
	front = Node2D.new()
	front.z_index = 32
	front.material = additive
	front.draw.connect(_draw_wave)
	add_child(front)
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var screen := ColorRect.new()
	screen.size = Vector2(1280, 720)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade = ShaderMaterial.new()
	grade.shader = load("res://assets/shaders/blood_night.gdshader")
	screen.material = grade
	layer.add_child(screen)


func update(delta: float, enabled: bool) -> void:
	time += delta
	wave_age += delta
	strength = move_toward(strength, float(enabled), delta * 3.5)
	grade.set_shader_parameter("strength", strength)
	var center := hero.get_global_transform_with_canvas() * Vector2(0, -115)
	grade.set_shader_parameter("hero_center", center / Vector2(1280, 720))
	back.queue_redraw()
	front.queue_redraw()


func impulse(at: Vector2) -> void:
	wave_at = at
	wave_age = 0


func _draw_aura() -> void:
	if strength <= 0.001:
		return
	var at := hero.position
	for ring in range(6):
		back.draw_set_transform(at + Vector2(0, -115), 0, Vector2(0.55, 1.0))
		back.draw_circle(Vector2.ZERO, 145 - ring * 12, Color(0.85, 0.012, 0.04, 0.045 * strength))
	back.draw_set_transform(Vector2.ZERO)
	for index in range(34):
		var phase := fposmod(time * (0.55 + index % 3 * 0.1) + index * 0.173, 1.0)
		var x := sin(index * 7.21) * (43 + sin(phase * PI) * 13)
		var point := at + Vector2(x + sin(time * 4 + index) * 7, -12 - phase * 245)
		var opacity := sin(phase * PI) * strength
		back.draw_line(
			point,
			point + Vector2(sin(index) * 4, 15 + index % 5),
			Color(1, 0.045, 0.06, opacity * 0.65),
			1.5,
			true
		)
		back.draw_circle(point, 1.2 + index % 3 * 0.5, Color(1, 0.27, 0.12, opacity))
	back.draw_set_transform(at + Vector2(0, 3), 0, Vector2(1, 0.2))
	for radius in [45, 56, 68]:
		back.draw_arc(
			Vector2.ZERO,
			radius + sin(time * 5) * 2,
			0,
			TAU,
			64,
			Color(1, 0.06, 0.09, strength * 0.45),
			2,
			true
		)
	back.draw_set_transform(Vector2.ZERO)


func _draw_wave() -> void:
	if wave_age >= 0.65:
		return
	var progress := wave_age / 0.65
	for ring in range(3):
		var radius := 20 + progress * 230 - ring * 12
		if radius > 0:
			front.draw_arc(
				wave_at,
				radius,
				0,
				TAU,
				96,
				Color(1, 0.14, 0.12, (1 - progress) * (0.8 - ring * 0.2)),
				4 - ring,
				true
			)
	for index in range(12):
		var direction := Vector2.from_angle(index * TAU / 12 + 0.13)
		front.draw_line(
			wave_at + direction * progress * 160,
			wave_at + direction * progress * 235,
			Color(1, 0.42, 0.23, (1 - progress) * 0.7),
			2,
			true
		)
