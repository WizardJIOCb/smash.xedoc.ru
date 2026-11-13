extends "res://scripts/world/district_run.gd"
## Capture-only observer. Scheduled controls exercise independent T/Q/O inputs.

var review_time: float = 0.0
var snapshot_wait: float = 0.0
var snapshots: Array = []
var observed: Dictionary = {
	"night_without_power": false,
	"day_with_power": false,
	"night_after_expiry": false,
	"switch_with_empty_charge": false
}


func _ready() -> void:
	super._ready()
	front.start_requested.emit.call_deferred()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	review_time += delta
	snapshot_wait -= delta
	if world_night and not night.active() and night.charge == 100:
		observed.night_without_power = true
	if not world_night and night.active():
		observed.day_with_power = true
	if world_night and not night.active() and night.casts > 0:
		observed.night_after_expiry = true
	if time_switches >= 7 and night.charge == 0 and not night.active():
		observed.switch_with_empty_charge = true
	if snapshot_wait <= 0:
		snapshot_wait = 0.5
		snapshots.append(
			{
				"t": review_time,
				"world_night": world_night,
				"power": night.active(),
				"charge": night.charge,
				"remaining": night.remaining,
				"scale": moose.power_scale,
				"switches": time_switches,
				"bursts": night.bursts
			}
		)
	Metrics.rig["independence_review"] = {"observed": observed, "snapshots": snapshots}
