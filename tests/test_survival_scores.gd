extends GutTest

const Scores = preload("res://scripts/core/survival_scores.gd")


class FakeScores:
	extends "res://scripts/core/survival_scores.gd"

	var requests: Array = []

	func _request(
		operation: String, payload: Dictionary, method: int = HTTPClient.METHOD_POST
	) -> void:
		requests.append(
			{
				"op": operation,
				"payload": payload,
				"method": method,
				"generation": _generation,
				"list_generation": _list_generation
			}
		)


var scores: FakeScores
var submissions: Array = []


func before_each() -> void:
	scores = FakeScores.new()
	scores._storage_path = "user://survival-test-%s.json" % Time.get_ticks_usec()
	add_child_autofree(scores)
	scores.submitted.connect(func(value: bool) -> void: submissions.append(value))
	submissions.clear()


func after_each() -> void:
	if FileAccess.file_exists(scores._storage_path):
		DirAccess.remove_absolute(scores._storage_path)


func reply(index: int, data: Dictionary, code: int = 200) -> void:
	var request := HTTPRequest.new()
	scores.add_child(request)
	var captured: Dictionary = scores.requests[index]
	scores._response(
		HTTPRequest.RESULT_SUCCESS,
		code,
		PackedStringArray(),
		JSON.stringify(data).to_utf8_buffer(),
		captured.op,
		request,
		captured.generation,
		captured.list_generation
	)


func test_wave_kills_time_order_and_separate_local_boards_survive_reload() -> void:
	for stats: Dictionary in [
		{"wave": 2, "kills": 100, "seconds": 5.0},
		{"wave": 3, "kills": 9, "seconds": 5.0},
		{"wave": 3, "kills": 10, "seconds": 20.0},
		{"wave": 3, "kills": 10, "seconds": 10.0},
	]:
		scores.begin()
		scores.finish("Solo", stats)
	assert_eq(
		scores.rows.map(func(row: Dictionary) -> float: return row.seconds), [10.0, 20.0, 5.0, 5.0]
	)
	scores.begin("coop", 16)
	scores.finish("Party", {"wave": 100, "kills": 200, "seconds": 90.0})
	assert_eq(scores.rows.size(), 1)
	assert_eq(scores.rows[0].players, 16)
	var loaded := Scores.new()
	loaded._storage_path = scores._storage_path
	add_child_autofree(loaded)
	loaded.refresh()
	assert_eq(loaded.rows.size(), 4)
	assert_eq(int(loaded.rows[0].wave), 3)
	loaded.board = "coop"
	loaded.refresh()
	assert_eq(loaded.rows.size(), 1)
	assert_eq(loaded.rows[0].name, "Party")


func test_late_start_cannot_replace_new_run_token() -> void:
	scores.endpoint = "https://example.invalid/api/survival.php"
	scores.begin("solo")
	scores.begin("solo")
	reply(1, {"token": "new", "board": "solo", "players": 1})
	reply(0, {"token": "old", "board": "solo", "players": 1})
	assert_eq(scores.token, "new")


func test_finish_before_start_reply_is_local_once_and_old_reply_is_ignored() -> void:
	scores.endpoint = "https://example.invalid/api/survival.php"
	scores.begin()
	scores.finish("Local", {"wave": 1, "kills": 0, "seconds": 5.0})
	scores.finish("Duplicate", {"wave": 1, "kills": 0, "seconds": 5.0})
	reply(0, {"token": "late", "board": "solo", "players": 1})
	assert_eq(submissions, [false])
	assert_eq(scores.token, "")
	assert_eq(scores.local_rows.size(), 1)
	assert_false(scores.online)


func test_old_finish_and_list_responses_cannot_replace_new_board_or_busy_run() -> void:
	scores.endpoint = "https://example.invalid/api/survival.php"
	scores.begin()
	reply(0, {"token": "first", "board": "solo", "players": 1})
	scores.refresh()
	scores.finish("First", {"wave": 1, "kills": 0, "seconds": 5.0})
	scores.begin("coop", 2)
	reply(1, {"board": "solo", "scores": [{"name": "stale"}]})
	reply(2, {"saved": true, "board": "solo", "scores": [{"name": "stale"}]})
	assert_eq(scores.board, "coop")
	assert_eq(scores.rows, [])
	assert_eq(submissions, [])
	assert_false(scores.online)


func test_only_saved_true_confirms_submission_and_failed_server_keeps_local_result() -> void:
	scores.endpoint = "https://example.invalid/api/survival.php"
	scores.begin()
	reply(0, {"token": "first", "board": "solo", "players": 1})
	scores.finish("Local", {"wave": 2, "kills": 3, "seconds": 5.0})
	reply(1, {"saved": false, "board": "solo", "scores": []})
	assert_eq(submissions, [false])
	assert_eq(scores.rows[0].name, "Local")
	scores.begin()
	reply(2, {"token": "second", "board": "solo", "players": 1})
	scores.finish("Shared", {"wave": 3, "kills": 5, "seconds": 10.0})
	reply(3, {"saved": true, "board": "solo", "scores": [{"name": "Shared"}]})
	assert_eq(submissions, [false, true])
	assert_true(scores.online)
	assert_false(scores.busy)


func test_newer_refresh_wins_and_board_limits_do_not_discard_other_group() -> void:
	scores.endpoint = "https://example.invalid/api/survival.php"
	scores.refresh()
	scores.refresh()
	reply(1, {"board": "solo", "scores": [{"name": "current"}]})
	reply(0, {"board": "solo", "scores": [{"name": "stale"}]})
	assert_eq(scores.rows[0].name, "current")
	scores.endpoint = ""
	for group: String in ["solo", "coop"]:
		for wave: int in range(1, 53):
			scores.begin(group, 2)
			scores.finish("Player", {"wave": wave, "kills": wave, "seconds": 60.0})
	assert_eq(scores.local_rows.size(), 100)
	assert_eq(scores.rows.size(), 10)
	assert_eq(scores.rows[0].wave, 52)
	scores.board = "solo"
	scores.refresh()
	assert_eq(scores.rows[0].wave, 52)


func test_refresh_snapshot_during_finish_cannot_erase_confirmed_result() -> void:
	scores.endpoint = "https://example.invalid/api/survival.php"
	scores.begin()
	reply(0, {"token": "run", "board": "solo", "players": 1})
	scores.finish("Winner", {"wave": 2, "kills": 3, "seconds": 5.0})
	scores.refresh()
	reply(1, {"saved": true, "board": "solo", "scores": [{"name": "Winner"}]})
	reply(2, {"board": "solo", "scores": []})
	assert_eq(scores.rows[0].name, "Winner")
	assert_eq(submissions, [true])
