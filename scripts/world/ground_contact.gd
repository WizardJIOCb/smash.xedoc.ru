extends Node2D
## Soft planted-foot contact for the new painted cast, on the same sole plane as bodies.

const SoftSpot = preload("res://scripts/world/soft_spot.gd")

var run: Node
var _soft_spot: Texture2D


func _init(world: Node = null) -> void:
	run = world
	name = "GroundContact"


func _ready() -> void:
	z_index = -1
	z_as_relative = false
	_soft_spot = SoftSpot.texture()


func _process(_delta: float) -> void:
	visible = is_instance_valid(run) and not run.front.is_open()
	if visible:
		queue_redraw()


func _draw() -> void:
	if not is_instance_valid(run):
		return
	for enemy in run.enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.kind == "drone":
			continue
		var rig: Node2D = enemy.rig
		var size: float = rig.body_scale
		var sole_y: float = enemy.global_position.y + 10
		for side: String in ["far", "near"]:
			var ankle: Vector2 = rig.bones[side + "_foot"].global_position
			var height := maxf(0, sole_y - ankle.y - size)
			var strength := 1.0 - clampf(height / (24 * size), 0, 0.8)
			var at := to_local(Vector2(ankle.x - rig.scale.x * 2.5, sole_y + 0.5))
			var half := Vector2(19, 2.66) * size
			draw_texture_rect(
				_soft_spot,
				Rect2(at - half, half * 2),
				false,
				Color(0.015, 0.025, 0.025, 0.19 * strength)
			)
