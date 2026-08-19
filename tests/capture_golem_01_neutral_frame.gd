extends SceneTree

const OUTPUT_DIR := "res://tests/visual_log/golem_01_dyn_01"
const OUTPUT_PATH := OUTPUT_DIR + "/neutral_1280x720.png"


func _init() -> void:
	call_deferred("capture")


func capture() -> void:
	var version := Engine.get_version_info()
	if version.get("major") != 4 or version.get("minor") != 7 or version.get("patch") != 1 or version.get("status") != "stable":
		push_error("GOLEM-01 CAPTURE: Godot 4.7.1 stable is required")
		quit(1)
		return
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		push_error("GOLEM-01 CAPTURE: Compatibility renderer is required")
		quit(1)
		return
	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	if packed == null:
		push_error("GOLEM-01 CAPTURE: ExpeditionScene did not load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("GOLEM-01 CAPTURE: framebuffer image is empty")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var result := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if result != OK:
		push_error("GOLEM-01 CAPTURE: failed to save neutral frame (%s)" % result)
		quit(1)
		return
	print("GOLEM-01 NEUTRAL FRAME: SAVED %s (%dx%d)" % [OUTPUT_PATH, image.get_width(), image.get_height()])
	quit(0)
