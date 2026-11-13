extends CanvasLayer

signal start_requested
signal resume_requested
signal submit_requested(name_text: String)
signal mute_requested
signal records_requested
signal fps_requested(enabled: bool)

const Moose = preload("res://scripts/actors/moose_rig.gd")
const FONT = preload("res://assets/fonts/Manrope-Semibold.tres")

var root: Control
var content: Control
var portrait: Node2D
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
	background.texture = load("res://assets/environment/courtyard-alive-clean.png")
	background.size = Vector2(1280, 720)
	background.modulate = Color(0.66, 0.76, 0.74)
	background.z_index = -50
	root.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.065, 0.075, 0.88)
	shade.size = Vector2(640, 720)
	shade.z_index = -49
	root.add_child(shade)
	portrait = Node2D.new()
	portrait.position = Vector2(940, 657)
	portrait.scale = Vector2.ONE * 2.25
	root.add_child(portrait)
	var hero := Moose.new()
	portrait.add_child(hero)
	ambience = Control.new()
	ambience.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ambience.draw.connect(_draw_ambience)
	root.add_child(ambience)
	_label(root, Vector2(64, 32), "ЛОСЬ В ПРОДЕ  /  ИГРОВОЙ РАЙОН", 14, Color("e2b36e"))
	_label(root, Vector2(64, 672), "SMASH.XEDOC.RU    ·    ПЕРВЫЙ МАРШРУТ", 14, Color("b3c4b6"))
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
	_button("Продолжить" if can_resume else "Войти во двор", 374, _play, true)
	_button("Рекорды района", 438, show_records)
	_button("Как играть", 502, show_help)
	_button("Настройки", 566, show_settings)
	if can_resume:
		var restart := _button("Начать заново", 614, func() -> void: start_requested.emit())
		restart.add_theme_font_size_override("font_size", 16)


func _page(id: String) -> void:
	page = id
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	root.show()
	portrait.visible = id == "home" or id == "finish"
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
	_label(content, Vector2(64, 112), "Рекорды района", 48)
	_label(
		content,
		Vector2(68, 184),
		"Общий зачёт сайта" if online else "Рекорды на этом компе",
		18,
		Color("e2b36e")
	)
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
	_label(content, Vector2(64, 112), "Как устроить шум", 48)
	_label(
		content,
		Vector2(72, 216),
		(
			"A / D или ← / →     Ходить\nShift     Бежать\nW / ↑ / Пробел     Прыгать"
			+ "\nS / ↓     Присесть и идти в приседе\nJ     Серия ударов руками"
			+ "\nK     Серия ударов ногами\nL     Блок · удерживать · −75% урона\nE     Отключить реле"
			+ "\nT     День / ночь\nQ     Ульта · 8 секунд\nO     Импульс во время ульты"
			+ "\nEsc     Меню    R     Повтор    M     Звук"
		),
		21
	)
	_label(
		content,
		Vector2(704, 264),
		(
			"Сними три узла карантина.\n\nЩит пробивается ногой."
			+ "\nПод кабелем можно присесть.\nДрон запоминает, куда целился."
			+ "\n\nУльта: урон ×1,8 и красная аура.\nO — импульс, перерыв 2 секунды."
			+ "\nРаботает и днём, и ночью.\nЗаряд — за попадания и победы."
		),
		24,
		Color("e2b36e")
	)
	_button("← Главное меню", 614, func() -> void: show_home(can_resume)).grab_focus()


func show_finish(score: int, seconds: float, previous_name: String) -> void:
	_page("finish")
	_label(content, Vector2(64, 112), "Район снова дышит", 36)
	_label(content, Vector2(64, 168), str(score), 72, Color("e2b36e"))
	_label(
		content,
		Vector2(72, 264),
		(
			"Очков за %02d:%02d\nПять охранников. Три узла. Твои рога."
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
	_button("← Главное меню", 614, func() -> void: show_home(can_resume))


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
		portrait.position.y = 657 + sin(clock * 0.6) * 2


func _draw_ambience() -> void:
	for index in range(34):
		var point := Vector2(
			fposmod(index * 233.7 + clock * (4 + index % 3), 1280),
			180 + fposmod(index * 77.4 - clock * 8, 520)
		)
		var opacity := 0.18 + sin(clock * 1.2 + index) * 0.12
		ambience.draw_circle(point, 1.3 + index % 3 * 0.4, Color(0.95, 0.71, 0.33, opacity))
