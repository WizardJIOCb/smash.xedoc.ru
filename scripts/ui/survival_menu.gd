extends RefCounted

const GOLD := Color("e2b36e")


func home(front, resumable: bool) -> void:
	front._page("survival")
	front._label(front.content, Vector2(64, 112), "ВЫЖИВАНИЕ", 64)
	front._label(
		front.content, Vector2(70, 198), "До какой волны дошёл — такой ты и царь.", 24, GOLD
	)
	front._label(
		front.content,
		Vector2(72, 252),
		(
			"Враги заходят с двух сторон. Каждая волна злее.\n"
			+ "Между волнами — передышка, здоровье и оружие.\n"
			+ "В коопе павшие встают после зачистки. Все легли — конец."
		),
		20
	)
	if resumable:
		front._button("Продолжить выживание", 358, func(): front.resume_requested.emit(), true)
		front._button("Начать заново · соло", 414, func(): front.survival_solo_requested.emit())
	else:
		front._button(
			"Выживать в одиночку", 358, func(): front.survival_solo_requested.emit(), true
		)
		front._button("Выживать вместе · 2–16", 414, func(): front.survival_coop_requested.emit())
	front._button(
		"Цари района · рейтинг", 478, func(): front.survival_records_requested.emit("solo")
	)
	front._button("← Главное меню", 610, func(): front.show_home(front.can_resume))


func finish(
	front, stats: Dictionary, name_text: String, can_submit: bool, cooperative: bool
) -> void:
	front._page("survival_finish")
	front._label(front.content, Vector2(64, 108), "Царь района пока отдыхает", 34)
	front._label(front.content, Vector2(64, 172), "ВОЛНА %d" % int(stats.wave), 70, GOLD)
	var seconds := int(stats.seconds)
	front._label(
		front.content,
		Vector2(72, 270),
		(
			"%d врагов · %02d:%02d · %s зачёт"
			% [
				int(stats.kills),
				seconds / 60,
				seconds % 60,
				"командный" if cooperative else "одиночный"
			]
		),
		22
	)
	front.name_input = LineEdit.new()
	front.name_input.position = Vector2(72, 338)
	front.name_input.size = Vector2(440, 48)
	front.name_input.placeholder_text = "Название банды" if cooperative else "Как тебя зовёт двор?"
	front.name_input.text = name_text
	front.name_input.max_length = 20
	front.name_input.add_theme_stylebox_override("normal", front._style(Color("263b40")))
	front.content.add_child(front.name_input)
	front.submit_button = front._button(
		"Записать результат",
		406,
		func():
			front.submit_button.disabled = true
			front.score_status.text = "Записываем результат…"
			front.survival_submit_requested.emit(front.name_input.text),
		true
	)
	front.submit_button.disabled = not can_submit
	if not can_submit:
		front.submit_button.text = "Результат записывает ведущий"
	front.score_status = front._label(front.content, Vector2(72, 472), "", 14)
	var again: Button = front._button("Ещё волны", 496, func(): front.survival_requested.emit())
	again.size.y = 50
	if cooperative and not can_submit:
		again.disabled = true
		again.text = "Следующий забег начнёт ведущий"
	var records_button: Button = front._button(
		"Рейтинг выживания",
		552,
		func(): front.survival_records_requested.emit("coop" if cooperative else "solo")
	)
	records_button.size.y = 50
	var home_button: Button = front._button("Главное меню", 608, func(): front.show_home(false))
	home_button.size.y = 50


func records(front, board: String, rows: Array, online: bool, loading: bool = false) -> void:
	front._page("survival_records")
	front._label(front.content, Vector2(64, 104), "ЦАРИ РАЙОНА", 56)
	front._label(
		front.content,
		Vector2(68, 178),
		"Волна → враги → время. Одиночный и командный зачёты отдельно.",
		18,
		GOLD
	)
	var selector := OptionButton.new()
	selector.position = Vector2(810, 112)
	selector.size = Vector2(406, 48)
	selector.add_item("Одиночный зачёт")
	selector.add_item("Командный зачёт · 2–16")
	selector.selected = 1 if board == "coop" else 0
	selector.item_selected.connect(
		func(index: int): front.survival_records_requested.emit("coop" if index == 1 else "solo")
	)
	front.content.add_child(selector)
	var table := Tree.new()
	table.position = Vector2(64, 244)
	table.size = Vector2(1152, 340)
	table.columns = 5
	table.hide_root = true
	table.column_titles_visible = true
	table.add_theme_font_size_override("font_size", 20)
	table.add_theme_constant_override("v_separation", 12)
	table.add_theme_stylebox_override("panel", front._style(Color(0.03, 0.08, 0.09, 0.93)))
	var headings := ["МЕСТО", "БАНДА" if board == "coop" else "ИМЯ", "ВОЛНА", "ВРАГИ", "ВРЕМЯ"]
	for index in range(5):
		table.set_column_title(index, headings[index])
		table.set_column_custom_minimum_width(index, 380 if index == 1 else 140)
	front.content.add_child(table)
	var base := table.create_item()
	for index in range(mini(rows.size(), 10)):
		var row: Dictionary = rows[index]
		var item := table.create_item(base)
		item.set_text(0, "%02d" % (index + 1))
		item.set_text(
			1,
			(
				str(row.get("name", "Лось"))
				+ (" · %d игрока" % int(row.get("players", 2)) if board == "coop" else "")
			)
		)
		item.set_text(2, str(row.wave))
		item.set_text(3, str(row.kills))
		var seconds := int(row.seconds)
		item.set_text(4, "%02d:%02d" % [seconds / 60, seconds % 60])
		if index == 0:
			for column in range(5):
				item.set_custom_color(column, GOLD)
	if rows.is_empty():
		front._label(
			front.content,
			Vector2(112, 350),
			"Загружаем царей…" if loading else "Трон свободен. Покажи, кто тут царь.",
			24
		)
	front._label(
		front.content,
		Vector2(68, 600),
		"Рейтинг сайта" if online else "Рекорды на этом устройстве",
		16,
		GOLD
	)
	front._button("← Выживание", 636, func(): front.survival_menu_requested.emit())
