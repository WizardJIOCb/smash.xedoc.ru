extends Node
## Casual survival records; campaign progress is never read or written here.

signal changed
signal submitted(online: bool)

var board: String = "solo":
	set(value):
		var selected := value if value in ["solo", "coop"] else "solo"
		if selected == board:
			return
		board = selected
		_generation += 1
		token = ""
		busy = false
		online = false
		rows = _local_board_rows()
var players: int = 1
var rows: Array = []
var local_rows: Array = []
var online: bool = false
var busy: bool = false
var player_name: String = ""
var token: String = ""
var endpoint: String = ""
var _generation: int = 0
var _list_generation: int = 0
var _finished: bool = false
var _storage_path: String = "user://survival-records.json"


func _ready() -> void:
	var raw := (
		FileAccess.get_file_as_string(_storage_path)
		if FileAccess.file_exists(_storage_path)
		else ""
	)
	if raw.is_empty() and OS.has_feature("web"):
		raw = str(
			JavaScriptBridge.eval(
				(
					"(() => { try { return localStorage.getItem('smash-survival-v1') || ''; }"
					+ " catch(e) { return ''; } })()"
				),
				true
			)
		)
	var stored: Variant = JSON.parse_string(raw) if not raw.is_empty() else null
	if stored is Dictionary and stored.get("version") == 1:
		var saved_rows: Variant = stored.get("scores", [])
		if saved_rows is Array:
			for item: Variant in saved_rows:
				if (
					item is Dictionary
					and _valid_stats(item)
					and item.get("board") in ["solo", "coop"]
				):
					local_rows.append(item)
		player_name = str(stored.get("name", ""))
	_trim_local()
	rows = _local_board_rows()
	if OS.has_feature("web") and endpoint.is_empty():
		var origin := str(JavaScriptBridge.eval("window.location.origin", true))
		if origin.begins_with("https://"):
			endpoint = origin + "/api/survival.php"


func refresh() -> void:
	_list_generation += 1
	if endpoint.is_empty():
		online = false
		rows = _local_board_rows()
		changed.emit()
		return
	_request("list", {}, HTTPClient.METHOD_GET)


func begin(board_name: String = "solo", party_size: int = 1) -> void:
	board = board_name
	players = 1 if board == "solo" else clampi(party_size, 2, 16)
	_generation += 1
	_finished = false
	busy = false
	token = ""
	if not endpoint.is_empty():
		_request("start", {"op": "start", "board": board, "players": players})


func finish(name_text: String, stats: Dictionary) -> void:
	if _finished or busy:
		return
	if not _valid_stats(stats):
		submitted.emit(false)
		return
	_finished = true
	_generation += 1
	player_name = name_text.strip_edges().left(20)
	if player_name.is_empty():
		player_name = "Лось"
	var row := {
		"name": player_name,
		"wave": int(stats.wave),
		"kills": int(stats.kills),
		"seconds": snappedf(float(stats.seconds), 0.01),
		"board": board,
		"players": players,
	}
	local_rows.append(row)
	_trim_local()
	_save_local()
	rows = _local_board_rows()
	online = false
	if endpoint.is_empty() or token.is_empty():
		token = ""
		submitted.emit(false)
		changed.emit()
		return
	busy = true
	var payload := row.duplicate()
	payload.merge({"op": "finish", "token": token}, true)
	token = ""
	_request("finish", payload)


static func ranked_before(a: Dictionary, b: Dictionary) -> bool:
	if int(a.wave) != int(b.wave):
		return int(a.wave) > int(b.wave)
	if int(a.kills) != int(b.kills):
		return int(a.kills) > int(b.kills)
	return float(a.seconds) < float(b.seconds)


static func _valid_stats(stats: Dictionary) -> bool:
	var wave: Variant = stats.get("wave")
	var kills: Variant = stats.get("kills")
	var seconds: Variant = stats.get("seconds")
	if not (wave is int or wave is float) or not (kills is int or kills is float):
		return false
	if not (seconds is int or seconds is float):
		return false
	return (
		is_finite(float(wave))
		and is_finite(float(kills))
		and is_finite(float(seconds))
		and wave == int(wave)
		and kills == int(kills)
		and wave >= 1
		and wave <= 10000
		and kills >= wave - 1
		and kills <= 1000000
		and seconds >= 5
		and seconds <= 86400
	)


func _local_board_rows() -> Array:
	return (
		local_rows
		. filter(func(row: Dictionary) -> bool: return row.get("board") == board)
		. slice(0, 10)
	)


func _trim_local() -> void:
	local_rows.sort_custom(ranked_before)
	var kept: Array = []
	for group: String in ["solo", "coop"]:
		kept.append_array(
			local_rows.filter(func(row: Dictionary) -> bool: return row.board == group).slice(0, 50)
		)
	local_rows = kept


func _save_local() -> void:
	var raw := JSON.stringify({"version": 1, "scores": local_rows, "name": player_name})
	var file := FileAccess.open(_storage_path, FileAccess.WRITE)
	if file != null:
		file.store_string(raw)
	elif OS.has_feature("web"):
		JavaScriptBridge.eval(
			(
				"try { localStorage.setItem('smash-survival-v1', %s); } catch(e) {}"
				% JSON.stringify(raw)
			),
			true
		)


func _request(operation: String, payload: Dictionary, method: int = HTTPClient.METHOD_POST) -> void:
	var request := HTTPRequest.new()
	request.timeout = 8
	add_child(request)
	var generation := _generation
	var list_generation := _list_generation
	request.request_completed.connect(
		_response.bind(operation, request, generation, list_generation)
	)
	var error := request.request(
		endpoint + ("?board=" + board if method == HTTPClient.METHOD_GET else ""),
		["Content-Type: application/json"],
		method,
		"" if method == HTTPClient.METHOD_GET else JSON.stringify(payload)
	)
	if error != OK:
		_response(
			HTTPRequest.RESULT_CANT_CONNECT,
			0,
			PackedStringArray(),
			PackedByteArray(),
			operation,
			request,
			generation,
			list_generation
		)


func _response(
	result: int,
	code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	operation: String,
	request: HTTPRequest,
	generation: int,
	list_generation: int
) -> void:
	request.queue_free()
	if generation != _generation or (operation == "list" and list_generation != _list_generation):
		return
	var data: Variant = (
		JSON.parse_string(body.get_string_from_utf8()) if not body.is_empty() else null
	)
	var success := result == HTTPRequest.RESULT_SUCCESS and code == 200 and data is Dictionary
	if operation == "start":
		if success and data.get("board") == board and data.get("players") == players:
			token = str(data.get("token", ""))
		return
	if success:
		success = data.get("board") == board and data.get("scores") is Array
	if operation == "finish":
		success = success and data.get("saved", false) == true
		busy = false
		_list_generation += 1
	online = success
	rows = data.scores if success else _local_board_rows()
	if operation == "finish":
		submitted.emit(success)
	changed.emit()
