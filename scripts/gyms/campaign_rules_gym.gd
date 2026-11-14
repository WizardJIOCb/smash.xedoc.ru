extends "res://scripts/gyms/rig_lab.gd"
## Standalone playtest; chapter tabs and live tuning use the mouse, actions stay J/K/E.

const CampaignRules = preload("res://scripts/world/campaign_rules.gd")
const Enemy = preload("res://scripts/actors/district_enemy.gd")
const Effects = preload("res://scripts/world/district_fx.gd")
const Sound = preload("res://scripts/core/combat_audio.gd")
const Contact = preload("res://scripts/core/combat_contact.gd")

var health: int = 100
var enemies: Array[Enemy] = []
var effects: Effects
var audio: Sound
var _notice: String = ""
var _notice_left: float = 0.0
var _rules: CampaignRules
var _data: Dictionary
var _encounters: Dictionary
var _scenario: int = 0
var _heading: Label
var _goal: Label
var _readout: Label
var _tuning_box: VBoxContainer
var _environment: TextureRect
var _tabs: Array[Button] = []
var _projectile_left: float = 0.0
var _tip_serial: int = -1
var _previous_tip := Vector2.ZERO
var _arrived: bool = false


func _ready() -> void:
	_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign_rules.json"))
	_encounters = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	super._ready()
	movement_bounds = Vector2(45, 1230)
	rain.hide()
	rain.paused = true
	for child: Node in get_children():
		if child is CanvasLayer:
			for control: Node in child.get_children():
				control.hide()
	_environment = _background("res://assets/environment/depot-yard.webp")
	effects = Effects.new()
	effects.z_index = 30
	add_child(effects)
	audio = Sound.new()
	add_child(audio)
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_E
		InputMap.action_add_event("interact", key)
	_build_panel()
	var initial := 0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--gym-kind="):
			for index in range(_data.gym.scenarios.size()):
				if _data.gym.scenarios[index].kind == argument.get_slice("=", 1):
					initial = index
	_select(initial)


func _build_panel() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := Panel.new()
	panel.position = Vector2(17, 17)
	panel.size = Vector2(1246, 130)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10232a", 0.94)
	style.border_color = Color("637c70")
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	_heading = _label(layer, Vector2(32, 26), 28)
	_goal = _label(layer, Vector2(32, 67), 18)
	for index in range(_data.gym.scenarios.size()):
		var button := Button.new()
		button.text = str(_data.gym.scenarios[index].title)
		button.position = Vector2(32 + index * 246, 104)
		button.size = Vector2(236, 33)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_select.bind(index))
		layer.add_child(button)
		_tabs.append(button)
	var restart := Button.new()
	restart.text = "ПОВТОРИТЬ"
	restart.position = Vector2(1028, 104)
	restart.size = Vector2(218, 33)
	restart.focus_mode = Control.FOCUS_NONE
	restart.pressed.connect(func() -> void: _select(_scenario))
	layer.add_child(restart)
	var footer := Panel.new()
	footer.position = Vector2(17, 600)
	footer.size = Vector2(1246, 108)
	footer.add_theme_stylebox_override("panel", style)
	layer.add_child(footer)
	_readout = _label(layer, Vector2(32, 608), 18)
	var controls := _label(layer, Vector2(32, 669), 17)
	controls.text = (
		"A/D · ход    Shift · бег    S/↓ · присед    W/↑/Пробел · прыжок"
		+ "    J/K · удары    E · груз"
	)
	_tuning_box = VBoxContainer.new()
	_tuning_box.position = Vector2(951, 166)
	_tuning_box.size.x = 292
	layer.add_child(_tuning_box)


func _label(parent: Node, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("e8d9bb"))
	label.add_theme_color_override("font_shadow_color", Color("0d2028"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label


func _select(index: int) -> void:
	_scenario = index
	if is_instance_valid(_rules):
		remove_child(_rules)
		_rules.queue_free()
	for enemy: Enemy in enemies:
		remove_child(enemy)
		enemy.queue_free()
	enemies.clear()
	var spec: Dictionary = _data.gym.scenarios[index]
	_rules = CampaignRules.new()
	_rules.configure({"floor": 555, "mechanic": {"kind": spec.kind, "gap_enabled": true}})
	add_child(_rules)
	_environment.texture = load("res://assets/environment/" + str(spec.art))
	moose.position = Vector2(_data.gym.start_x, 555)
	moose.facing = 1
	moose.airborne = false
	moose.combat.interrupt()
	moose.land(0)
	speed = 0
	lift = 0
	vertical_speed = 0
	floor_y = 555
	_stride_stop.active = false
	_direction_was_held = false
	_jump_buffer = 0
	_preparation_time = -1
	health = int(_data.gym.player_health)
	_arrived = false
	_tip_serial = -1
	_projectile_left = float(_data.gym.projectile_interval)
	effects.projectiles.clear()
	effects.seal = 0
	effects.floor_y = 555
	_notice = str(spec.goal)
	_notice_left = 5
	_heading.text = str(spec.title) + "  /  ПОЛИГОН"
	_goal.text = str(spec.goal)
	for tab in range(_tabs.size()):
		_tabs[tab].modulate = Color("e4bf76") if tab == index else Color.WHITE
	for child: Node in _tuning_box.get_children():
		_tuning_box.remove_child(child)
		child.queue_free()
	for slider_spec: Array in _data.gym.sliders[spec.kind]:
		_add_slider(slider_spec)
	if spec.kind == "metro":
		var enemy := Enemy.new()
		enemy.kind = "hare"
		enemy.position = Vector2(730, 555)
		enemy.target = moose
		enemy.tuning = _encounters.hare.duplicate(true)
		enemy.tuning.speed = 0
		enemy.tuning.reach = 0
		enemy.feedback.connect(_feedback)
		add_child(enemy)
		enemies.append(enemy)
	Metrics.completed = false
	_sync_metrics()


func _add_slider(spec: Array) -> void:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 15)
	var slider := HSlider.new()
	slider.min_value = float(spec[2])
	slider.max_value = float(spec[3])
	slider.step = float(spec[4])
	slider.value = float(_rules.tuning[spec[0]])
	slider.focus_mode = Control.FOCUS_NONE
	label.text = "%s: %s" % [spec[1], slider.value]
	slider.value_changed.connect(
		func(value: float) -> void:
			_rules.tuning[spec[0]] = value
			label.text = "%s: %s" % [spec[1], value]
	)
	_tuning_box.add_child(label)
	_tuning_box.add_child(slider)


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if is_instance_valid(_rules) and event.is_action_pressed("interact"):
		_rules.interact(self)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_rules):
		return
	_rules.advance(self, delta, false)
	floor_y = _rules.floor_at(self, 555)
	lift = minf(0, moose.position.y - floor_y)
	var previous := moose.position
	super._physics_process(delta)
	_rules.after_move(self, previous, delta)
	_resolve_gym_attacks()
	_advance_projectiles(delta)
	if moose.position.x >= float(_data.gym.goal_x) and not _arrived:
		_arrived = true
		Metrics.completed = true
		_feedback(moose.position + Vector2(0, -170), "МАРШРУТ ПРОЙДЕН", Color("d4c17d"), "relay")
	_sync_metrics()


func _resolve_gym_attacks() -> void:
	var attack = moose.combat
	if not attack.is_active():
		_tip_serial = -1
		return
	var bone: Bone2D = moose.bones[attack.side + ("_foot" if attack.kind == "kick" else "_hand")]
	var tip := bone.to_global(Vector2(0, 15))
	if _tip_serial != attack.serial:
		_tip_serial = attack.serial
		_previous_tip = tip
	var area := Rect2(_previous_tip, Vector2.ZERO).expand(tip).grow(float(_data.gym.attack_radius))
	var damage := Contact.damage(attack.kind, attack.kick_step, attack.in_air, _encounters)
	_rules.attack(self, attack.serial, area, damage)
	for enemy: Enemy in enemies:
		if not enemy.dead and area.intersects(enemy.hurtbox()):
			enemy.receive_hit(attack.serial, attack.kind, damage, moose.position)
	_previous_tip = tip


func _advance_projectiles(delta: float) -> void:
	if _rules.kind == "roofs":
		_projectile_left -= delta
		if _projectile_left <= 0:
			_projectile_left += float(_data.gym.projectile_interval)
			effects.projectiles.append(
				{
					"at": Vector2(1110, 555 - float(_data.gym.projectile_y_offset)),
					"velocity": Vector2(-float(_data.gym.projectile_speed), 0),
					"damage": int(_data.gym.projectile_damage),
					"age": 0.0
				}
			)
	var body := Rect2(
		moose.position - Vector2(19, 77 if moose.crouch > 0.5 else 149),
		Vector2(38, 74 if moose.crouch > 0.5 else 146)
	)
	for item: Dictionary in effects.projectiles:
		var before: Vector2 = item.at
		item.age += delta
		item.at += item.velocity * delta
		if Rect2(before, Vector2.ZERO).expand(item.at).grow(5).intersects(body):
			_hurt_player(int(item.damage), before)
			item.age = 10
	effects.projectiles = effects.projectiles.filter(
		func(item: Dictionary) -> bool: return item.age < 4
	)


func _hurt_player(amount: int, _source: Vector2, _high: bool = false) -> void:
	health = maxi(1, health - amount)
	_feedback(moose.position + Vector2(0, -160), "−%d" % amount, Color("e99670"), "hurt")


func _feedback(at: Vector2, caption: String, color: Color, sound: String) -> void:
	effects.burst(at, caption, color)
	audio.play(sound)


func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(_rules):
		return
	_notice_left = maxf(0, _notice_left - delta)
	var m := _rules.metrics()
	_readout.text = "ЛОСЬ %d HP  ·  " % health
	match _rules.kind:
		"port":
			_readout.text += (
				"ГРУЗ %.0f px  ·  ПЕРЕПРАВА %.0f px  ·  ВОЗВРАТЫ %d"
				% [_rules.deck_x, m.carried_distance, m.falls]
			)
		"metro":
			_readout.text += (
				"ВОЛНЫ %d  ·  УДАРЫ ПО ЛОСЮ %d / ПО ОХРАНЕ %d"
				% [m.waves, m.player_wave_hits, m.enemy_wave_hits]
			)
		_:
			_readout.text += (
				"СЛОМАНО %d  ·  УКРЫТИЕ ОСТАНОВИЛО %d  ·  МОСТ %s"
				% [m.broken, m.cover_blocks, "ГОТОВ" if m.bridge_down else "—"]
			)
	_readout.text += (
		"\n"
		+ (
			"МАРШРУТ ПРОЙДЕН · выбери следующую главу сверху"
			if _arrived
			else _notice if _notice_left > 0 else str(_data.gym.scenarios[_scenario].goal)
		)
	)


func _draw() -> void:
	super._draw()
	if not is_instance_valid(_rules):
		return
	var x := float(_data.gym.goal_x)
	draw_circle(Vector2(x, 545), 21, Color("8dbb8c", 0.18))
	draw_rect(Rect2(x - 12, 490, 24, 38), Color("e7d6ad"))
	for row in range(4):
		draw_line(Vector2(x - 6, 499 + row * 6), Vector2(x + 7, 499 + row * 6), Color("526357"), 2)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(x - 57, 474),
		"НАКЛАДНЫЕ",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("ead7ae")
	)


func _sync_metrics() -> void:
	super._sync_metrics()
	if is_instance_valid(_rules):
		Metrics.stage = "campaign_rules_gym"
		Metrics.rig.merge(_rules.metrics(), true)
		Metrics.rig["health"] = health
		Metrics.rig["feet_y"] = moose.position.y
		Metrics.rig["floor_y"] = floor_y
		Metrics.rig["arrived"] = _arrived
