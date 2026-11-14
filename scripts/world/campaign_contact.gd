extends RefCounted
## Resolve room obstacles before a projectile can hit a guard behind them.

const Armory = preload("res://scripts/systems/armory.gd")


static func intercept_player_fire(run, rules: Node2D, delta: float) -> void:
	if rules.kind not in ["vines", "roofs"]:
		return
	for index in range(run.armory.bullets.size() - 1, -1, -1):
		var bullet: Dictionary = run.armory.bullets[index]
		var start: Vector2 = bullet.at
		var finish: Vector2 = start + bullet.velocity * delta
		finish = _before_guard(run, start, finish)
		var sweep := Rect2(start, Vector2.ZERO).expand(finish).grow(2)
		if rules.attack(run, int(bullet.serial), sweep, int(bullet.damage)):
			run.armory.bullets.remove_at(index)
	for item: Dictionary in run.armory.pickups:
		if not item.get("thrown", false):
			continue
		var start: Vector2 = item.at
		var finish := _before_guard(run, start, start + item.velocity * delta)
		var sweep := Rect2(start, Vector2.ZERO).expand(finish).grow(6)
		if rules.attack(run, int(item.serial), sweep, int(run.armory.tuning.throw_damage)):
			item.thrown = false
			item.velocity = Vector2(-item.velocity.x * 0.15, -90)


static func _before_guard(run, start: Vector2, finish: Vector2) -> Vector2:
	var fraction := 1.0
	for enemy: Node2D in run.enemies:
		if enemy.dead:
			continue
		var hit := Armory._segment_rect(start, finish, enemy.hurtbox().grow(2))
		if hit >= 0:
			fraction = minf(fraction, hit)
	return start.lerp(finish, fraction)
