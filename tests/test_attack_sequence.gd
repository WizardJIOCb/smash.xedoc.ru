extends GutTest

const Sequence = preload("res://scripts/core/attack_sequence.gd")


func test_buffered_punches_alternate_and_finish_without_extra_input() -> void:
	var attack := Sequence.new()
	attack.request("punch", false)
	for expected: String in ["far", "near", "far"]:
		attack.advance(0.10, false)
		attack.request("punch", false)
		attack.advance(0.20, false)
		assert_eq(attack.side, expected)
	assert_eq(attack.history, ["punch:near", "punch:far", "punch:near", "punch:far"])
	attack.advance(0.5, false)
	assert_eq(attack.elapsed, -1.0)
	assert_eq(attack.serial, 4, "Recovery never starts an attack without a tap")


func test_mashing_buffers_one_attack_and_chooses_air_state_when_consumed() -> void:
	var attack := Sequence.new()
	attack.request("punch", false)
	for tap in range(10):
		attack.request("punch", false)
	attack.advance(0.27, true)
	assert_eq(attack.serial, 2)
	assert_true(attack.in_air)
	assert_eq(attack.counts.air_punch, 1)
	attack.advance(0.5, false)
	assert_eq(attack.serial, 2)


func test_kicks_mix_with_punches_and_idle_resets_the_sequence() -> void:
	var attack := Sequence.new()
	attack.request("kick", true)
	attack.advance(0.30, true)
	attack.request("punch", true)
	attack.advance(0.15, false)
	assert_eq(attack.kind, "punch")
	assert_false(attack.in_air, "A buffered landing follow-up uses a grounded pose")
	assert_eq(attack.counts.air_kick, 1)
	attack.advance(0.5, false)
	attack.advance(0.7, false)
	attack.request("punch", false)
	assert_eq(attack.side, "near")
	assert_eq(attack.chain_length, 1)


func test_crouching_preserves_alternation_and_air_attacks_take_priority() -> void:
	var attack := Sequence.new()
	attack.request("punch", false, true)
	assert_true(attack.low)
	attack.advance(0.1, false, true)
	attack.request("punch", false, true)
	attack.advance(0.18, false, true)
	assert_eq(attack.history, ["crouch_punch:near", "crouch_punch:far"])
	assert_eq(attack.counts.crouch_punch, 2)
	attack.advance(0.5, false, true)
	attack.request("kick", false, true)
	assert_eq(attack.counts.crouch_kick, 1)
	attack.advance(0.6, false, true)
	attack.request("kick", true, true)
	assert_true(attack.in_air)
	assert_false(attack.low, "Holding down in flight must use the airborne pose")


func test_kick_combo_changes_leg_and_cycles_through_three_timings() -> void:
	var attack := Sequence.new()
	attack.request("kick", false)
	assert_eq(attack.side, "near")
	attack.advance(0.3, false)
	attack.request("kick", false)
	attack.advance(0.18, false)
	assert_eq(attack.side, "far")
	assert_eq(attack.kick_step, 1)
	assert_lt(float(attack.timings().duration), 0.5)
	attack.advance(0.15, false)
	attack.request("kick", false)
	attack.advance(0.21, false)
	assert_eq(attack.side, "near")
	assert_eq(attack.kick_step, 2)
	assert_gt(float(attack.timings().duration), 0.6)
	attack.advance(0.7, false)
	attack.request("kick", false)
	assert_eq(attack.kick_step, 0)
	assert_eq(attack.side, "far", "The next cycle must keep alternating legs")
