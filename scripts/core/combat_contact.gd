extends RefCounted
## One attack may touch each target once, even across multiple active frames.

var recent_serials: Array[int] = []


func accept(serial: int) -> bool:
	if serial in recent_serials:
		return false
	recent_serials.append(serial)
	if recent_serials.size() > 32:
		recent_serials.pop_front()
	return true


static func damage(kind: String, step: int, airborne: bool, tuning: Dictionary) -> int:
	var amount: int = tuning.punch_damage
	if kind == "kick":
		amount = int(tuning.kick_damage[clampi(step, 0, 2)])
	return amount + (5 if airborne else 0)


static func separate(
	previous_x: float, current_x: float, obstacle_x: float, gap: float = 72.0
) -> float:
	var side := signf(previous_x - obstacle_x)
	if side == 0:
		side = -1
	var limit := obstacle_x + side * gap
	return maxf(current_x, limit) if side > 0 else minf(current_x, limit)
