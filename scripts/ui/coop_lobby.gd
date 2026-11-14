extends CanvasLayer

signal create_requested(player_name: String, capacity: int)
signal join_requested(player_name: String, code: String)
signal start_requested(chapter: int)
signal leave_requested
signal back_requested

const FONT = preload("res://assets/fonts/Manrope-Semibold.tres")
const INK := Color("132630")
const PAPER := Color("e7d3ac")
const GOLD := Color("e2b36e")
const MUTED := Color("b3c4b6")

var chapters: Array = []
var root: Control
var name_input: LineEdit
var code_input: LineEdit
var capacity_input: SpinBox
var chapter_input: OptionButton
var forms: Control
var room: Control
var status: Label
var roster: Array[Label] = []
var room_code: Label
var room_title: Label
var waiting: Label
var create_button: Button
var join_button: Button
var start_button: Button
var copy_button: Button
var leave_button: Button
var back_button: Button
var _info: Dictionary = {}
var _you: String = ""
var _busy: bool = false
var _in_room: bool = false


func _ready() -> void:
	layer = 24
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.theme = Theme.new()
	root.theme.default_font = FONT
	root.theme.default_font_size = 20
	add_child(root)
	var background := TextureRect.new()
	background.texture = load("res://assets/environment/menu-ground-v1.webp")
	background.size = root.size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.065, 0.075, 0.94)
	shade.size = root.size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	_label(root, Vector2(64, 24), "ЛОСЬ В ПРОДЕ  /  СОВМЕСТНОЕ ПРОХОЖДЕНИЕ", 18, GOLD)
	_label(root, Vector2(64, 64), "Во двор всей бандой", 48)
	_build_forms()
	_build_room()
	status = _label(root, Vector2(340, 652), "", 18, MUTED)
	status.size = Vector2(876, 56)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	back_button = _button(root, Vector2(64, 648), Vector2(248, 48), "← Главное меню", _back)
	hide_lobby()


func _build_forms() -> void:
	forms = Control.new()
	root.add_child(forms)
	_label(
		forms, Vector2(68, 144), "Собери от 2 до 16 игроков и проходите главы вместе.", 20, MUTED
	)
	_label(forms, Vector2(64, 196), "Как тебя зовёт двор?", 18)
	name_input = _field(forms, Vector2(64, 228), Vector2(548, 48), "Твоё имя", 20)
	_panel(forms, Vector2(64, 300), Vector2(548, 288))
	_panel(forms, Vector2(644, 300), Vector2(572, 288))
	_label(forms, Vector2(88, 320), "Создать игру", 30)
	_label(forms, Vector2(88, 376), "Сколько мест в банде?", 18, MUTED)
	capacity_input = SpinBox.new()
	capacity_input.position = Vector2(88, 412)
	capacity_input.size = Vector2(200, 48)
	capacity_input.min_value = 2
	capacity_input.max_value = 16
	capacity_input.step = 1
	capacity_input.value = 4
	capacity_input.add_theme_font_size_override("font_size", 24)
	_skin_input(capacity_input.get_line_edit())
	forms.add_child(capacity_input)
	_label(forms, Vector2(312, 424), "Включая тебя", 18, MUTED)
	create_button = _button(
		forms, Vector2(88, 508), Vector2(500, 56), "Создать комнату", _create, true
	)
	_label(forms, Vector2(668, 320), "Вступить в игру", 30)
	_label(forms, Vector2(668, 376), "Код комнаты от друга", 18, MUTED)
	code_input = _field(forms, Vector2(668, 412), Vector2(524, 48), "Например, ABCDEF", 12)
	code_input.text_submitted.connect(func(_text: String) -> void: _join())
	join_button = _button(forms, Vector2(668, 508), Vector2(524, 56), "Вступить по коду", _join)


func _build_room() -> void:
	room = Control.new()
	root.add_child(room)
	room_title = _label(room, Vector2(68, 144), "", 24, GOLD)
	room_code = _label(room, Vector2(776, 80), "", 36, GOLD)
	room_code.size = Vector2(440, 52)
	room_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	copy_button = _button(
		room, Vector2(872, 144), Vector2(344, 48), "Скопировать приглашение", _copy_invite
	)
	waiting = _label(room, Vector2(64, 208), "", 18, MUTED)
	waiting.size = Vector2(1152, 32)
	for index in range(16):
		var column := index / 8
		var row := index % 8
		var at := Vector2(64 + column * 580, 256 + row * 34)
		_panel(room, at, Vector2(572 if column == 1 else 548, 32))
		var entry := _label(room, at + Vector2(12, 2), "", 18)
		entry.size = Vector2(548 if column == 1 else 524, 28)
		entry.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		roster.append(entry)
	_label(room, Vector2(64, 544), "С какой главы начнём?", 18, MUTED)
	chapter_input = OptionButton.new()
	chapter_input.position = Vector2(64, 584)
	chapter_input.size = Vector2(780, 48)
	chapter_input.add_theme_font_size_override("font_size", 20)
	chapter_input.add_theme_stylebox_override("normal", _style(Color("263b40")))
	chapter_input.add_theme_stylebox_override("hover", _style(Color("314b4e")))
	chapter_input.add_theme_stylebox_override("focus", _focus_style())
	chapter_input.add_theme_color_override("font_color", PAPER)
	for index in range(chapters.size()):
		chapter_input.add_item(
			"%02d / %s" % [index + 1, str(chapters[index].get("title", "Глава"))]
		)
	if chapters.is_empty():
		chapter_input.add_item("01 / Район закрыт")
	room.add_child(chapter_input)
	start_button = _button(room, Vector2(872, 584), Vector2(344, 48), "Начать вместе", _start, true)
	leave_button = _button(room, Vector2(64, 648), Vector2(248, 48), "Покинуть комнату", _leave)


func open() -> void:
	_in_room = false
	_info.clear()
	_busy = false
	forms.show()
	room.hide()
	back_button.show()
	root.show()
	status.text = ""
	_update_controls()
	name_input.grab_focus()


func hide_lobby() -> void:
	if is_instance_valid(root):
		root.hide()
		get_viewport().gui_release_focus()


func invite(code: String) -> void:
	open()
	code_input.text = code.strip_edges().to_upper()
	if name_input.text.strip_edges().is_empty():
		name_input.grab_focus()
	else:
		join_button.grab_focus()


func show_room(info: Dictionary, you: String) -> void:
	var previous_code := str(_info.get("code", ""))
	_info = info.duplicate(true)
	_you = you
	_in_room = true
	_busy = false
	forms.hide()
	room.show()
	back_button.hide()
	root.show()
	status.text = ""
	status.add_theme_color_override("font_color", MUTED)
	var players: Array = _info.get("players", [])
	var capacity := clampi(int(_info.get("capacity", 2)), 2, 16)
	var code := str(_info.get("code", ""))
	var host := str(_info.get("host", ""))
	room_code.text = code
	room_title.text = "Комната · %d / %d игроков" % [players.size(), capacity]
	for index in range(16):
		var entry := roster[index]
		entry.modulate.a = 1.0 if index < capacity else 0.35
		if index >= players.size():
			entry.text = (
				"%02d    %s"
				% [index + 1, "Свободное место" if index < capacity else "Место не открыто"]
			)
			entry.add_theme_color_override("font_color", MUTED)
			continue
		var player: Dictionary = players[index]
		var id := str(player.get("id", ""))
		var badge := " · ты" if id == _you else ""
		if id == host:
			badge += " · ведущий"
		entry.text = "%02d    %s%s" % [index + 1, str(player.get("name", "Лось")), badge]
		entry.add_theme_color_override("font_color", GOLD if id == _you else PAPER)
	if code != previous_code or _you != host:
		chapter_input.select(clampi(int(_info.get("chapter", 0)), 0, chapter_input.item_count - 1))
	if bool(_info.get("started", false)):
		waiting.text = "Банда отправляется во двор…"
	elif players.size() < 2:
		waiting.text = "Пригласи хотя бы одного друга. Начать можно от двух игроков."
	elif _you == host:
		waiting.text = "Банда собралась. Когда все будут готовы, выбери главу и начинайте."
	else:
		waiting.text = "Ждём ведущего: он выбирает главу и начинает игру."
	_update_controls()


func show_error(message: String) -> void:
	_busy = false
	status.text = message
	status.add_theme_color_override("font_color", Color("f3a08a"))
	_update_controls()


func set_busy(message: String) -> void:
	_busy = true
	status.text = message
	status.add_theme_color_override("font_color", GOLD)
	_update_controls()


func _update_controls() -> void:
	name_input.editable = not _busy
	code_input.editable = not _busy
	capacity_input.editable = not _busy
	create_button.disabled = _busy
	join_button.disabled = _busy
	var is_host := _in_room and str(_info.get("host", "")) == _you
	var started := bool(_info.get("started", false))
	var players: Array = _info.get("players", [])
	chapter_input.disabled = _busy or not is_host or started
	start_button.disabled = _busy or not is_host or started or players.size() < 2
	start_button.text = "Начать вместе" if is_host else "Ждём ведущего"
	copy_button.disabled = str(_info.get("code", "")).is_empty()
	leave_button.disabled = _busy
	back_button.disabled = _busy


func _create() -> void:
	if _busy:
		return
	if not _valid_name():
		return
	set_busy("Создаём комнату…")
	create_requested.emit(name_input.text.strip_edges(), int(capacity_input.value))


func _join() -> void:
	if _busy:
		return
	if not _valid_name():
		return
	var code := code_input.text.strip_edges().to_upper()
	if code.is_empty():
		show_error("Введи код комнаты из приглашения.")
		code_input.grab_focus()
		return
	code_input.text = code
	set_busy("Подключаемся к комнате…")
	join_requested.emit(name_input.text.strip_edges(), code)


func _valid_name() -> bool:
	if not name_input.text.strip_edges().is_empty():
		return true
	show_error("Введи имя, чтобы друзья узнали тебя в банде.")
	name_input.grab_focus()
	return false


func _start() -> void:
	if start_button.disabled:
		return
	set_busy("Собираем банду во дворе…")
	start_requested.emit(chapter_input.selected)


func _copy_invite() -> void:
	var code := str(_info.get("code", ""))
	if code.is_empty():
		return
	var base := "https://smash.xedoc.ru/coop-game/"
	if OS.has_feature("web"):
		base = str(JavaScriptBridge.eval("location.origin + location.pathname", true))
	DisplayServer.clipboard_set(base + "?room=" + code.uri_encode())
	status.text = "Приглашение скопировано. Отправь ссылку друзьям."
	status.add_theme_color_override("font_color", GOLD)


func _leave() -> void:
	leave_requested.emit()


func _back() -> void:
	back_requested.emit()


func _field(
	parent: Control, at: Vector2, extent: Vector2, placeholder: String, limit: int
) -> LineEdit:
	var field := LineEdit.new()
	field.position = at
	field.size = extent
	field.placeholder_text = placeholder
	field.max_length = limit
	_skin_input(field)
	parent.add_child(field)
	return field


func _skin_input(field: LineEdit) -> void:
	field.add_theme_font_size_override("font_size", 20)
	field.add_theme_color_override("font_color", PAPER)
	field.add_theme_color_override("font_placeholder_color", MUTED)
	field.add_theme_color_override("caret_color", GOLD)
	field.add_theme_stylebox_override("normal", _style(Color("263b40")))
	field.add_theme_stylebox_override("read_only", _style(Color("1a2b30")))
	field.add_theme_stylebox_override("focus", _focus_style())


func _button(
	parent: Control,
	at: Vector2,
	extent: Vector2,
	caption: String,
	action: Callable,
	primary: bool = false
) -> Button:
	var button := Button.new()
	button.position = at
	button.size = extent
	button.text = caption
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", INK if primary else PAPER)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_focus_color", INK if primary else PAPER)
	button.add_theme_color_override("font_disabled_color", Color("77908a"))
	button.add_theme_stylebox_override(
		"normal", _style(GOLD if primary else Color(0.05, 0.12, 0.14, 0.8))
	)
	button.add_theme_stylebox_override("hover", _style(PAPER))
	button.add_theme_stylebox_override("pressed", _style(Color("b59a69")))
	button.add_theme_stylebox_override("disabled", _style(Color("172e32")))
	button.add_theme_stylebox_override("focus", _focus_style())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _panel(parent: Control, at: Vector2, extent: Vector2) -> void:
	var panel := Panel.new()
	panel.position = at
	panel.size = extent
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color(0.03, 0.08, 0.09, 0.7)))
	parent.add_child(panel)


func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _focus_style() -> StyleBoxFlat:
	var style := _style(Color(0, 0, 0, 0))
	style.set_border_width_all(2)
	style.border_color = GOLD
	return style


func _label(
	parent: Control, at: Vector2, caption: String, font_size: int, color: Color = PAPER
) -> Label:
	var label := Label.new()
	label.position = at
	label.text = caption
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
