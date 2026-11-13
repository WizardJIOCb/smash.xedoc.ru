extends "res://tools/district_route_review.gd"
## Full route through real input. Alley relay waits for an actual upper landing.

var upper_landed: bool = false
var upper_landing_at: float = -1.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if room_index == 1 and not moose.airborne and is_equal_approx(floor_y, 415):
		if not upper_landed:
			upper_landing_at = elapsed_run
			Metrics.record("review_upper_ledge_landed")
		upper_landed = true
	Metrics.rig["upper_ledge_landed"] = upper_landed
	Metrics.rig["upper_ledge_landing_at"] = upper_landing_at


func _interact() -> void:
	if room_index == 1 and not upper_landed:
		return
	super._interact()
