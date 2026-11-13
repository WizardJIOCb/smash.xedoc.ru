extends CanvasLayer
## A quiet readout with an explicit, persistent display preference.

var enabled: bool = true
var label: Label
var _elapsed: float = 0.0


func _ready() -> void:
	layer = 25
	var preferences := ConfigFile.new()
	if preferences.load("user://display.cfg") == OK:
		enabled = bool(preferences.get_value("display", "fps", true))
	if OS.has_feature("web"):
		var saved = JavaScriptBridge.eval(
			(
				"(() => { try { return localStorage.getItem('smash-show-fps'); }"
				+ " catch (_) { return null; } })()"
			),
			true
		)
		if saved is String and saved in ["true", "false"]:
			enabled = saved == "true"
	label = Label.new()
	label.position = Vector2(1182, 8)
	label.size = Vector2(80, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_override("font", preload("res://assets/fonts/Manrope-Semibold.tres"))
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.81, 0.65))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = enabled
	add_child(label)
	_refresh()


func set_enabled(value: bool) -> void:
	enabled = value
	label.visible = enabled
	var preferences := ConfigFile.new()
	preferences.set_value("display", "fps", enabled)
	preferences.save("user://display.cfg")
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			(
				"try { localStorage.setItem('smash-show-fps', %s); } catch (_) {}"
				% JSON.stringify(str(enabled).to_lower())
			),
			true
		)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.25:
		_elapsed = 0
		_refresh()


func _refresh() -> void:
	label.text = "%d FPS" % Engine.get_frames_per_second()
