extends Node2D
## Painted mechanic props. Geometry and timing stay in CampaignRules.

const ROOT := "res://assets/environment/props/"
const DECK = preload(ROOT + "port-carrier.png")
const WATER = preload(ROOT + "river-opening.png")
const ALLEY = preload(ROOT + "roof-opening.png")
const BANK = preload(ROOT + "masonry-bank.png")
const REFUGE = preload(ROOT + "metro-refuge.png")
const SIGNAL = preload(ROOT + "metro-signal.png")
const COVER = preload(ROOT + "roof-cover.png")
const VINES = preload(ROOT + "garden-thicket.png")
const SUPPORT = preload(ROOT + "bridge-support.png")
const BRIDGE = preload(ROOT + "billboard-bridge.png")
const WIND = preload("res://assets/shaders/campaign_wind.gdshader")
const FONT = preload("res://assets/fonts/Manrope.ttf")
const SoftSpot = preload("res://scripts/world/soft_spot.gd")

var rules: Node2D
var _wind_haze: Polygon2D
var _soft_spot: Texture2D


func _ready() -> void:
	_soft_spot = SoftSpot.texture()
	if rules.kind == "metro":
		_wind_haze = Polygon2D.new()
		_wind_haze.polygon = PackedVector2Array(
			[Vector2(-230, -110), Vector2(230, -110), Vector2(230, 110), Vector2(-230, 110)]
		)
		var material := ShaderMaterial.new()
		material.shader = WIND
		_wind_haze.material = material
		_wind_haze.visible = false
		add_child(_wind_haze)


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


func _sole() -> float:
	return float(rules.tuning.floor) + float(rules.tuning.foot_offset)


func _draw_gap(water: bool) -> void:
	var t: Dictionary = rules.tuning
	if not bool(t.gap_enabled):
		return
	var left := float(t.gap[0])
	var right := float(t.gap[1])
	var top := _sole()
	var void_rect := Rect2(left, top, right - left, 720 - top)
	draw_texture_rect(
		WATER if water else ALLEY,
		void_rect,
		false,
		Color.WHITE if water else Color(0.73, 0.79, 0.8)
	)
	var wall_height := 726 - top
	draw_texture_rect(BANK, Rect2(left - 24, top - 5, 34, wall_height), false)
	draw_texture_rect(BANK, Rect2(right + 24, top - 5, -34, wall_height), false)


func _draw_port() -> void:
	_draw_gap(true)
	var deck: Rect2 = rules.deck_rect()
	var sole := deck.position.y + float(rules.tuning.foot_offset)
	# The front edge of the painted planks is the physical sole plane.
	draw_texture_rect(DECK, Rect2(deck.position.x - 6, sole - 16, deck.size.x + 12, 38), false)


func _draw_metro() -> void:
	var t: Dictionary = rules.tuning
	var floor_y := _sole()
	var warning: bool = rules.wave_state == "warning"
	var wave: bool = rules.wave_state == "wave"
	var pulse := 0.58 + sin(rules.elapsed * 10) * 0.42
	for niche: Array in t.niches:
		var width := float(niche[1]) + 26
		var box := Rect2(float(niche[0]) - 13, floor_y - 224, width, 226)
		_shadow(Vector2(box.get_center().x, floor_y + 2), width * 0.44, 5, 0.16)
		draw_texture_rect(REFUGE, box, false)
		if warning or wave:
			_glow(
				Vector2(box.get_center().x, floor_y - 161),
				Color(0.85, 0.72, 0.33),
				10,
				0.65 + pulse * 0.35
			)
	var sign := Rect2(967, floor_y - 286, 268, 87)
	draw_texture_rect(SIGNAL, sign, false)
	var lens := 0 if wave else 1 if warning else 2
	var signal_color := Color("ef6848") if wave else Color("efb44f") if warning else Color("8bc7a2")
	_glow(sign.position + Vector2(28 + lens * 28, 41), signal_color, 10, pulse if warning else 0.7)
	var caption := (
		"ПОЕЗД %.1f с" % rules.wave_time
		if warning
		else "ПРИЖМИСЬ К СТЕНЕ" if wave else "ПУТЬ СВОБОДЕН"
	)
	_text(sign.position + Vector2(115, 48), caption, 11, signal_color)
	if is_instance_valid(_wind_haze):
		_wind_haze.visible = wave
		_wind_haze.position = Vector2(float(rules.wave_x), floor_y - 82)
		_wind_haze.material.set_shader_parameter("clock", float(rules.elapsed))
		_wind_haze.material.set_shader_parameter("direction", float(rules.wave_direction))
	if wave:
		_draw_wind_leaves(floor_y)


func _draw_wind_leaves(floor_y: float) -> void:
	for index in range(5):
		var offset := fposmod(rules.elapsed * 127 + index * 53, 255) - 127
		var at := Vector2(
			rules.wave_x + offset, floor_y - 24 - index * 19 + sin(rules.elapsed * 6 + index) * 9
		)
		draw_set_transform(at, rules.elapsed * 7 + index)
		draw_texture_rect_region(
			VINES, Rect2(-5, -4, 10, 8), Rect2(24, 33, 35, 28), Color(0.8, 0.83, 0.64, 0.6)
		)
	draw_set_transform(Vector2.ZERO)


func _draw_roofs() -> void:
	_draw_gap(false)
	var t: Dictionary = rules.tuning
	if not bool(t.gap_enabled) or t.supports.is_empty():
		return
	var start := Vector2(float(t.gap[0]) - float(t.bridge_overlap), _sole())
	var length := float(t.gap[1]) - float(t.gap[0]) + float(t.bridge_overlap) * 2
	var progress := smoothstep(0, 1, float(rules.bridge_progress))
	draw_set_transform(start, lerpf(-PI / 2, 0, progress))
	draw_texture_rect(BRIDGE, Rect2(-6, -3, length + 12, 76), false)
	draw_set_transform(Vector2.ZERO)


func _draw_object(item: Dictionary) -> void:
	var rect: Rect2 = item.rect
	var texture: Texture2D = (
		VINES if item.type == "vine" else COVER if item.type == "cover" else SUPPORT
	)
	var base := rect.end.y + float(rules.tuning.foot_offset)
	if item.health <= 0:
		_draw_broken(item, texture, base)
		return
	var anchor := Vector2(rect.get_center().x, base)
	_shadow(anchor + Vector2(0, 2), rect.size.x * 0.65, 5, 0.19)
	var flash := float(item.flash) / float(rules.tuning.flash_seconds)
	var tint := Color(1 + flash * 0.35, 1 + flash * 0.16, 1)
	if item.type == "vine":
		draw_set_transform(anchor, sin(rules.elapsed * 1.2 + rect.position.x) * 0.012)
		draw_texture_rect(
			texture,
			Rect2(-rect.size.x / 2 - 14, -rect.size.y - 8, rect.size.x + 28, rect.size.y + 8),
			false,
			tint
		)
		draw_set_transform(Vector2.ZERO)
	else:
		var padding := 6.0 if item.type == "cover" else 5.0
		var shake := sin(rules.elapsed * 91) * flash * 2
		draw_texture_rect(
			texture,
			Rect2(
				rect.position.x - padding + shake,
				base - rect.size.y - 4,
				rect.size.x + padding * 2,
				rect.size.y + 4
			),
			false,
			tint
		)


func _draw_broken(item: Dictionary, texture: Texture2D, base: float) -> void:
	var rect: Rect2 = item.rect
	var airborne := float(item.debris) > 0
	var progress := 1 - float(item.debris) / float(rules.tuning.debris_seconds)
	var size := texture.get_size()
	for index in range(5):
		var arc := sin(progress * PI) * (24 + index * 5) if airborne else 0.0
		var at := Vector2(rect.position.x + rect.size.x * (index + 0.5) / 5, base + 3 - arc)
		var angle := (index - 2) * 0.17 + (progress * 3 if airborne else 0.0)
		draw_set_transform(at, angle)
		draw_texture_rect_region(
			texture,
			Rect2(-11, -7, 22, 14),
			Rect2(size.x * index / 5, size.y * 0.78, size.x / 5, size.y * 0.2),
			Color(0.76, 0.8, 0.71, 0.85)
		)
	draw_set_transform(Vector2.ZERO)


func _shadow(at: Vector2, width: float, height: float, opacity: float) -> void:
	draw_texture_rect(
		_soft_spot,
		Rect2(at - Vector2(width, height), Vector2(width, height) * 2),
		false,
		Color(0.025, 0.05, 0.045, opacity)
	)


func _glow(at: Vector2, color: Color, radius: float, strength: float) -> void:
	var half := Vector2.ONE * radius * 1.5
	draw_texture_rect(_soft_spot, Rect2(at - half, half * 2), false, Color(color, strength * 0.3))


func _text(at: Vector2, caption: String, size: int, color: Color) -> void:
	draw_string(FONT, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
