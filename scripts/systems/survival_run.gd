extends RefCounted
## Host-owned endless waves; only the current wave's enemies stay in the scene.

const ROOM_ID := 255

var tuning: Dictionary = JSON.parse_string(
	FileAccess.get_file_as_string("res://data/survival.json")
)
var enabled: bool = false
var wave: int = 0
var completed: int = 0
var rest: float = 0
var players: int = 1
var arena_index: int = -1
var pending: Array = []
var spawn_wait: float = 0


func begin(party_size: int) -> void:
	enabled = true
	wave = 0
	completed = 0
	players = clampi(party_size, 1, 16)
	rest = float(tuning.opening_seconds)
	pending.clear()
	spawn_wait = 0


func plan(number: int, party_size: int) -> Array:
	var count := mini(
		int(tuning.max_enemies),
		(
			int(tuning.base_enemies)
			+ floori(number * float(tuning.enemies_per_wave))
			+ ceili(sqrt(party_size) - 1)
		)
	)
	var pool: Array = tuning.enemy_pool.slice(0, mini(tuning.enemy_pool.size(), 2 + number))
	var result: Array = []
	for index in range(count):
		result.append(pool[(number * 3 + index * 5) % pool.size()])
	if number % int(tuning.boss_every) == 0:
		result[0] = tuning.bosses[(number / int(tuning.boss_every) - 1) % tuning.bosses.size()]
	return result


func enemy_tuning(base: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	result.health = roundi(
		(
			float(base.health)
			* (1 + (wave - 1) * float(tuning.health_per_wave))
			* (1 + (players - 1) * float(tuning.health_per_teammate))
		)
	)
	result.damage = roundi(
		float(base.damage) * minf(3, 1 + (wave - 1) * float(tuning.damage_per_wave))
	)
	result.speed = float(base.speed) * minf(1.65, 1 + (wave - 1) * float(tuning.speed_per_wave))
	return result


func advance(run, delta: float) -> void:
	if not enabled or run.run_state != "playing":
		return
	if rest > 0:
		rest = maxf(0, rest - delta)
		if rest == 0:
			_start_wave(run)
		return
	spawn_wait -= delta
	if not pending.is_empty() and run._remaining() < int(tuning.alive_limit) and spawn_wait <= 0:
		var kind: String = str(pending.pop_front())
		var at := 110.0 if (pending.size() + wave) % 2 == 0 else 1160.0
		if absf(at - run.moose.position.x) < 190:
			at = 1160.0 if at < 640 else 110.0
		run._spawn_enemy([kind, at, float(run.rooms[arena_index].floor)])
		spawn_wait = float(tuning.spawn_interval)
	if wave > 0 and pending.is_empty() and run._remaining() == 0:
		completed = wave
		rest = float(tuning.rest_seconds)
		_refresh_party(run)
		run._feedback(Vector2(640, 320), "ВОЛНА %d ЗАКРЫТА" % wave, Color("e2b36e"), "relay")
		var weapons: Array = tuning.weapon_cycle
		var weapon: String = str(weapons[(wave - 1) % weapons.size()])
		run.armory.spawn_pickups([[weapon, 640, float(run.rooms[arena_index].floor) - 22]])
		if is_instance_valid(run.coop) and run.coop.active:
			for actor in run.coop.actors.values():
				actor.armory.pickups = run.armory.pickups


func _start_wave(run) -> void:
	for enemy in run.enemies:
		run.remove_child(enemy)
		enemy.queue_free()
	run.enemies.clear()
	run.effects.projectiles.clear()
	wave += 1
	pending = plan(wave, players)
	spawn_wait = 0
	run._feedback(
		Vector2(640, 300),
		"ВОЛНА %d%s" % [wave, " · БОСС" if wave % int(tuning.boss_every) == 0 else ""],
		Color("e2b36e"),
		"relay"
	)


func _refresh_party(run) -> void:
	if run.health <= 0 and is_instance_valid(run.coop) and run.coop.active:
		run.coop._revive_host()
		run.health = int(tuning.revive_health)
	else:
		run.health = mini(100, run.health + int(tuning.heal_between_waves))
	if is_instance_valid(run.coop) and run.coop.active:
		for actor in run.coop.actors.values():
			if actor.health <= 0:
				actor.reset_at(Vector2(run.coop._safe_spawn(), float(run.rooms[arena_index].floor)))
				actor.health = int(tuning.revive_health)
			else:
				actor.health = mini(100, actor.health + int(tuning.heal_between_waves))


func snapshot() -> Dictionary:
	return {
		"enabled": enabled,
		"wave": wave,
		"completed": completed,
		"rest": rest,
		"players": players,
		"pending": pending.size()
	}


func apply_snapshot(state: Dictionary) -> void:
	enabled = bool(state.get("enabled", false))
	wave = int(state.get("wave", 0))
	completed = int(state.get("completed", 0))
	rest = float(state.get("rest", 0))
	players = int(state.get("players", 1))


func stats(run) -> Dictionary:
	return {"wave": maxi(1, wave), "kills": run.kills, "seconds": snappedf(run.elapsed_run, 0.01)}


func sync_hud(run) -> void:
	run.objective.text = "ВЫЖИВАНИЕ · ВОЛНА %d · %d ПОБЕЖДЕНО" % [maxi(1, wave), run.kills]
	if rest > 0:
		run.message.text = (
			"%s · следующая волна через %d · E — подобрать оружие"
			% [
				(
					"Приготовься"
					if wave == 0
					else "Выдохни. %d HP в подарок" % int(tuning.heal_between_waves)
				),
				ceili(rest)
			]
		)
	else:
		run.message.text = (
			"Врагов: %d · подкреплений: %d · %s/%s — бой · L — блок"
			% [
				run._remaining(),
				pending.size(),
				run.bindings.caption("strike"),
				run.bindings.caption("kick")
			]
		)
