extends SceneTree

const OUTPUT_DIR := "res://tests/visual_log/golem_01_assembly"

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var version := Engine.get_version_info()
	if version.get("major") != 4 or version.get("minor") != 7 or version.get("patch") != 1 or version.get("status") != "stable":
		push_error("ASSEMBLY CAPTURE: Godot 4.7.1 stable is required")
		quit(1)
		return
	var packed := load("res://scenes/golem/golem_01_assembly_v0.tscn") as PackedScene
	for spec in [{"name":"neutral_pc", "size":Vector2i(1280,720)}, {"name":"neutral_mobile", "size":Vector2i(720,1280)}]:
		var viewport := SubViewport.new()
		viewport.size = spec.size
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.transparent_bg = true
		root.add_child(viewport)
		var assembly := packed.instantiate()
		viewport.add_child(assembly)
		var camera := Camera2D.new()
		camera.position = Vector2(826, 1500)
		camera.zoom = Vector2(0.3, 0.3)
		viewport.add_child(camera)
		camera.enabled = true
		await process_frame
		await process_frame
		var image := viewport.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		var path := "%s/%s.png" % [OUTPUT_DIR, spec.name]
		image.save_png(ProjectSettings.globalize_path(path))
		print("ASSEMBLY FRAME SAVED: %s (%dx%d)" % [path, image.get_width(), image.get_height()])
		viewport.queue_free()
		await process_frame
	quit(0)
