extends GutTest

const Contact = preload("res://scripts/core/combat_contact.gd")
const Sequence = preload("res://scripts/core/attack_sequence.gd")


func test_active_frames_hit_each_target_once_but_allow_the_next_attack() -> void:
	var first := Contact.new()
	var second := Contact.new()
	assert_true(first.accept(17))
	assert_false(first.accept(17))
	assert_true(second.accept(17), "A different target may be struck in the same swing")
	assert_true(first.accept(18))
	assert_false(first.accept(18))


func test_air_bonus_and_high_kick_damage_use_tuning() -> void:
	var tuning: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/encounters.json")
	)
	assert_eq(Contact.damage("punch", 0, false, tuning), 19)
	assert_eq(Contact.damage("kick", 2, true, tuning), 46)
	assert_eq(Contact.damage("kick", 0, false, tuning), 29)


func test_damage_interrupt_discards_buffered_follow_up() -> void:
	var attack := Sequence.new()
	attack.request("punch", false)
	attack.request("kick", false)
	attack.interrupt()
	attack.advance(0.8, false)
	assert_eq(attack.serial, 1)
	assert_eq(attack.elapsed, -1.0)
	attack.request("punch", false)
	assert_eq(attack.side, "near")
