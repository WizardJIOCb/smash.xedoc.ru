extends GutTest

const Moose = preload("res://scripts/actors/moose_rig.gd")


func test_camera_side_limbs_keep_render_priority_in_both_directions() -> void:
	var rig := Moose.new()
	add_child_autofree(rig)
	await get_tree().process_frame
	var hand: Sprite2D = rig.bones.near_hand.get_node("fist_back")
	var far_hand: Sprite2D = rig.bones.far_hand.get_node("fist")
	var head: Sprite2D = rig.bones.head.get_node("head")
	for direction: float in [-1.0, 1.0]:
		rig.facing = direction
		await get_tree().process_frame
		assert_gt(hand.z_index, head.z_index, "Near fist must pass in front of the head")
		assert_gt(rig.leg_meshes.near.z_index, rig.leg_meshes.far.z_index)
		assert_lt(rig.bones.near_thigh.position.x, rig.bones.far_thigh.position.x)
	assert_ne(hand.texture.resource_path, far_hand.texture.resource_path)
	var far_shoe: Sprite2D = rig.bones.far_foot.get_node("shoe")
	assert_gt(rig.leg_meshes.far.z_index, far_shoe.z_index, "Far cuff covers its shoe collar")


func test_continuous_trousers_resolve_all_skin_bones_with_normalized_weights() -> void:
	var rig := Moose.new()
	add_child_autofree(rig)
	await get_tree().process_frame
	for leg: Polygon2D in rig.leg_meshes.values():
		var totals := PackedFloat32Array()
		totals.resize(leg.polygon.size())
		for bone_index in range(leg.get_bone_count()):
			assert_true(rig.skeleton.has_node(leg.get_bone_path(bone_index)))
			var weights := leg.get_bone_weights(bone_index)
			for vertex in range(totals.size()):
				totals[vertex] += weights[vertex]
		var max_error := 0.0
		for total in totals:
			max_error = maxf(max_error, absf(total - 1.0))
		assert_lt(max_error, 0.0001, "No unbound waist or knee vertices")
