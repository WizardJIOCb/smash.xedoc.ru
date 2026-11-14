extends "res://tools/campaign_route_review.gd"
## Native audiovisual capture; combat and route use the existing normal-input driver.


func _ready() -> void:
	get_viewport().unfocusable = true
	super._ready()
	# Disposable review only: do not persist a change to the player's sound preference.
	audio.muted = false
