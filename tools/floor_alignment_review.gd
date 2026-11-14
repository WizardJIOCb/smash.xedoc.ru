extends "res://scripts/world/district_run.gd"
## Native render review of every new room, with its production rigs and floor planes.

const GroundContact = preload("res://scripts/world/ground_contact.gd")

var _review_clock: float = 0
var _review_room: int = 11
var _review_rows: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	front.hide_menu()
	audio.set_muted(true)
	_review_next()


func _physics_process(delta: float) -> void:
	_review_clock += delta
	if _review_clock >= 1.0:
		_review_clock -= 1.0
		_review_room += 1
		_review_next()
	super._physics_process(delta)


func _process(delta: float) -> void:
	super._process(delta)
	outcome.text = ""


func _review_next() -> void:
	if _review_room >= 27:
		Metrics.completed = true
		print("FLOOR_ALIGNMENT " + JSON.stringify(_review_rows))
		set_physics_process(false)
		return
	_load_room(_review_room, 220)
	route.chapter = int(rooms[_review_room].chapter) - 1
	if not scenery.has_node("GroundContact"):
		scenery.add_child(GroundContact.new(self))
	run_state = "paused"
	quarantine = false
	blend = 0
	for enemy: Enemy in enemies:
		enemy.paused = true
	_notice = "ОПОРА %.0f · ПОДОШВА %.0f" % [floor_y, floor_y + 10]
	_notice_left = 99
	_review_rows.append(
		{
			"room": _review_room + 1,
			"art": rooms[_review_room].art,
			"root": floor_y,
			"sole": floor_y + 10,
			"blood": _surface_at(blood.surfaces, moose.position.x),
			"rain": _surface_at(rain.surfaces, moose.position.x),
			"enemy_roots": enemies.map(func(enemy: Enemy): return enemy.position.y),
			"lift_bottom": carrier.surface().position.y if is_instance_valid(carrier) else 0
		}
	)


func _surface_at(planes: Array[Rect2], x: float) -> float:
	var support := INF
	for plane: Rect2 in planes:
		if x >= plane.position.x and x <= plane.end.x:
			support = minf(support, plane.position.y)
	return support
