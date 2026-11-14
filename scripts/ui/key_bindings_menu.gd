extends Control

signal closed
signal changed

var bindings: RefCounted
var pending: String = ""
var buttons: Dictionary = {}
var message: Label


func _ready() -> void:
	var title := Label.new()
	title.text = "Клавиши управления"
	title.position = Vector2(64, 80)
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)
	message = Label.new()
	message.text = "Нажми кнопку действия, затем новую клавишу. Esc — отмена."
	message.position = Vector2(68, 134)
	message.add_theme_font_size_override("font_size", 18)
	add_child(message)
	var index := 0
	for action: String in bindings.ACTIONS:
		var at := Vector2(64 + (index / 9) * 596, 186 + (index % 9) * 42)
		var label := Label.new()
		label.text = str(bindings.ACTIONS[action])
		label.position = at
		label.add_theme_font_size_override("font_size", 18)
		add_child(label)
		var button := _button(bindings.caption(action), at + Vector2(248, -3), Vector2(270, 35))
		button.pressed.connect(_choose.bind(action))
		buttons[action] = button
		index += 1
	call_deferred("_refresh")
	var back := _button("← Настройки", Vector2(64, 614), Vector2(300, 48))
	back.pressed.connect(func() -> void: closed.emit())
	var reset_button := _button("Сбросить клавиши", Vector2(840, 614), Vector2(340, 48))
	reset_button.pressed.connect(
		func() -> void:
			pending = ""
			bindings.reset()
			_refresh()
			message.text = "Стандартные клавиши восстановлены."
			changed.emit()
	)


func _button(text: String, at: Vector2, extent: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = extent
	button.add_theme_font_size_override("font_size", 18)
	add_child(button)
	return button


func _choose(action: String) -> void:
	pending = action
	_refresh()
	buttons[action].text = "Нажми клавишу…"
	message.text = str(bindings.ACTIONS[action]) + ": нажми новую клавишу. Esc — отмена."
	get_viewport().gui_release_focus()


func _input(event: InputEvent) -> void:
	if pending.is_empty() or not event is InputEventKey:
		return
	get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_ESCAPE:
		pending = ""
		_refresh()
		message.text = "Изменение отменено."
		return
	var error: String = bindings.rebind(pending, event.physical_keycode)
	if not error.is_empty():
		message.text = error
		return
	pending = ""
	_refresh()
	message.text = "Сохранено на этом устройстве."
	changed.emit()


func _refresh() -> void:
	for action: String in buttons:
		buttons[action].text = bindings.caption(action)
