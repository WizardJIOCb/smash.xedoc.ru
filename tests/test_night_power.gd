extends GutTest

const Power = preload("res://scripts/core/night_power.gd")
const Contact = preload("res://scripts/core/combat_contact.gd")


func test_activation_expires_and_cannot_refresh_or_farm_charge_while_active() -> void:
	var power := Power.new()
	assert_true(power.activate())
	assert_false(power.activate())
	power.gain(500)
	assert_eq(power.charge, 0.0)
	power.advance(7.9)
	assert_true(power.active())
	power.advance(0.2)
	assert_false(power.active())
	assert_false(power.activate())
	power.gain(120)
	assert_eq(power.charge, 100.0)
	assert_true(power.activate())


func test_impulse_fires_once_even_when_frame_crosses_entire_animation() -> void:
	var power := Power.new()
	power.activate()
	assert_true(power.try_burst())
	assert_false(power.try_burst())
	assert_false(power.advance(0.1))
	assert_true(power.advance(0.8))
	assert_false(power.advance(0.2))
	assert_eq(power.bursts, 1)
	assert_false(power.try_burst())
	power.advance(1.0)
	assert_true(power.try_burst())
	power.cancel()
	assert_false(power.advance(1.0))
	assert_eq(power.pose(), Vector2.ZERO)


func test_expiry_cancels_impulse_before_windup_finishes() -> void:
	var power := Power.new()
	power.activate()
	power.advance(7.9)
	power.try_burst()
	assert_false(power.advance(0.5))
	assert_eq(power.bursts, 0)
	assert_eq(power.burst_time, -1.0)


func test_interleaved_impulse_does_not_allow_same_swing_to_damage_twice() -> void:
	var contact := Contact.new()
	assert_true(contact.accept(21))
	assert_true(contact.accept(-1001))
	assert_false(contact.accept(21))
	assert_false(contact.accept(-1001))
	assert_true(contact.accept(22))
