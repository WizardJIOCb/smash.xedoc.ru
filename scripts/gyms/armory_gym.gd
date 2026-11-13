extends "res://scripts/gyms/rig_lab.gd"
## Playable weapon range. Capture input can collect the rack and cycle every item.

const Armory = preload("res://scripts/systems/armory.gd")
const Enemy = preload("res://scripts/actors/district_enemy.gd")

var armory: Node2D
var target: Node2D
var weapon_label: Label
var contacts: int = 0
var _last_melee: int = -1


func _ready() -> void:
	super._ready()
	moose.position.x = 420
	armory = Armory.new()
	add_child(armory)
	armory.configure(moose)
	armory.projectile_hit.connect(_bullet_hit)
	armory.spawn_pickups(
		[
			{"id": "knuckles", "x": 425, "y": 555},
			{"id": "bat", "x": 430, "y": 555},
			{"id": "shovel", "x": 435, "y": 555},
			{"id": "hockey", "x": 440, "y": 555},
			{"id": "pistol", "x": 445, "y": 555},
			{"id": "rifle", "x": 450, "y": 555}
		]
	)
	for pair in [["pickup", KEY_E], ["weapon_cycle", KEY_TAB], ["reload_weapon", KEY_F]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		var key := InputEventKey.new()
		key.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], key)
	target = Enemy.new()
	target.kind = "shield"
	target.tuning = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json")).shield
	)
	target.position = Vector2(780, 555)
	add_child(target)
	target.set_physics_process(false)
	target.health = 100000
	target.rig.facing = -1
	var layer := CanvasLayer.new()
	add_child(layer)
	weapon_label = Label.new()
	weapon_label.position = Vector2(30, 105)
	weapon_label.add_theme_font_size_override("font_size", 21)
	layer.add_child(weapon_label)
	var help := Label.new()
	help.text = "ОРУЖЕЙНАЯ · E подобрать · Tab сменить · F перезарядить · J оружие · K нога"
	help.position = Vector2(30, 632)
	help.add_theme_font_size_override("font_size", 20)
	layer.add_child(help)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pickup"):
		armory.interact()
	elif event.is_action_pressed("weapon_cycle"):
		armory.cycle()
	elif event.is_action_pressed("reload_weapon"):
		armory.reload()
	elif event.is_action_pressed("strike"):
		if armory.before_attack("punch"):
			super._unhandled_input(event)
	else:
		super._unhandled_input(event)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	armory.trigger(Input.is_action_pressed("strike"))
	armory.advance(delta, [target], true)
	var attack = moose.combat
	if attack.is_active() and _last_melee != attack.serial:
		var hand: Bone2D = moose.bones[
			attack.side + ("_foot" if attack.kind == "kick" else "_hand")
		]
		var at := hand.to_global(Vector2(0, 15))
		var area: Rect2 = armory.melee_area(Rect2(at, Vector2.ZERO).grow(24), attack.kind, at)
		if area.intersects(target.hurtbox()):
			_last_melee = attack.serial
			target.receive_hit(
				attack.serial, attack.kind, armory.melee_damage(20, attack.kind), moose.position
			)
			contacts += 1
	var state: Dictionary = armory.stats()
	weapon_label.text = str(state.name)
	if state.ranged:
		weapon_label.text += "  %d / %d   запас %d" % [state.loaded, state.capacity, state.reserve]
	if state.reload > 0:
		weapon_label.text += "   ПЕРЕЗАРЯДКА %d%%" % roundi(state.reload_progress * 100)
	weapon_label.text += "   попаданий: %d" % contacts
	Metrics.rig = {"armory": state, "contacts": contacts}


func _bullet_hit(
	victim: Node2D, serial: int, amount: int, at: Vector2, axis: Vector2, kind: String
) -> void:
	if victim.receive_hit(serial, kind, amount, moose.position, {"at": at, "direction": axis}):
		contacts += 1
