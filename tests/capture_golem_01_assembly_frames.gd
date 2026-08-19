extends SceneTree

const OUTPUT_DIR := "res://tests/visual_log/golem_01_assembly"
const POSES := [
	{"name":"neutral", "hip":0.0, "knee":0.0},
	{"name":"hip_forward_45", "hip":45.0, "knee":0.0},
	{"name":"hip_back_20", "hip":-20.0, "knee":0.0},
	{"name":"knee_partial_30", "hip":0.0, "knee":-30.0},
	{"name":"knee_deep_90", "hip":0.0, "knee":-90.0},
	{"name":"composite_hip45_knee90", "hip":45.0, "knee":-90.0},
]

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var version := Engine.get_version_info()
	if version.get("major") != 4 or version.get("minor") != 7 or version.get("patch") != 1 or version.get("status") != "stable":
		push_error("ASSEMBLY CAPTURE: Godot 4.7.1 stable is required")
		quit(1)
		return
	var packed := load("res://scenes/golem/golem_01_assembly_v0.tscn") as PackedScene
	for spec in [{"name":"assembly_pc", "size":Vector2i(1280,720)}]:
		for pose in POSES:
			var viewport := SubViewport.new()
			viewport.size = spec.size
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
			viewport.transparent_bg = true
			root.add_child(viewport)
			var assembly := packed.instantiate()
			viewport.add_child(assembly)
			var rig := assembly.get_node("LowerBodyRig") as Golem01ArticulationV0
			var camera := Camera2D.new()
			camera.position = Vector2(826, 1500)
			camera.zoom = Vector2(0.3, 0.3)
			viewport.add_child(camera)
			camera.enabled = true
			rig.set_left_hip_rotation(deg_to_rad(float(pose.hip)))
			rig.set_left_knee_rotation(deg_to_rad(float(pose.knee)))
			await process_frame
			await process_frame
			await process_frame
			var image := viewport.get_texture().get_image()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
			var path := "%s/%s_%s.png" % [OUTPUT_DIR, spec.name, pose.name]
			image.save_png(ProjectSettings.globalize_path(path))
			print("ASSEMBLY FRAME SAVED: %s (%dx%d)" % [path, image.get_width(), image.get_height()])
			viewport.queue_free()
			await process_frame
	quit(0)
