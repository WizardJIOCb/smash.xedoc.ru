extends GutTest

const Run = preload("res://scripts/world/district_run.gd")


func test_successive_damage_preserves_facing_and_restart_cannot_reuse_dead_pose() -> void:
	var run := Run.new()
	add_child_autofree(run)
	await get_tree().process_frame
	run._start_new_run()
	run.moose.facing = 1
	var source := run.moose.position + Vector2(100, 0)
	run._hurt_player(20, source)
	run._hurt_player(20, source)
	assert_eq(run.health, 60, "Distinct hits are no longer ignored during a grace period")
	for frame in range(10):
		await get_tree().physics_frame
	assert_eq(run.moose.facing, 1.0, "Knockback alone cannot turn the hero")
	assert_eq(run.moose.modulate.a, 1.0, "Receiving damage does not blink the hero")
	run._hurt_player(100, source)
	for frame in range(100):
		await get_tree().physics_frame
	assert_true(run.moose.ragdoll_active)
	var corpse := run.player_corpse
	run._restart()
	assert_false(corpse.is_processing(), "Deferred deletion cannot overwrite reset bones")
	for frame in range(8):
		await get_tree().process_frame
	assert_false(run.moose.ragdoll_active)
	assert_eq(run.health, 100)
	assert_almost_eq(run.moose.bones.hips.rotation, 0.0, 0.001)
	assert_eq(run.moose.skeleton.modulate.a, 1.0)
