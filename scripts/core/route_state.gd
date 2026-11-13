extends RefCounted
## Chapter boundaries and reinforcement timing are independent of drawing and combat.

var chapters: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapters.json"))
var chapter: int = 0
var wave: int = 0
var wave_wait: float = -1.0
var completed: Array = []


func current() -> Dictionary:
	return chapters[chapter]


func enter() -> void:
	wave = 0
	wave_wait = -1


func waves_done(room: Dictionary) -> bool:
	return wave >= room.get("waves", []).size()


func reinforcement(room: Dictionary, remaining: int, delta: float) -> Array:
	if remaining > 0 or waves_done(room):
		wave_wait = -1
		return []
	if wave_wait < 0:
		wave_wait = 1.8
	wave_wait -= delta
	if wave_wait > 0:
		return []
	var entries: Array = room.waves[wave]
	wave += 1
	wave_wait = -1
	return entries


func load_progress() -> void:
	var saved := ConfigFile.new()
	if saved.load("user://chapters.cfg") == OK:
		completed = saved.get_value("campaign", "completed", [])
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("(() => {try {return localStorage.getItem('smash-chapters-v1');}catch(_){return null;}})()", true)
		if raw is String:
			var parsed = JSON.parse_string(raw)
			if parsed is Array:
				completed = parsed


func finish() -> void:
	if not completed.has(chapter):
		completed.append(chapter)
	var saved := ConfigFile.new()
	saved.set_value("campaign", "completed", completed)
	saved.save("user://chapters.cfg")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try{localStorage.setItem('smash-chapters-v1',%s);}catch(_){}" % JSON.stringify(JSON.stringify(completed)), true)
