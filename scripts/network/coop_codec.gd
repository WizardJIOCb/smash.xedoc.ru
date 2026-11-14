extends RefCounted
## JSON-safe snapshots. Only the room host produces gameplay state.

const POSE = [
	"facing",
	"horizontal_speed",
	"horizontal_acceleration",
	"vertical_speed",
	"preparation",
	"crouch_requested",
	"crouch",
	"airborne",
	"sprinting",
	"blocking",
	"gait",
	"travel",
	"power_scale",
	"ragdoll_active"
]
const ATTACK = [
	"elapsed", "kind", "side", "in_air", "low", "kick_step", "serial", "chain_length", "weapon"
]
const ENEMY_POSE = ["pace", "facing", "wind", "strike", "hurt", "recoil", "stomp", "shield_down"]
const POWER = ["charge", "remaining", "cooldown", "burst_time", "casts", "bursts"]


static func hero(id: String, label: String, moose, gear, night, health: int) -> Dictionary:
	var result := {
		"id": id,
		"name": label,
		"x": moose.position.x,
		"y": moose.position.y,
		"health": health,
		"pose": {},
		"attack": {},
		"power": {},
		"gear": gear.snapshot()
	}
	for key: String in POSE:
		result.pose[key] = moose.get(key)
	for key: String in ATTACK:
		result.attack[key] = moose.combat.get(key)
	for key: String in POWER:
		result.power[key] = night.get(key)
	return result


static func apply_hero(data: Dictionary, moose, gear, night) -> void:
	moose.position = Vector2(data.x, data.y)
	for key: String in POSE:
		if data.pose.has(key):
			moose.set(key, data.pose[key])
	var state: Dictionary = data.gear
	var changed: bool = gear.equipped != str(state.equipped)
	gear.inventory.assign(state.inventory)
	gear.ammunition = state.ammunition.duplicate(true)
	gear.equipped = str(state.equipped)
	if changed:
		gear._refresh()
	for key: String in ATTACK:
		moose.combat.set(key, data.attack[key])
	for key: String in POWER:
		night.set(key, data.power[key])
	moose.visible = int(data.health) > 0
	if moose.visible:
		moose.skeleton.modulate = Color.WHITE


static func enemy(actor) -> Dictionary:
	var result := {
		"kind": actor.kind,
		"x": actor.position.x,
		"y": actor.position.y,
		"health": actor.health,
		"maximum": actor.maximum_health,
		"dead": actor.dead,
		"state": actor.state,
		"phase": actor.phase,
		"pose": {}
	}
	for key: String in ENEMY_POSE:
		result.pose[key] = actor.rig.get(key)
	return result


static func apply_enemy(data: Dictionary, actor) -> void:
	actor.set_physics_process(false)
	actor.position = Vector2(data.x, data.y)
	if bool(data.dead) and not actor.dead:
		actor.receive_hit(-777, "kick", actor.health + 1, actor.position - Vector2(10, 0))
	actor.health = int(data.health)
	actor.maximum_health = int(data.maximum)
	actor.dead = bool(data.dead)
	actor.state = str(data.state)
	actor.phase = int(data.phase)
	for key: String in ENEMY_POSE:
		actor.rig.set(key, data.pose[key])
	actor.queue_redraw()
