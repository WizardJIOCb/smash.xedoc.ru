extends RefCounted
## Two native arm bones, with a chosen elbow bend and a level hand axis.


static func solve(
	bones: Dictionary, side: String, target: Vector2, bend: float, hand_angle: float
) -> void:
	var arm: Bone2D = bones[side + "_arm"]
	var fore: Bone2D = bones[side + "_fore"]
	var hand: Bone2D = bones[side + "_hand"]
	var vector := target - arm.position
	var upper: float = arm.length
	var lower: float = fore.length
	var distance := clampf(vector.length(), absf(upper - lower) + 0.01, upper + lower - 0.01)
	arm.rotation = (
		atan2(-vector.x, vector.y)
		- (
			bend
			* acos(
				clampf(
					(distance * distance + upper * upper - lower * lower) / (2 * upper * distance),
					-1,
					1
				)
			)
		)
	)
	fore.rotation = (
		bend
		* (
			PI
			- acos(
				clampf(
					(upper * upper + lower * lower - distance * distance) / (2 * upper * lower),
					-1,
					1
				)
			)
		)
	)
	hand.rotation = hand_angle - bones.body.rotation - arm.rotation - fore.rotation
