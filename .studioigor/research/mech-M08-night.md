# M08 — Багровая ночь, 2026-11-14

User requested a timed night ultimate, red aura, slight growth and stronger attacks.
T activates for 8 s from a full charge; L releases a telegraphed radial impulse.
Charge comes from damaging hits and defeats, never shield blocks or active-night hits.
Pause freezes gameplay timers. Room changes preserve charge and active time.
Death and new runs reset the mode. Quarantine relays remain independent.

Sources checked: official Godot CanvasItem shader reference, 2D lights/shadows,
data paths and ConfigFile documentation:
- https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html
- https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html
- https://docs.godotengine.org/en/4.4/classes/class_configfile.html

Use an additive procedural aura and screen-reading night grade below HUD/menu.
Store explicit sound preference in user://; fresh installs start muted.
Keep native Skeleton2D animation and scale foot anchors with the growth factor.
