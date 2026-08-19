extends SceneTree

const OUTPUT_PATH := "res://tests/visual_log/golem_01_dyn_01/mobile_720x1280.png"

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	var version := Engine.get_version_info()
	if version.get("major") != 4 or version.get("minor") != 7 or version.get("patch") != 1 or version.get("status") != "stable":
		push_error("GOLEM-01 MOBILE: Godot 4.7.1 stable is required")
		quit(1)
		return
	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	root.size = Vector2i(720, 1280)
	await process_frame
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_log/golem_01_dyn_01"))
	var result := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if result != OK:
		push_error("GOLEM-01 MOBILE: failed to save frame (%s)" % result)
		quit(1)
		return
	print("GOLEM-01 MOBILE FRAME: SAVED %s (%dx%d)" % [OUTPUT_PATH, image.get_width(), image.get_height()])
	quit(0)
