extends Node2D
## Composition module: owns pickups/ammunition/projectiles, never changes run state.
## Caller resolves projectile_hit against its own damage, blood and score rules.

signal projectile_hit(
	target: Node2D, serial: int, amount: int, at: Vector2, axis: Vector2, kind: String
)
signal changed
signal shot(id: String, at: Vector2)

const HeldWeapon = preload("res://scripts/view/held_weapon.gd")
const ORDER = ["fists", "knuckles", "bat", "shovel", "hockey", "pistol", "rifle"]

var tuning: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
var hero: Node2D
var equipped: String = "fists"
var inventory: Array[String] = ["fists"]
var ammunition: Dictionary = {}
var pickups: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var shots_fired: int = 0
var bullet_hits: int = 0
var reloads: int = 0
var visual: Node2D
var interact_caption: String = "E"
var ground_y: float = 555.0
var throws: int = 0
var thrown_hits: int = 0

var _reload_left: float = 0.0
var _reload_weapon: String = ""
var _cooldown: float = 0.0
var _held: bool = false
var _playing: bool = true
var _serial: int = -1000000
var _clock: float = 0.0


func configure(actor: Node2D) -> void:
	hero = actor
	ground_y = hero.position.y
	process_priority = 60
	z_index = 24
	visual = HeldWeapon.new()
	visual.z_index = -3
	add_child(visual)
	hero.combat.started.connect(_swing_started)
	reset()


func reset(keep_inventory: bool = false) -> void:
	bullets.clear()
	clear_pickups()
	_reload_left = 0
	_reload_weapon = ""
	_cooldown = 0
	_held = false
	if not keep_inventory:
		inventory.assign(["fists"])
		ammunition.clear()
		equipped = "fists"
		shots_fired = 0
		bullet_hits = 0
		reloads = 0
		throws = 0
		thrown_hits = 0
	_refresh()


func clear_pickups() -> void:
	for item: Dictionary in pickups:
		item.visual.queue_free()
	pickups.clear()


func spawn_pickups(items: Array) -> void:
	clear_pickups()
	for item: Dictionary in items:
		var id := str(item.get("id", ""))
		if not tuning.weapons.has(id) or id == "fists":
			continue
		var art := HeldWeapon.new()
		art.equip(id)
		art.position = Vector2(float(item.x), float(item.y) - 18)
		art.rotation = -0.16
		add_child(art)
		pickups.append(
			{"id": id, "at": art.position, "visual": art, "reserve": int(item.get("reserve", -1))}
		)
	queue_redraw()


func interact() -> bool:
	if not is_instance_valid(hero) or hero.ragdoll_active or not _playing:
		return false
	var closest := -1
	var distance := float(tuning.pickup_radius)
	for index in range(pickups.size()):
		var separation: float = hero.global_position.distance_to(to_global(pickups[index].at))
		if separation < distance:
			distance = separation
			closest = index
	if closest < 0:
		return false
	var item: Dictionary = pickups.pop_at(closest)
	if item.has("ammo"):
		var previous: Dictionary = ammunition.get(item.id, {}).duplicate()
		grant(item.id, 0)
		if previous.is_empty():
			ammunition[item.id] = item.ammo.duplicate()
		else:
			ammunition[item.id] = previous
			ammunition[item.id].reserve += int(item.ammo.loaded) + int(item.ammo.reserve)
		changed.emit()
	else:
		grant(item.id, int(item.reserve))
	item.visual.queue_free()
	return true


func drop(floor_y: float) -> bool:
	if not _can_use() or equipped == "fists":
		return false
	var id := equipped
	var art := HeldWeapon.new()
	art.equip(id)
	art.position = to_local(hero.bones.near_hand.global_position)
	add_child(art)
	var item := {
		"id": id,
		"at": art.position,
		"visual": art,
		"reserve": -1,
		"velocity": Vector2(hero.facing * 140, -120),
		"floor": floor_y - 18
	}
	if ammunition.has(id):
		item["ammo"] = ammunition[id].duplicate()
		ammunition.erase(id)
	pickups.append(item)
	inventory.erase(id)
	hero.combat.interrupt()
	equipped = "fists"
	_cancel_reload()
	_refresh()
	return true


func grant(id: String, reserve: int = -1) -> void:
	if not tuning.weapons.has(id):
		return
	var spec: Dictionary = tuning.weapons[id]
	if id not in inventory:
		inventory.append(id)
		if spec.mode == "ranged":
			ammunition[id] = {
				"loaded": int(spec.capacity),
				"reserve": int(spec.reserve) if reserve < 0 else reserve
			}
	elif spec.mode == "ranged":
		# A spare weapon gives one magazine; reserves always stay finite.
		ammunition[id].reserve = mini(
			int(ammunition[id].reserve) + (int(spec.capacity) if reserve < 0 else reserve),
			maxi(int(spec.reserve), reserve)
		)
	hero.combat.interrupt()
	equipped = id
	_cancel_reload()
	_refresh()


func cycle() -> void:
	if not _playing or not is_instance_valid(hero) or hero.ragdoll_active:
		return
	var current: int = ORDER.find(equipped)
	for offset in range(1, ORDER.size() + 1):
		var candidate: String = ORDER[(current + offset) % ORDER.size()]
		if candidate in inventory:
			hero.combat.interrupt()
			equipped = candidate
			_cancel_reload()
			_refresh()
			return


func reload() -> bool:
	var spec: Dictionary = tuning.weapons[equipped]
	if spec.mode != "ranged" or _reload_left > 0 or not _can_use():
		return false
	var ammo: Dictionary = ammunition[equipped]
	if int(ammo.loaded) >= int(spec.capacity) or int(ammo.reserve) <= 0:
		return false
	_reload_weapon = equipped
	_reload_left = float(spec.reload)
	changed.emit()
	return true


func before_attack(kind: String) -> bool:
	if kind != "punch" or tuning.weapons[equipped].mode != "ranged":
		return true
	if int(ammunition[equipped].loaded) <= 0 and _can_use() and _reload_left <= 0:
		_throw_empty_weapon()
	else:
		_fire()
	return false


func trigger(held: bool) -> void:
	_held = held


func is_ranged() -> bool:
	return tuning.weapons[equipped].mode == "ranged"


func melee_damage(base: int, kind: String) -> int:
	if kind != "punch" or is_ranged():
		return base
	return roundi(base * float(tuning.weapons[equipped].damage))


func melee_tip(original: Vector2, kind: String) -> Vector2:
	if kind != "punch" or is_ranged() or equipped == "fists":
		return original
	_update_visual()
	var reach := float(tuning.weapons[equipped].reach)
	if equipped == "bat" and visual.grip_active:
		var grip_end := (
			(float(visual.grip_data.shaft_start) - float(visual.grip_data.pivot[0]))
			* float(visual.grip_data.scale)
		)
		reach = grip_end + (reach - grip_end) * hero.melee_length
	return visual.to_global(Vector2(reach, 0))


func melee_area(base: Rect2, kind: String, tip: Vector2) -> Rect2:
	if kind != "punch" or is_ranged() or equipped == "fists":
		return base
	return (
		base
		. expand(melee_tip(tip, kind))
		. expand(hero.bones.near_hand.to_global(Vector2(0, 7)))
		. grow(4)
	)


func advance(delta: float, enemies: Array, playing: bool) -> void:
	_playing = playing
	visual.visible = is_instance_valid(hero) and hero.visible and not hero.ragdoll_active
	if is_instance_valid(hero) and hero.ragdoll_active:
		hero.bat_grip_active = false
		hero.bones.near_hand.get_node("fist_back").visible = true
		hero.bones.far_hand.get_node("fist").visible = true
	if not playing:
		_held = false
		return
	_clock += delta
	hero.held_firearm = equipped if is_ranged() else ""
	hero.held_melee = equipped if not is_ranged() else ""
	hero.combat.weapon = equipped
	hero.firearm_reloading = _reload_left > 0
	_cooldown = maxf(0, _cooldown - delta)
	visual.flash = maxf(0, visual.flash - delta)
	if _reload_left > 0:
		_reload_left = maxf(0, _reload_left - delta)
		if _reload_left == 0:
			_complete_reload()
	if _held and is_ranged() and bool(tuning.weapons[equipped].automatic):
		_fire()
	hero.firearm_recoil = visual.flash / 0.065
	_advance_bullets(delta, enemies)
	for item: Dictionary in pickups:
		if item.has("velocity"):
			var previous: Vector2 = item.at
			item.velocity.y += 720 * delta
			item.at += item.velocity * delta
			if item.get("thrown", false):
				_throw_contact(item, previous, enemies)
			item.at.x = clampf(item.at.x, 28, 1252)
			item.visual.rotation += delta * item.velocity.x / 45
			if item.at.y >= float(item.floor) and item.velocity.y > 0:
				item.at.y = item.floor
				item.erase("velocity")
				item.visual.rotation = -0.16
		item.visual.position = item.at
		if not item.has("velocity"):
			item.visual.position.y += sin(_clock * 2.8 + item.at.x) * 3
	visual.queue_redraw()
	queue_redraw()


func stats() -> Dictionary:
	var state := {
		"id": equipped,
		"name": tuning.weapons[equipped].name,
		"inventory": inventory.duplicate(),
		"ranged": is_ranged(),
		"loaded": 0,
		"reserve": 0,
		"capacity": 0,
		"reload": _reload_left,
		"reload_progress": 0.0,
		"shots": shots_fired,
		"bullet_hits": bullet_hits,
		"bullets": bullets.size(),
		"pickups": pickups.size(),
		"throws": throws,
		"thrown_hits": thrown_hits
	}
	if is_ranged():
		state.loaded = ammunition[equipped].loaded
		state.reserve = ammunition[equipped].reserve
		state.capacity = tuning.weapons[equipped].capacity
		if _reload_left > 0:
			state.reload_progress = 1.0 - _reload_left / float(tuning.weapons[equipped].reload)
	return state


func _process(_delta: float) -> void:
	_update_visual()


func _update_visual() -> void:
	if not is_instance_valid(hero) or not is_instance_valid(visual):
		return
	var hand: Bone2D = hero.bones.near_hand
	visual.global_position = hand.to_global(Vector2(0, 7))
	visual.grip_active = equipped == "bat" and hero.bat_grip_active
	if visual.grip_active:
		visual.global_position = hero.to_global(hero.melee_origin)
		visual.bat_length = hero.melee_length
	var facing: float = hero.facing
	var angle := -0.8
	if is_ranged():
		angle = hero.firearm_angle
	elif equipped == "bat":
		angle = hero.melee_angle
	else:
		var envelope: Vector2 = hero.combat.envelope()
		if hero.combat.kind == "punch" and hero.combat.elapsed >= 0:
			angle = lerpf(-0.8, 0.08, envelope.x) - envelope.y * 0.6
	visual.rotation = angle * facing
	visual.scale = Vector2(facing, 1) * hero.global_scale.abs()


func _swing_started(kind: String, _side: String, _air: bool, _low: bool) -> void:
	if kind == "punch" and equipped not in ["fists", "knuckles"] and not is_ranged():
		# The prop stays in its actual hand, including every buffered follow-up.
		hero.combat.side = "near"


func _can_use() -> bool:
	return _playing and is_instance_valid(hero) and not hero.ragdoll_active and not hero.blocking


func _throw_empty_weapon() -> void:
	drop(ground_y)
	var item: Dictionary = pickups.back()
	item.velocity = Vector2(hero.facing * 520, -90)
	item["thrown"] = true
	_serial -= 1
	item["serial"] = _serial
	throws += 1
	hero.combat.request("punch", hero.airborne, hero.crouch_requested)
	hero.combat.side = "near"


func _fire() -> bool:
	if not _can_use() or _cooldown > 0 or _reload_left > 0 or not is_ranged():
		return false
	var ammo: Dictionary = ammunition[equipped]
	if int(ammo.loaded) <= 0 or bullets.size() >= int(tuning.bullet_limit):
		return false
	var spec: Dictionary = tuning.weapons[equipped]
	ammo.loaded -= 1
	_cooldown = float(spec.cooldown)
	_serial -= 1
	shots_fired += 1
	_update_visual()
	var at := visual.to_global(visual.muzzle())
	bullets.append(
		{
			"at": at,
			"previous": at,
			"velocity": Vector2(hero.facing * float(spec.speed), 0),
			"life": float(tuning.bullet_lifetime),
			"serial": _serial,
			"damage": int(spec.damage)
		}
	)
	visual.flash = 0.065
	hero.firearm_recoil = 1.0
	shot.emit(equipped, at)
	changed.emit()
	return true


func _throw_contact(item: Dictionary, previous: Vector2, enemies: Array) -> void:
	var start := to_global(previous)
	var finish := to_global(item.at)
	var nearest := 1.01
	var victim: Node2D
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		var hit := -1.0
		if enemy.dead:
			if is_instance_valid(enemy.corpse):
				var at: Vector2 = enemy.corpse.contact(
					Rect2(start, Vector2.ZERO).expand(finish).grow(8), finish
				)
				if at != Vector2.INF:
					hit = start.distance_to(at) / maxf(0.01, start.distance_to(finish))
		else:
			hit = _segment_rect(start, finish, enemy.hurtbox().grow(8))
		if hit >= 0 and hit < nearest:
			nearest = hit
			victim = enemy
	if not is_instance_valid(victim):
		return
	item.thrown = false
	item.at = previous.lerp(item.at, nearest)
	var axis: Vector2 = item.velocity.normalized()
	item.velocity = Vector2(-item.velocity.x * 0.15, -90)
	thrown_hits += 1
	projectile_hit.emit(
		victim, int(item.serial), int(tuning.throw_damage), to_global(item.at), axis, "throw"
	)


func _advance_bullets(delta: float, enemies: Array) -> void:
	for index in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[index]
		var start: Vector2 = bullet.at
		var finish: Vector2 = start + bullet.velocity * delta
		var nearest := 1.01
		var victim: Node2D
		for enemy: Node2D in enemies:
			if not is_instance_valid(enemy):
				continue
			var hit := -1.0
			if enemy.dead:
				if not is_instance_valid(enemy.corpse):
					continue
				var at: Vector2 = enemy.corpse.contact(
					Rect2(start, Vector2.ZERO).expand(finish).grow(2), finish
				)
				if at != Vector2.INF:
					hit = clampf(
						(
							(at - start).dot(finish - start)
							/ maxf(0.01, start.distance_squared_to(finish))
						),
						0,
						1
					)
			else:
				hit = _segment_rect(start, finish, enemy.hurtbox().grow(2))
			if hit >= 0 and hit < nearest:
				nearest = hit
				victim = enemy
		var obstruction := get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(start, finish, 8)
		)
		if not obstruction.is_empty():
			var wall_fraction: float = (
				start.distance_to(obstruction.position) / maxf(0.01, start.distance_to(finish))
			)
			if wall_fraction <= nearest:
				bullets.remove_at(index)
				continue
		if is_instance_valid(victim):
			bullet_hits += 1
			projectile_hit.emit(
				victim,
				int(bullet.serial),
				int(bullet.damage),
				start.lerp(finish, nearest),
				bullet.velocity.normalized(),
				"bullet"
			)
			bullets.remove_at(index)
			continue
		bullet.previous = start
		bullet.at = finish
		bullet.life -= delta
		if float(bullet.life) <= 0:
			bullets.remove_at(index)


static func _segment_rect(start: Vector2, finish: Vector2, rect: Rect2) -> float:
	var direction := finish - start
	var enter := 0.0
	var exit := 1.0
	for axis in range(2):
		if absf(direction[axis]) < 0.001:
			if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]:
				return -1
			continue
		var near_t: float = (rect.position[axis] - start[axis]) / direction[axis]
		var far_t: float = (rect.end[axis] - start[axis]) / direction[axis]
		enter = maxf(enter, minf(near_t, far_t))
		exit = minf(exit, maxf(near_t, far_t))
		if enter > exit:
			return -1
	return enter


func _complete_reload() -> void:
	if _reload_weapon != equipped or not ammunition.has(equipped):
		return
	var ammo: Dictionary = ammunition[equipped]
	var transfer := mini(
		int(tuning.weapons[equipped].capacity) - int(ammo.loaded), int(ammo.reserve)
	)
	ammo.loaded += transfer
	ammo.reserve -= transfer
	reloads += 1
	_reload_weapon = ""
	changed.emit()


func _cancel_reload() -> void:
	_reload_left = 0
	_reload_weapon = ""
	_held = false


func _refresh() -> void:
	if is_instance_valid(hero):
		hero.held_firearm = equipped if is_ranged() else ""
		hero.held_melee = equipped if not is_ranged() else ""
		hero.combat.weapon = equipped
		hero.firearm_reloading = _reload_left > 0
		if equipped != "bat" or hero.ragdoll_active:
			hero.bat_grip_active = false
			hero.bones.near_hand.get_node("fist_back").visible = true
			hero.bones.far_hand.get_node("fist").visible = true
	if is_instance_valid(visual):
		visual.equip(equipped)
	changed.emit()
	queue_redraw()


func _draw() -> void:
	for bullet: Dictionary in bullets:
		var at: Vector2 = to_local(bullet.at)
		var tail: Vector2 = to_local(bullet.at - bullet.velocity.normalized() * 30)
		draw_line(tail, at, Color(1, 0.69, 0.29, 0.8), 2, true)
		draw_circle(at, 2, Color("ffe7b0"))
	var font := ThemeDB.fallback_font
	for item: Dictionary in pickups:
		var at: Vector2 = item.at
		draw_ellipse_shadow(at + Vector2(18, 18))
		var nearby := (
			is_instance_valid(hero)
			and hero.global_position.distance_to(to_global(at)) < float(tuning.pickup_radius)
		)
		var text := (interact_caption + " · " if nearby else "") + str(tuning.weapons[item.id].name)
		draw_string(
			font,
			at + Vector2(-12, -28),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			15,
			Color("ead09b") if nearby else Color("a6b6a6")
		)


func draw_ellipse_shadow(at: Vector2) -> void:
	draw_set_transform(at, 0, Vector2(1, 0.2))
	draw_circle(Vector2.ZERO, 32, Color(0.03, 0.05, 0.04, 0.32))
	draw_set_transform(Vector2.ZERO)


func snapshot() -> Dictionary:
	return {
		"inventory": inventory.duplicate(),
		"ammunition": ammunition.duplicate(true),
		"equipped": equipped
	}


func restore(state: Dictionary) -> void:
	reset(true)
	hero.combat.interrupt()
	inventory.assign(state.get("inventory", ["fists"]))
	ammunition = state.get("ammunition", {}).duplicate(true)
	equipped = str(state.get("equipped", "fists"))
	_refresh()
