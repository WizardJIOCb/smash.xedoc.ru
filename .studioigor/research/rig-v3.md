# Rig correction v3 — 2026-11-13

- User screenshots identify shoulder perspective/layers, wrist pivot, empty neckline and pelvis silhouette. A second request sets forward gaze as default and keeps rare camera glances.
- Existing native Skeleton2D and Polygon2D pipeline remains. Artistic edits use built-in image_gen; deterministic cropping/fitting only in preparation script.
- Explicit z layers separate far/near limbs; pelvis now covers thigh caps. Near shoulder belongs on the visible side of the three-quarter torso.
- Wrist-to-knuckle artwork axis is aligned to the forearm bone, with no arbitrary animated wrist twist. Original atlas fist cell contained a disconnected tuft: crop the fist component without changing pixels.
- Neckline cavity in the source torso was opaque, so a neck behind it could not fill the hole. Edit the actual jacket art to include fur in the cavity, and bridge to the head with a separate neck.
- [Godot CanvasItem shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html): pass vertex COLOR through a varying to avoid multiplying the head texture twice; eye shader uses original alpha and modulate.
- [Godot Window](https://docs.godotengine.org/en/stable/classes/class_window.html): local capture harness sets root.unfocusable=true to keep automated native capture from receiving live keyboard input intended for the browser. No skill source modified.
