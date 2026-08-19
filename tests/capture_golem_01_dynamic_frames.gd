extends SceneTree

const OUTPUT_DIR := "res://tests/visual_log/golem_01_dyn_01"

var poses := [
	{"name": "neutral", "hip": 0.0, "knee": 0.0},
	{"name": "hip_forward_45", "hip": 45.0, "knee": 0.0},
	{"name": "hip_back_20", "hip": -20.0, "knee": 0.0},
	{"name": "knee_partial_30", "hip": 0.0, "knee": -30.0},
	{"name": "knee_deep_90", "hip": 0.0, "knee": -90.0},
	{"name": "composite_hip45_knee90", "hip": 45.0, "knee": -90.0},
]

func _init() -> void:
	call_deferred("capture_all")

func capture_all() -> void:
	var version := Engine.get_version_info()
	if version.get("major") != 4 or version.get("minor") != 7 or version.get("patch") != 1 or version.get("status") != "stable":
		push_error("GOLEM-01 CAPTURE: Godot 4.7.1 stable is required")
		quit(1)
		return
	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	var rig := scene.get_node("Margin/RootColumn/MainSplit/GolemPanel/GolemView/GolemRigViewport/SubViewport/Golem01ArticulationV0") as Golem01ArticulationV0
	for pose in poses:
		rig.set_left_hip_rotation(deg_to_rad(float(pose.hip)))
		rig.set_left_knee_rotation(deg_to_rad(float(pose.knee)))
		await process_frame
		await process_frame
		var image := root.get_texture().get_image()
		var output_path := "%s/%s_1280x720.png" % [OUTPUT_DIR, pose.name]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		var result := image.save_png(ProjectSettings.globalize_path(output_path))
		if result != OK:
			push_error("GOLEM-01 CAPTURE: failed %s (%s)" % [pose.name, result])
			quit(1)
			return
		print("GOLEM-01 FRAME SAVED: %s" % output_path)
	quit(0)
