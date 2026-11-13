extends RefCounted
## One attack may touch each target once, even across multiple active frames.

var last_serial: int = -1


func accept(serial: int) -> bool:
	if serial == last_serial:
		return false
	last_serial = serial
	return true


static func damage(kind: String, step: int, airborne: bool, tuning: Dictionary) -> int:
	var amount: int = tuning.punch_damage
	if kind == "kick":
		amount = int(tuning.kick_damage[clampi(step, 0, 2)])
	return amount + (5 if airborne else 0)
