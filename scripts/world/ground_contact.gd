extends Node2D
## Soft planted-foot contact for the new painted cast, on the same sole plane as bodies.

var run: Node


func _init(world: Node = null) -> void:
	run = world
	name = "GroundContact"


func _ready() -> void:
	z_index = -1
	z_as_relative = false


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
			for ring in range(4):
				draw_set_transform(at, 0, Vector2(1, 0.14))
				draw_circle(
					Vector2.ZERO,
					(19.0 - ring * 3) * size,
					Color(0.015, 0.025, 0.025, (0.035 + ring * 0.012) * strength)
				)
		draw_set_transform(Vector2.ZERO)
