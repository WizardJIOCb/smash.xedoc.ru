extends Node2D

const Moose = preload("res://scripts/actors/moose_rig.gd")
const Armory = preload("res://scripts/systems/armory.gd")
var rigs: Array[Node2D] = []
var guns: Array[Node2D] = []
var clock: float = 0
var stage: int = -1
var label: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("14282c"))
	label = Label.new()
	label.position = Vector2(30, 30)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	for direction: float in [-1.0, 1.0]:
		var rig := Moose.new()
		rig.position = Vector2(380 if direction < 0 else 900, 585)
		rig.scale = Vector2.ONE * 2.4
		rig.power_scale = 2.4
		rig.facing = direction
		add_child(rig)
		var gear := Armory.new()
		add_child(gear)
		gear.configure(rig)
		rigs.append(rig)
		guns.append(gear)


func _physics_process(delta: float) -> void:
	clock += delta
	var next := mini(5, int(clock / 2))
	if next != stage:
		stage = next
		for gear: Node2D in guns:
			gear.grant("pistol" if stage < 3 else "rifle")
			if stage == 5:
				gear.ammunition.rifle.loaded = 0
				gear.reload()
	for index in range(rigs.size()):
		var rig: Node2D = rigs[index]
		rig.crouch_requested = stage == 2
		rig.travel = 0.5 if stage in [1, 4] else 0.0
		rig.horizontal_speed = rig.facing * 60 if stage in [1, 4] else 0.0
		var gear: Node2D = guns[index]
		if stage in [0, 3, 4] and fmod(clock, 0.6) < delta:
			gear.before_attack("punch")
		gear.advance(delta, [], true)
	label.text = ["PISTOL · TWO HANDS", "PISTOL · WALK", "PISTOL · CROUCH", "RIFLE · TWO HANDS", "RIFLE · WALK/FIRE", "RIFLE · RELOAD"][stage]
	Metrics.rig = {"stage": stage, "gear": guns[0].stats()}
