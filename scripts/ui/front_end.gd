extends CanvasLayer

signal chapter_requested(index: int)
signal next_requested
signal start_requested
signal resume_requested
signal submit_requested(name_text: String)
signal mute_requested
signal records_requested
signal fps_requested(enabled: bool)
signal coop_requested

const Moose = preload("res://scripts/actors/moose_rig.gd")
const FONT = preload("res://assets/fonts/Manrope-Semibold.tres")
const KeyMenu = preload("res://scripts/ui/key_bindings_menu.gd")
const CHAPTERS_PER_PAGE := 3

var bindings: RefCounted

var chapters: Array = []
var chapter_index: int = 0
var chapter_page: int = 0
var completed_chapters: Array = []
var root: Control
var content: Control
var portrait: Node2D
var contact_shadow: Node2D
var menu_hero: Node2D
var ambience: Control
var home_title: Label
var page: String = "home"
var can_resume: bool = false
var muted: bool = true
var fps_enabled: bool = true
var clock: float = 0.0
var rows: Array = []
var online: bool = false
var name_input: LineEdit
var score_status: Label
var submit_button: Button


func _ready() -> void:
	layer = 20
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.theme = Theme.new()
	root.theme.default_font = FONT
	root.theme.default_font_size = 20
	add_child(root)
	var background := TextureRect.new()
	background.texture = load("res://assets/environment/menu-ground-v1.webp")
	background.size = Vector2(1280, 720)
	background.modulate = Color(0.86, 0.91, 0.89)
	background.z_index = -50
	root.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.065, 0.075, 0.88)
	shade.size = Vector2(640, 720)
	shade.z_index = -49
	root.add_child(shade)
	contact_shadow = Node2D.new()
	contact_shadow.draw.connect(_draw_contact_shadow)
	root.add_child(contact_shadow)
	portrait = Node2D.new()
	portrait.position = Vector2(940, 657)
	portrait.scale = Vector2.ONE * 2.25
	root.add_child(portrait)
	menu_hero = Moose.new()
	portrait.add_child(menu_hero)
	ambience = Control.new()
	ambience.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ambience.draw.connect(_draw_ambience)
	root.add_child(ambience)
	_label(root, Vector2(64, 32), "ЛОСЬ В ПРОДЕ  /  ИГРОВОЙ РАЙОН", 14, Color("e2b36e"))
	var room_count := 0
	for chapter: Dictionary in chapters:
		room_count += int(chapter.end) - int(chapter.start) + 1
	_label(
		root,
		Vector2(64, 672),
		"SMASH.XEDOC.RU    ·    ГЛАВ: %d / УРОВНЕЙ: %d" % [chapters.size(), room_count],
		14,
		Color("b3c4b6")
	)
	content = Control.new()
	root.add_child(content)
	show_home(false)


func show_home(resumable: bool) -> void:
	can_resume = resumable
	_page("home")
	home_title = _label(content, Vector2(64, 112), "ЛОСЬ", 96)
	_label(content, Vector2(69, 216), "РАЙОН ЗАКРЫТ", 36, Color("e2b36e"))
	_label(
		content,
		Vector2(72, 280),
		"Рога на месте. Двор под карантином.\nУ Firewall сейчас будут проблемы.",
		20
	)
	_button("Продолжить" if can_resume else "Войти во двор", 350, _play, true)
	_button("По сети · 2–16 игроков", 402, func() -> void: coop_requested.emit())
	_button("Выбрать главу", 454, show_chapters)
	_button("Рекорды", 506, show_records)
	_button("Как играть", 558, show_help)
	_button("Настройки", 610, show_settings)
	for child: Node in content.get_children():
		if child is Button:
			child.size.y = 48


func _page(id: String) -> void:
	page = id
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	root.show()
	portrait.visible = id == "home" or id == "finish"
	contact_shadow.visible = portrait.visible
	root.modulate.a = 0
	(
		create_tween()
		. tween_property(root, "modulate:a", 1.0, 0.3)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
	)


func hide_menu() -> void:
	root.hide()
	get_viewport().gui_release_focus()


func is_open() -> bool:
	return is_instance_valid(root) and root.visible


func show_records(refresh: bool = true) -> void:
	if refresh:
		records_requested.emit()
	_page("records")
	_label(
		content,
		Vector2(64, 112),
		"Рекорды · " + (str(chapters[chapter_index].title) if not chapters.is_empty() else "Район"),
		38
	)
	_label(
		content,
		Vector2(68, 184),
		"Общий зачёт сайта" if online else "Рекорды на этом компе",
		18,
		Color("e2b36e")
	)
	var selector := OptionButton.new()
	selector.position = Vector2(600, 172)
	selector.size = Vector2(610, 44)
	for index in range(chapters.size()):
		selector.add_item("%02d / %s" % [index + 1, chapters[index].title])
	selector.selected = chapter_index
	selector.item_selected.connect(
		func(index: int) -> void:
			chapter_index = index
			records_requested.emit()
	)
	content.add_child(selector)
	var table := Tree.new()
	table.position = Vector2(64, 240)
	table.size = Vector2(1152, 360)
	table.columns = 4
	table.hide_root = true
	table.column_titles_visible = true
	table.add_theme_font_size_override("font_size", 20)
	table.add_theme_constant_override("v_separation", 14)
	table.add_theme_stylebox_override("panel", _style(Color(0.03, 0.08, 0.09, 0.93)))
	var headings := ["МЕСТО", "ИМЯ", "ОЧКИ", "ВРЕМЯ"]
	for index in range(4):
		table.set_column_title(index, headings[index])
		table.set_column_custom_minimum_width(index, 120 if index == 0 else 230)
	content.add_child(table)
	var base := table.create_item()
	for index in range(mini(rows.size(), 10)):
		var row: Dictionary = rows[index]
		var item := table.create_item(base)
		item.set_text(0, "%02d" % (index + 1))
		item.set_text(1, str(row.get("name", "Лось")))
		item.set_text(2, str(row.get("score", 0)))
		var seconds := int(row.get("seconds", 0))
		item.set_text(3, "%02d:%02d" % [seconds / 60, seconds % 60])
		if index == 0:
			for column in range(4):
				item.set_custom_color(column, Color("e2b36e"))
	if rows.is_empty():
		_label(content, Vector2(112, 340), "Пока тихо. Пройди район первым.", 24)
	_button("← Главное меню", 614, func() -> void: show_home(can_resume)).grab_focus()


func show_help() -> void:
	_page("help")
	_label(content, Vector2(64, 100), "Как устроить шум", 42)
	var left := ""
	for action: String in [
		"left", "right", "jump", "crouch", "sprint", "strike", "kick", "block", "quick_turn"
	]:
		left += key(action) + "     " + str(bindings.ACTIONS[action]) + "\n"
	_label(content, Vector2(72, 194), left, 21)
	var right := ""
	for action: String in [
		"interact",
		"cycle_weapon",
		"reload_weapon",
		"drop_weapon",
		"world",
		"ultimate",
		"super_strike",
		"restart",
		"mute"
	]:
		right += key(action) + "     " + str(bindings.ACTIONS[action]) + "\n"
	_label(content, Vector2(704, 194), right, 21, Color("e2b36e"))
	_label(
		content,
		Vector2(72, 538),
		(
			"Esc — меню. Клавиши меняются в настройках.\n"
			+ "Удерживай блок: −75% урона. Удерживай атаку для автомата."
		),
		18
	)
	_button("← Главное меню", 614, func() -> void: show_home(can_resume)).grab_focus()


func key(action: String) -> String:
	return bindings.caption(action) if bindings != null else action


func show_finish(score: int, seconds: float, previous_name: String) -> void:
	_page("finish")
	_label(
		content,
		Vector2(64, 112),
		(
			str(chapters[chapter_index].get("victory", "Глава пройдена"))
			if not chapters.is_empty()
			else "Глава пройдена"
		),
		36
	)
	_label(content, Vector2(64, 168), str(score), 72, Color("e2b36e"))
	_label(
		content,
		Vector2(72, 264),
		(
			(
				"Очков за %02d:%02d\n"
				+ (
					str(chapters[chapter_index].title)
					if not chapters.is_empty()
					else "Район закрыт"
				)
			)
			% [int(seconds) / 60, int(seconds) % 60]
		),
		20
	)
	name_input = LineEdit.new()
	name_input.position = Vector2(72, 352)
	name_input.size = Vector2(440, 48)
	name_input.placeholder_text = "Как тебя зовёт двор?"
	name_input.text = previous_name
	name_input.max_length = 20
	name_input.add_theme_stylebox_override("normal", _style(Color("263b40")))
	content.add_child(name_input)
	submit_button = _button("Записать результат", 422, _submit, true)
	score_status = _label(content, Vector2(72, 486), "", 16)
	if chapter_index + 1 < chapters.size():
		_button(
			"Дальше: " + str(chapters[chapter_index + 1].title),
			526,
			func() -> void: next_requested.emit()
		)
	else:
		_button("Ещё раз", 526, func() -> void: start_requested.emit())
	_button("Главное меню", 590, func() -> void: show_home(false))


func result_saved(shared: bool) -> void:
	if page != "finish":
		return
	score_status.text = (
		"Результат в общей таблице района." if shared else "Результат сохранён на этом компе."
	)
	submit_button.text = "Результат записан"
	submit_button.disabled = true


func _submit() -> void:
	submit_button.disabled = true
	score_status.text = "Записываем результат…"
	submit_requested.emit(name_input.text)


func _play() -> void:
	if can_resume:
		resume_requested.emit()
	else:
		start_requested.emit()


func _toggle_sound() -> void:
	muted = not muted
	mute_requested.emit()
	show_settings()


func show_settings() -> void:
	_page("settings")
	_label(content, Vector2(64, 112), "Настройки", 48)
	_label(content, Vector2(72, 216), "Параметры сохраняются на этом устройстве.", 20)
	_button("Звук: " + ("выключен" if muted else "включён"), 342, _toggle_sound, true)
	_button("Показывать FPS: " + ("да" if fps_enabled else "нет"), 414, _toggle_fps)
	_button("Клавиши управления", 486, show_controls)
	_button("← Главное меню", 614, func() -> void: show_home(can_resume))


func show_controls() -> void:
	_page("controls")
	var keys := KeyMenu.new()
	keys.bindings = bindings
	keys.closed.connect(show_settings)
	content.add_child(keys)


func _toggle_fps() -> void:
	fps_enabled = not fps_enabled
	fps_requested.emit(fps_enabled)
	show_settings()


func _button(text: String, y: float, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = Vector2(64, y)
	button.size = Vector2(472, 56)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("132630") if primary else Color("e7d3ac"))
	button.add_theme_color_override("font_hover_color", Color("132630"))
	button.add_theme_color_override(
		"font_focus_color", Color("132630") if primary else Color("e7d3ac")
	)
	button.add_theme_stylebox_override(
		"normal", _style(Color("e2b36e") if primary else Color(0.05, 0.12, 0.14, 0.4))
	)
	button.add_theme_stylebox_override("hover", _style(Color("e7d3ac")))
	button.add_theme_stylebox_override("pressed", _style(Color("b59a69")))
	var focus := _style(Color(0, 0, 0, 0))
	focus.set_border_width_all(2)
	focus.border_color = Color("e2b36e")
	button.add_theme_stylebox_override("focus", focus)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	content.add_child(button)
	if primary or content.get_child_count() == 1:
		button.grab_focus()
	return button


func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _label(
	parent: Node, at: Vector2, caption: String, size: int, color: Color = Color("e7d3ac")
) -> Label:
	var label := Label.new()
	label.position = at
	label.text = caption
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _process(delta: float) -> void:
	clock += delta
	if is_open():
		ambience.queue_redraw()
		contact_shadow.queue_redraw()


func _draw_contact_shadow() -> void:
	for side: String in ["far", "near"]:
		var foot: Bone2D = menu_hero.bones[side + "_foot"]
		var at := foot.global_position + Vector2(12, 35)
		for ring in range(3):
			var extent := Vector2(53 - ring * 10, 8 - ring * 2)
			contact_shadow.draw_set_transform(at, 0, extent)
			contact_shadow.draw_circle(Vector2.ZERO, 1, Color(0.015, 0.025, 0.025, 0.14))
	contact_shadow.draw_set_transform(Vector2.ZERO)


func _draw_ambience() -> void:
	for index in range(34):
		var point := Vector2(
			fposmod(index * 233.7 + clock * (4 + index % 3), 1280),
			180 + fposmod(index * 77.4 - clock * 8, 520)
		)
		var opacity := 0.18 + sin(clock * 1.2 + index) * 0.12
		ambience.draw_circle(point, 1.3 + index % 3 * 0.4, Color(0.95, 0.71, 0.33, opacity))


func show_chapters() -> void:
	_page("chapters")
	_label(content, Vector2(64, 64), "Город больше одного двора", 42)
	_label(
		content,
		Vector2(68, 128),
		"Начни с любой главы. Между уровнями — контрольные точки, в финале — босс.",
		18
	)
	var last_page := maxi(0, ceili(float(chapters.size()) / CHAPTERS_PER_PAGE) - 1)
	chapter_page = clampi(chapter_page, 0, last_page)
	var first := chapter_page * CHAPTERS_PER_PAGE
	var rooms: Array = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/district_rooms.json")
	)
	for index in range(first, mini(first + CHAPTERS_PER_PAGE, chapters.size())):
		var x := 64.0 + (index - first) * 386
		var frame := ColorRect.new()
		frame.color = Color("10272c")
		frame.position = Vector2(x, 190)
		frame.size = Vector2(350, 330)
		content.add_child(frame)
		var preview := TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_SCALE
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var image := "res://assets/environment/" + str(rooms[int(chapters[index].start)].art)
		preview.texture = load(
			image + (".webp" if ResourceLoader.exists(image + ".webp") else ".png")
		)
		preview.position = Vector2(x, 190)
		preview.size = Vector2(350, 197)
		content.add_child(preview)
		_label(content, Vector2(x + 16, 401), "%02d / %s" % [index + 1, chapters[index].title], 22)
		_label(content, Vector2(x + 16, 440), str(chapters[index].subtitle), 13)
		if index in completed_chapters:
			_label(content, Vector2(x + 16, 473), "ПРОЙДЕНО", 14, Color("a4c7a1"))
		var button := _button(
			"Играть главу",
			544,
			func() -> void: chapter_requested.emit(index),
			index == chapter_index
		)
		button.position.x = x
		button.size.x = 350
	_button("← Главное меню", 614, func() -> void: show_home(can_resume))
	if last_page > 0:
		_label(content, Vector2(816, 632), "%d / %d" % [chapter_page + 1, last_page + 1], 18)
		var previous := _button("←", 614, func() -> void: _turn_chapter_page(-1))
		previous.position.x = 716
		previous.size.x = 72
		previous.disabled = chapter_page == 0
		var following := _button("→", 614, func() -> void: _turn_chapter_page(1))
		following.position.x = 906
		following.size.x = 72
		following.disabled = chapter_page == last_page


func _turn_chapter_page(direction: int) -> void:
	chapter_page += direction
	show_chapters()
