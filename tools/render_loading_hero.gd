extends SceneTree
## Export the actual animated rig, preserving its layered art and transparent alpha.


func _initialize() -> void:
	root.unfocusable = true
	call_deferred("_render")


func _render() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 768)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var mount := Node2D.new()
	mount.position = Vector2(256, 722)
	mount.scale = Vector2.ONE * 2.25
	viewport.add_child(mount)
	var hero := Node2D.new()
	hero.set_script(load("res://scripts/actors/moose_rig.gd"))
	mount.add_child(hero)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var output := "res://art/branding/loading-moose-v1.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/branding"))
	var error := viewport.get_texture().get_image().save_png(output)
	print("Loading hero render: ", error)
	quit(error)
