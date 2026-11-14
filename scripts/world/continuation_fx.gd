extends RefCounted

const Enemy = preload("res://scripts/actors/district_enemy.gd")


func advance_lift(run, delta: float, paused: bool) -> void:
	if not is_instance_valid(run.carrier):
		return
	run.carrier.advance(delta, paused)
	if run.run_state == "playing":
		run.moose.position.y += run.carrier.carry_delta(run.moose.position, run.moose.airborne)
	if absf(run.carrier.delta_y) < 0.001:
		return
	var deck: Rect2 = run.carrier.surface()
	for enemy: Enemy in run.enemies:
		var corpse := enemy.corpse
		if not is_instance_valid(corpse) or not corpse.settled:
			continue
		var core: Vector2 = corpse.bodies.body.position
		if (
			core.x < deck.position.x
			or core.x > deck.end.x
			or absf(core.y - run.carrier.previous_y + 35) > 50
		):
			continue
		for body: RigidBody2D in corpse.physical_bodies:
			body.position.y += run.carrier.delta_y
		corpse.pose_dirty = true
	var planes: Array[Rect2] = run.blood.surfaces.filter(
		func(rect: Rect2) -> bool: return rect.size.x != deck.size.x
	)
	planes.append(run.carrier.physical_surface())
	run.blood.surfaces = planes
	run.blood.surfaces.sort_custom(
		func(a: Rect2, b: Rect2) -> bool: return a.position.y < b.position.y
	)


func weapon_contact(
	target: Node2D, serial: int, amount: int, at: Vector2, axis: Vector2, _kind: String, run
) -> void:
	if run.run_state != "playing":
		return
	if target.dead:
		if target.receive_corpse_hit(serial, at, axis, "bullet"):
			run.corpse_hits += 1
		return
	var before: int = target.health
	if run.night.active():
		amount = roundi(amount * float(run.night.tuning.damage_multiplier))
	if target.receive_hit(
		serial, "bullet", amount, run.moose.position, {"at": at, "direction": axis}
	):
		run.hits_landed += 1
		if target.health < before:
			run.night.gain(float(run.night.tuning.hit_charge))
			if run.night.active():
				run.night_damage += before - target.health


func sync_hud(run) -> void:
	var gear: Dictionary = run.armory.stats()
	var take: String = run.bindings.caption("interact")
	run.armory.interact_caption = take
	run.weapon_label.text = (
		str(gear.name)
		+ (
			(
				" · %d/%d запас %d · %s перезарядка · %s бросить"
				% [
					gear.loaded,
					gear.capacity,
					gear.reserve,
					run.bindings.caption("reload_weapon"),
					run.bindings.caption("drop_weapon")
				]
			)
			if gear.ranged
			else (
				" · %s атака · %s смена · %s бросить"
				% [
					run.bindings.caption("strike"),
					run.bindings.caption("cycle_weapon"),
					run.bindings.caption("drop_weapon")
				]
			)
		)
	)
	if gear.reload > 0:
		run.weapon_label.text = "ПЕРЕЗАРЯДКА %d%%" % roundi(gear.reload_progress * 100)
	if gear.id == "fists":
		run.weapon_label.text = "Кулаки · %s — подобрать оружие" % take
	run.controls_hint.text = (
		"%s/%s ход · %s бег · %s прыжок · %s присед · %s блок · %s разворот · Esc меню"
		% [
			run.bindings.caption("left"),
			run.bindings.caption("right"),
			run.bindings.caption("sprint"),
			run.bindings.caption("jump"),
			run.bindings.caption("crouch"),
			run.bindings.caption("block"),
			run.bindings.caption("quick_turn")
		]
	)
	run.boss_label.text = ""
	run.boss_bar.size.x = 0
	for enemy: Enemy in run.enemies:
		if enemy.boss and not enemy.dead:
			run.boss_label.text = (
				"%s · ФАЗА %d/%d" % [enemy.tuning.name, enemy.phase, enemy.phase_count]
			)
			run.boss_bar.size.x = 410.0 * enemy.health / enemy.maximum_health


func sync_metrics(run) -> void:
	Metrics.stage = "district_playtest"
	Metrics.rig.merge(
		{
			"revision": 37,
			"room": run.room_index + 1,
			"health": run.health,
			"run_state": run.run_state,
			"enemies_alive": run._remaining(),
			"kills": run.kills,
			"hits_landed": run.hits_landed,
			"player_hits": run.player_hits,
			"deaths": run.deaths,
			"relays": run.cleared.count(true),
			"feet_y": run.moose.position.y,
			"floor_y": run.floor_y,
			"jump_bindings": ["W", "Up", "Space"]
		},
		true
	)
	Metrics.rig["seconds"] = run.elapsed_run
	Metrics.rig["blocking"] = run.moose.blocking
	Metrics.rig["fps_visible"] = (
		run.fps_counter.enabled if is_instance_valid(run.fps_counter) else true
	)
	Metrics.rig["fps"] = Engine.get_frames_per_second()
	Metrics.rig["draw_calls"] = Performance.get_monitor(
		Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
	)
	Metrics.rig["touch_controls"] = (
		run.touch_controls.enabled if is_instance_valid(run.touch_controls) else false
	)
	var active_bodies := 0
	for enemy: Enemy in run.enemies:
		if is_instance_valid(enemy.corpse) and not enemy.corpse.settled:
			active_bodies += enemy.corpse.physical_bodies.size()
	if is_instance_valid(run.player_corpse) and not run.player_corpse.settled:
		active_bodies += run.player_corpse.physical_bodies.size()
	Metrics.rig["ragdoll_active_bodies"] = active_bodies
	Metrics.rig["blocked_hits"] = run.blocked_hits
	Metrics.rig["player_ragdoll"] = run.moose.ragdoll_active
	Metrics.rig["corpses"] = (
		run.enemies.filter(func(enemy: Enemy) -> bool: return enemy.dead).size()
	)
	Metrics.rig["blood_drops"] = run.blood.drops.size() if is_instance_valid(run.blood) else 0
	Metrics.rig["corpse_hits"] = run.corpse_hits
	Metrics.rig["chapter"] = run.route.chapter + 1
	Metrics.rig["wave"] = run.route.wave + 1
	Metrics.rig["waves"] = run.rooms[run.room_index].get("waves", []).size() + 1
	Metrics.rig["weapon"] = run.armory.stats()
	Metrics.rig["key_turn"] = run.bindings.caption("quick_turn")
	Metrics.rig["key_drop"] = run.bindings.caption("drop_weapon")
	Metrics.rig["lift_present"] = is_instance_valid(run.carrier)
	Metrics.rig["lift_upper"] = run.carrier.upper if is_instance_valid(run.carrier) else false
	Metrics.rig["boss_phase"] = 0
	for enemy: Enemy in run.enemies:
		if enemy.boss and not enemy.dead:
			Metrics.rig["boss_phase"] = enemy.phase
	Metrics.rig["rain_impacts"] = run.rain.impacts
	Metrics.rig["blood_stains"] = run.blood.stains.size() if is_instance_valid(run.blood) else 0
	Metrics.rig["blood_landed"] = run.blood.landed if is_instance_valid(run.blood) else 0
	Metrics.rig.merge(
		{
			"world_night": run.world_night,
			"time_switches": run.time_switches,
			"world_night_strength":
			run.night_fx.world_strength if is_instance_valid(run.night_fx) else 0,
			"night_active": run.night.active(),
			"night_remaining": run.night.remaining,
			"night_charge": run.night.charge,
			"night_casts": run.night.casts,
			"night_bursts": run.night.bursts,
			"night_damage": run.night_damage,
			"burst_hits": run.burst_hits,
			"power_scale": run.moose.power_scale,
			"sound_muted": run.audio.muted if is_instance_valid(run.audio) else true,
			"shoe_layers": 2,
			"hand_digits": 4
		},
		true
	)
	Metrics.rig["score_online"] = run.scores.online if is_instance_valid(run.scores) else false
	Metrics.rig["score_session_ready"] = (
		not run.scores.token.is_empty() if is_instance_valid(run.scores) else false
	)
	Metrics.rig["menu"] = (
		run.front.page if is_instance_valid(run.front) and run.front.is_open() else "closed"
	)
	if OS.has_feature("web"):
		var state := Metrics.rig.duplicate()
		state.merge({"ready": true, "stage": Metrics.stage, "completed": Metrics.completed}, true)
		JavaScriptBridge.eval(
			(
				"document.body.setAttribute('data-game-metrics', "
				+ JSON.stringify(JSON.stringify(state))
				+ ");"
			),
			true
		)
