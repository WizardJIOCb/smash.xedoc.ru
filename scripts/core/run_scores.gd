extends Node
## Casual shared scoreboard, with an honest local fallback for offline playtests.

signal changed
signal submitted(online: bool)

var chapter: int = 1
var rows: Array = []
var local_rows: Array = []
var online: bool = false
var busy: bool = false
var player_name: String = ""
var token: String = ""
var endpoint: String = ""
var pending: Dictionary = {}


func _ready() -> void:
	if FileAccess.file_exists("user://records.json"):
		var stored = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
		if stored is Dictionary:
			local_rows = stored.get("scores", [])
			player_name = str(stored.get("name", ""))
	rows = local_rows.filter(
		func(row: Dictionary) -> bool: return int(row.get("chapter", 1)) == chapter
	)
	if OS.has_feature("web"):
		var origin: String = str(JavaScriptBridge.eval("window.location.origin", true))
		if origin.begins_with("https://"):
			endpoint = origin + "/api/scores.php"


func refresh() -> void:
	if endpoint.is_empty():
		online = false
		rows = local_rows.filter(
			func(row: Dictionary) -> bool: return int(row.get("chapter", 1)) == chapter
		)
		changed.emit()
		return
	_request("list", {}, HTTPClient.METHOD_GET)


func begin() -> void:
	token = ""
	if not endpoint.is_empty():
		_request("start", {"op": "start", "chapter": chapter})


func finish(name_text: String, stats: Dictionary) -> void:
	if busy:
		return
	player_name = name_text.strip_edges().left(20)
	if player_name.is_empty():
		player_name = "Лось"
	var row := stats.duplicate()
	row["name"] = player_name
	row["score"] = calculate(stats)
	local_rows.append(row)
	local_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	var kept: Array = []
	var groups: Array = []
	for item: Dictionary in local_rows:
		var group := int(item.get("chapter", 1))
		if not groups.has(group):
			groups.append(group)
	for group: int in groups:
		kept.append_array(
			(
				local_rows
				. filter(
					func(item: Dictionary) -> bool: return int(item.get("chapter", 1)) == group
				)
				. slice(0, 10)
			)
		)
	local_rows = kept
	var file := FileAccess.open("user://records.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scores": local_rows, "name": player_name}))
	if endpoint.is_empty() or token.is_empty():
		rows = local_rows.filter(
			func(row: Dictionary) -> bool: return int(row.get("chapter", 1)) == chapter
		)
		online = false
		submitted.emit(false)
		changed.emit()
		return
	busy = true
	pending = row
	pending.merge({"op": "finish", "token": token}, true)
	_request("finish", pending)


static func calculate(stats: Dictionary) -> int:
	return maxi(
		0,
		(
			5000
			+ int(stats.health) * 10
			+ maxi(0, 3000 - int(float(stats.seconds) * 10))
			- int(stats.deaths) * 200
		)
	)


func _request(operation: String, payload: Dictionary, method: int = HTTPClient.METHOD_POST) -> void:
	var request := HTTPRequest.new()
	request.timeout = 8
	add_child(request)
	request.request_completed.connect(_response.bind(operation, request))
	var error := request.request(
		endpoint + ("?chapter=" + str(chapter) if method == HTTPClient.METHOD_GET else ""),
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
			request
		)


func _response(
	result: int,
	code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	operation: String,
	request: HTTPRequest
) -> void:
	request.queue_free()
	var data = JSON.parse_string(body.get_string_from_utf8()) if not body.is_empty() else null
	var success: bool = result == HTTPRequest.RESULT_SUCCESS and code == 200 and data is Dictionary
	if operation == "start":
		if success:
			token = str(data.get("token", ""))
		return
	busy = false
	online = success
	rows = data.get("scores", []) if success else local_rows.duplicate()
	if operation == "finish":
		token = ""
		submitted.emit(success)
	changed.emit()
