extends "res://scripts/world/district_run.gd"
## Native physics fixture, not a route completion driver. Real rigs, death and corpse hits.

const CampaignTerrain = preload("res://scripts/world/campaign_terrain.gd")

var review_kind: String = "port"
var review_seconds: float = 0
var review_max_y: float = 0
var first_sink_y: float = 0
var paused_drift: float = 0
var review_victim: Enemy
var review_corpse: Ragdoll
var first_corpse: Ragdoll
var _first_hit_at: float = -1
var _second_hit: bool = false
var _bridge_started: bool = false
var _second_spawn_at: float = -1
var _paused_at := Vector2.INF


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--terrain-kind="):
			review_kind = argument.get_slice("=", 1)
	super._ready()
	front.hide_menu()
	run_state = "playing"
	route.chapter = 3 if review_kind == "port" else 6
	_load_room(12 if review_kind == "port" else 25, 170)
	rooms[room_index].waves = []
	for enemy: Enemy in enemies:
		remove_child(enemy)
		enemy.queue_free()
	enemies.clear()
	_fixture_enemy()
	if review_kind == "port":
		campaign_rules.deck_x = 650
		campaign_rules.deck_right = false
		campaign_rules.dock_wait = 3
	_notice = "Проверка физики: тело на грузе → пауза → удар с края → настоящая вода."
	_notice_left = 30


func _build_physics_surfaces(base_floor: float) -> void:
	if not CampaignTerrain.applies(campaign_rules):
		super._build_physics_surfaces(base_floor)
		return
	if is_instance_valid(terrain):
		remove_child(terrain)
		terrain.queue_free()
	terrain = CampaignTerrain.new()
	terrain.configure(self, campaign_rules, base_floor)
	add_child(terrain)


func _fixture_enemy() -> void:
	_spawn_enemy(["otter" if review_kind == "port" else "crow", 1040, 555])
	review_victim = enemies.back()
	review_victim.paused = true
	review_victim.facing = 1
	review_victim.rig.facing = 1


func _kill_at(x: float, serial: int) -> void:
	review_victim.position.x = x
	review_victim.paused = false
	var at: Vector2 = review_victim.rig.bones.hips.global_position
	review_victim.receive_hit(
		serial, "kick", 10000, Vector2(x - 1, 555), {"at": at, "direction": Vector2.ZERO}
	)
	review_corpse = review_victim.corpse


func _physics_process(delta: float) -> void:
	review_seconds += delta
	var fixture_pause := review_kind == "port" and review_seconds >= 2 and review_seconds < 2.5
	run_state = "paused" if fixture_pause else "playing"
	for enemy: Enemy in enemies:
		enemy.paused = fixture_pause or not enemy.dead
	if not is_instance_valid(review_corpse) and review_seconds >= 0.25:
		_kill_at(650 if review_kind == "port" else 780, -91000)
	if review_kind == "port":
		_drive_port(fixture_pause)
	else:
		_drive_roof()
	super._physics_process(delta)
	if terrain is CampaignTerrain:
		terrain.advance(fixture_pause)
	if is_instance_valid(review_corpse):
		review_max_y = maxf(review_max_y, float(review_corpse.bodies.body.position.y))
	if is_instance_valid(first_corpse):
		first_sink_y = maxf(first_sink_y, float(first_corpse.bodies.body.position.y))
	_sync_metrics()


func _drive_port(paused: bool) -> void:
	if not is_instance_valid(review_corpse):
		return
	var core: RigidBody2D = review_corpse.bodies.body
	if paused:
		if _paused_at == Vector2.INF:
			_paused_at = core.position
		paused_drift = maxf(paused_drift, core.position.distance_to(_paused_at))
	if terrain is CampaignTerrain and terrain.carried_distance >= 70 and _first_hit_at < 0:
		review_victim.receive_corpse_hit(-92000, core.position, Vector2.RIGHT, "kick")
		_first_hit_at = review_seconds
	if _first_hit_at > 0 and review_seconds - _first_hit_at >= 0.2 and not _second_hit:
		review_victim.receive_corpse_hit(-92001, core.position, Vector2.RIGHT, "kick")
		_second_hit = true
	if review_max_y > 760 and _second_hit and terrain.carried_distance >= 70:
		Metrics.completed = true


func _drive_roof() -> void:
	if review_seconds >= 2.3 and not _bridge_started:
		for item: Dictionary in campaign_rules.objects:
			if item.type == "support":
				campaign_rules.attack(self, -93000, item.rect, 100)
		_bridge_started = true
	if campaign_rules.bridge_down and _second_spawn_at < 0:
		first_corpse = review_corpse
		_fixture_enemy()
		_second_spawn_at = review_seconds
	if _second_spawn_at > 0 and review_seconds - _second_spawn_at > 0.25 and not review_victim.dead:
		_kill_at(780, -93001)
	if (
		is_instance_valid(first_corpse)
		and is_instance_valid(review_corpse)
		and review_corpse != first_corpse
	):
		if (
			first_sink_y > 720
			and review_corpse.settled
			and review_corpse.bodies.body.position.y < 565
		):
			Metrics.completed = true


func _sync_metrics() -> void:
	super._sync_metrics()
	if terrain is CampaignTerrain:
		Metrics.rig.merge(terrain.metrics(), true)
		Metrics.rig["terrain_fixture"] = review_kind
		Metrics.rig["terrain_review_seconds"] = review_seconds
		Metrics.rig["corpse_max_y"] = review_max_y
		Metrics.rig["first_sink_y"] = first_sink_y
		Metrics.rig["paused_drift"] = paused_drift
		if is_instance_valid(review_corpse):
			Metrics.rig["corpse_y"] = review_corpse.bodies.body.position.y
			Metrics.rig["corpse_settled"] = review_corpse.settled
			Metrics.rig["corpse_reactions"] = review_corpse.hits
			Metrics.rig["corpse_joint_error"] = review_corpse.joint_error()
