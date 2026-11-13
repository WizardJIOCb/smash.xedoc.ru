extends Node2D
## Isolated art review: both species, both facings, guard/walk/windup/contact.

const Rig = preload("res://scripts/actors/enemy_rig.gd")

var rigs: Array[Rig] = []
var elapsed: float = 0.0
var status: Label


func _ready() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/environment/courtyard-alive-clean.png")
	background.size = Vector2(1280, 720)
	background.modulate = Color(0.65, 0.72, 0.74)
	background.z_index = -30
	add_child(background)
	status = Label.new()
	status.position = Vector2(32, 30)
	status.add_theme_font_size_override("font_size", 25)
	add_child(status)
	for index in range(4):
		var mount := Node2D.new()
		mount.position = Vector2(210 + index * 285, 590)
		mount.scale = Vector2.ONE * 1.7
		add_child(mount)
		var rig := Rig.new()
		rig.kind = "shield" if index < 2 else "whip"
		rig.facing = -1 if index % 2 == 0 else 1
		mount.add_child(rig)
		rigs.append(rig)
		var label := Label.new()
		label.position = Vector2(100 + index * 285, 640)
		label.text = (
			("ДОМОФОНЩИК" if index < 2 else "КАБЕЛЬЩИК") + (" ←" if index % 2 == 0 else " →")
		)
		label.add_theme_font_size_override("font_size", 20)
		add_child(label)


func _process(delta: float) -> void:
	elapsed += delta
	var phase := fmod(elapsed, 6.0)
	status.text = (
		"РУКИ v19 / "
		+ (
			"СТОЙКА"
			if phase < 1.5
			else (
				"ШАГ"
				if phase < 3
				else "ЗАМАХ" if phase < 4 else "УДАР" if phase < 4.7 else "ВОЗВРАТ"
			)
		)
	)
	for rig: Rig in rigs:
		rig.pace = 45 if phase >= 1.5 and phase < 3 else 0
		rig.wind = smoothstep(3, 4, phase) * (1 - smoothstep(4, 4.3, phase))
		rig.strike = sin(clampf((phase - 4) / 0.7, 0, 1) * PI)
		rig.shield_down = phase >= 4.7
