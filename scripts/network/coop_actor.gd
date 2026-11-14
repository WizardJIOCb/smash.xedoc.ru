extends "res://scripts/gyms/rig_lab.gd"
## Extra party member, simulated only on the room host with the existing motion/combat.

const Armory = preload("res://scripts/systems/armory.gd")
const Night = preload("res://scripts/core/night_power.gd")
const Ragdoll = preload("res://scripts/actors/skeletal_ragdoll.gd")

var peer_id: String = ""
var player_name: String = "Лось"
var health: int = 100
var armory: Armory
var night := Night.new()
var corpse: Ragdoll
var recovery: float = 0
var last_input: int = 0
var tip_serial: int = -1
var previous_tip := Vector2.ZERO
var caption: Label
var compact_tag: bool = false
var world: Node2D
var _notice: String = ""
var _notice_left: float = 0


func _ready() -> void:
	network_input = true
	motion = JSON.parse_string(FileAccess.get_file_as_string("res://data/rig_motion.json"))
	movement_bounds = Vector2(28, 1252)
	moose = Moose.new()
	moose.set_meta("coop_slot", int(peer_id))
	moose.position = Vector2(170, 555)
	add_child(moose)
	moose.combat.serial = int(peer_id) * 1000000
	armory = Armory.new()
	add_child(armory)
	armory.configure(moose)
	armory.draw_pickups = false
	caption = Label.new()
	caption.position = Vector2(-85, -232)
	caption.size = Vector2(170, 28)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font", preload("res://assets/fonts/Manrope-Semibold.tres"))
	caption.add_theme_font_size_override("font_size", 15)
	caption.add_theme_color_override(
		"font_color", Color.from_hsv(fmod(int(peer_id) * 0.17, 1), 0.38, 1)
	)
	moose.add_child(caption)
	set_physics_process(false)
	set_process_unhandled_input(false)
	last_input = Time.get_ticks_msec()


func step(delta: float, room_world) -> void:
	world = room_world
	if health <= 0:
		held_input.clear()
		pressed_input.clear()
		return
	if Time.get_ticks_msec() - last_input > 600:
		held_input.clear()
	var base := float(world.rooms[world.room_index].floor)
	if is_instance_valid(world.carrier):
		moose.position.y += world.carrier.carry_delta(moose.position, moose.airborne)
	for ledge: Rect2 in world.ledges:
		if moose.position.x >= ledge.position.x and moose.position.x <= ledge.end.x:
			if moose.position.y <= ledge.position.y + 1:
				base = minf(base, ledge.position.y)
	if is_instance_valid(world.carrier):
		var deck: Rect2 = world.carrier.surface()
		if moose.position.x >= deck.position.x and moose.position.x <= deck.end.x:
			if moose.position.y <= deck.position.y + 1:
				base = minf(base, deck.position.y)
	floor_y = world.campaign_rules.floor_at(self, base)
	lift = minf(0, moose.position.y - floor_y)
	move_power = float(night.tuning.move_multiplier) if night.active() else 1
	combat_rate = float(night.tuning.attack_rate) if night.active() else 1
	if _input_pressed("quick_turn"):
		quick_turn()
	if _input_pressed("cycle_weapon"):
		armory.cycle()
	if _input_pressed("reload_weapon"):
		armory.reload()
	if _input_pressed("drop_weapon"):
		armory.drop(floor_y)
	if _input_pressed("ultimate"):
		night.activate()
	if _input_pressed("super_strike"):
		night.try_burst()
	if not _input_held("block") and night.burst_time < 0:
		if _input_pressed("strike") and armory.before_attack("punch"):
			moose.combat.request("punch", moose.airborne, _input_held("crouch"))
		if _input_pressed("kick"):
			moose.combat.request("kick", moose.airborne, _input_held("crouch"))
	var before := moose.position
	var old_x := before.x
	super._physics_process(delta)
	world.campaign_rules.after_move(self, before, delta)
	for enemy: Node2D in world.enemies:
		if (
			not enemy.dead
			and enemy.kind != "drone"
			and absf(moose.position.y - enemy.position.y) < 45
		):
			moose.position.x = world.Contact.separate(old_x, moose.position.x, enemy.position.x)
	if not world.cleared[world.room_index]:
		moose.position.x = minf(moose.position.x, 1190)
	armory.ground_y = floor_y
	armory.trigger(_input_held("strike") and not _input_held("block") and night.burst_time < 0)
	moose.power_pose = night.pose()
	moose.power_scale = float(night.tuning.size_multiplier) if night.active() else 1


func reset_at(at: Vector2, heal: bool = true) -> void:
	if is_instance_valid(corpse):
		corpse.set_process(false)
		corpse.set_physics_process(false)
		moose.remove_child(corpse)
		corpse.queue_free()
		corpse = null
	if heal:
		health = 100
	recovery = 0
	moose.ragdoll_active = false
	moose.visible = true
	moose.skeleton.modulate = Color.WHITE
	for bone: Bone2D in moose.bones.values():
		bone.transform = bone.rest
	moose.position = at
	moose.horizontal_speed = 0
	moose.combat.interrupt()
	moose.blocking = false
	moose.airborne = false
	floor_y = at.y
	lift = 0
	speed = 0
	vertical_speed = 0
	tip_serial = -1
	pressed_input.clear()
	held_input.clear()


func hurt(amount: int, source: Vector2, world) -> void:
	if health <= 0:
		return
	if night.active():
		amount = maxi(1, roundi(amount * float(night.tuning.incoming_multiplier)))
	if moose.blocking:
		amount = maxi(1, ceili(amount * float(guard_tuning.damage_multiplier)))
	health = maxi(0, health - amount)
	moose.combat.interrupt()
	world._feedback(moose.position + Vector2(0, -150), "−%d" % amount, Color("e45848"), "hurt")
	world.blood.spill(
		moose.position + Vector2(0, -100),
		Vector2(signf(moose.position.x - source.x), -0.3),
		health <= 0
	)
	if health <= 0:
		recovery = 6
		night.cancel()
		moose.ragdoll_active = true
		corpse = Ragdoll.new()
		moose.add_child(corpse)
		corpse.start(
			moose,
			moose.position + Vector2(0, -100),
			Vector2(180, -60),
			Vector2(speed, vertical_speed)
		)


func _process(_delta: float) -> void:
	caption.scale.x = moose.facing
	caption.position.x = -85 * moose.facing
	caption.position.y = -232 - (int(peer_id) % 3) * 23
	caption.text = (
		"%02d · %d HP" % [int(peer_id), health]
		if compact_tag
		else "%s · %d HP" % [player_name, health]
	)
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(moose):
		return
	draw_set_transform(Vector2(moose.position.x, floor_y + 14), 0, Vector2(1, 0.17))
	draw_circle(Vector2.ZERO, 33, Color(0.02, 0.05, 0.06, 0.25))
	draw_set_transform(Vector2.ZERO)


func _sync_metrics() -> void:
	pass


func _world_pressed() -> void:
	pass


func _hurt_player(amount: int, source: Vector2, _high: bool = false) -> void:
	hurt(amount, source, world)


func _feedback(at: Vector2, text: String, color: Color, sound: String) -> void:
	world._feedback(at, text, color, sound)
