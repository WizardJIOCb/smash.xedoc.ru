extends RefCounted
## Physical keys keep the same game controls on Russian and Latin layouts.

const ACTIONS = {
	"left": "Влево",
	"right": "Вправо",
	"jump": "Прыжок",
	"crouch": "Присесть",
	"sprint": "Бег",
	"strike": "Рука / оружие",
	"kick": "Нога",
	"block": "Блок",
	"interact": "Взять / использовать",
	"cycle_weapon": "Сменить оружие",
	"reload_weapon": "Перезарядить",
	"drop_weapon": "Выбросить оружие",
	"quick_turn": "Резкий разворот",
	"world": "День / ночь",
	"ultimate": "Ульта",
	"super_strike": "Импульс",
	"restart": "Повтор",
	"mute": "Звук"
}

var defaults: Dictionary = {}
var overrides: Dictionary = {}
var persist: bool = true
var captions: Dictionary = {}


func setup(load_saved: bool = true) -> void:
	persist = load_saved
	for action: String in ACTIONS:
		defaults[action] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				defaults[action].append(event.physical_keycode)
		_update_caption(action)
	if not load_saved:
		return
	var saved := ConfigFile.new()
	if saved.load("user://controls.cfg") == OK:
		overrides = saved.get_value("controls", "keys", {})
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval(
			"(() => {try{return localStorage.getItem('smash-keys-v1');}catch(_){return null;}})()",
			true
		)
		if raw is String:
			var parsed = JSON.parse_string(raw)
			if parsed is Dictionary:
				overrides = parsed
	for action: String in overrides.keys():
		if ACTIONS.has(action) and int(overrides[action]) > 0:
			_apply(action, [int(overrides[action])])
			_update_caption(action)


func caption(action: String) -> String:
	return str(captions.get(action, ""))


func _update_caption(action: String) -> void:
	var keys: Array[String] = []
	var codes: Array = [int(overrides[action])] if overrides.has(action) else defaults[action]
	for code: int in codes:
		keys.append(OS.get_keycode_string(code))
	captions[action] = " / ".join(keys)


func rebind(action: String, code: int) -> String:
	if code in [KEY_ESCAPE, KEY_B, KEY_Z, KEY_F11] or code <= 0:
		return "Эта клавиша зарезервирована. Выбери другую."
	for other: String in ACTIONS:
		if other == action:
			continue
		for event: InputEvent in InputMap.action_get_events(other):
			if event is InputEventKey and event.physical_keycode == code:
				return "Клавиша занята: " + str(ACTIONS[other])
	_apply(action, [code])
	overrides[action] = code
	_update_caption(action)
	_save()
	return ""


func reset() -> void:
	for action: String in defaults:
		_apply(action, defaults[action])
	overrides.clear()
	for action: String in defaults:
		_update_caption(action)
	_save()


func _apply(action: String, keys: Array) -> void:
	Input.action_release(action)
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	for code: int in keys:
		var event := InputEventKey.new()
		event.physical_keycode = code
		InputMap.action_add_event(action, event)


func _save() -> void:
	if not persist:
		return
	var saved := ConfigFile.new()
	saved.set_value("controls", "keys", overrides)
	saved.save("user://controls.cfg")
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			(
				"try{localStorage.setItem('smash-keys-v1',%s);}catch(_){}"
				% JSON.stringify(JSON.stringify(overrides))
			),
			true
		)
