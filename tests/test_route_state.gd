extends GutTest

const Route = preload("res://scripts/core/route_state.gd")


func test_chapter_content_matches_score_contract_and_reinforcements_cannot_repeat() -> void:
	var route := Route.new()
	var rooms: Array = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/district_rooms.json")
	)
	assert_eq(rooms.size(), 11)
	rooms.append(JSON.parse_string(FileAccess.get_file_as_string("res://data/holiday_room.json")))
	for chapter: Dictionary in route.chapters:
		var kills := 0
		for index in range(int(chapter.start), int(chapter.end) + 1):
			var room: Dictionary = rooms[index]
			kills += room.enemies.size()
			route.enter()
			for wave: Array in room.get("waves", []):
				kills += wave.size()
				assert_true(
					route.reinforcement(room, 1, 5).is_empty(),
					"Living guards prevent the next wave"
				)
				assert_true(route.reinforcement(room, 0, 0.9).is_empty())
				assert_eq(route.reinforcement(room, 0, 1.0), wave)
			assert_true(route.waves_done(room))
			assert_true(
				route.reinforcement(room, 0, 10).is_empty(), "The final wave is not repeated"
			)
		assert_eq(kills, int(chapter.kills), "Chapter kills match the server score contract")
