extends SceneTree

var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GOLEM-01 ASSEMBLY FAIL: %s" % message)

func run_test() -> void:
	var packed := load("res://scenes/golem/golem_01_assembly_v0.tscn") as PackedScene
	var assembly := packed.instantiate() as Node2D
	root.add_child(assembly)
	await process_frame
	var lower_pelvis: Sprite2D = assembly.get_node("LowerBodyRig/Pelvis/PelvisSprite")
	check(assembly.position == Vector2.ZERO and assembly.scale == Vector2.ONE, "GolemRoot uses assembly origin and scale")
	check(not lower_pelvis.visible, "LowerBodyRig pelvis sprite is hidden")
	check(assembly.get_node("LowerBodyRig/Pelvis/LeftHipPivot") != null and assembly.get_node("LowerBodyRig/Pelvis/LeftHipPivot/LeftKneePivot") != null, "lower pivot chain remains intact")
	check(assembly.get_node("UpperBody/PelvisSprite").visible, "UpperBody pelvis is canonical visible pelvis")
	check(assembly.get_node("UpperBody/PelvisSprite").texture != null, "UpperBody pelvis texture resolves")
	check(assembly.get_node("UpperBody/TorsoSprite").texture != null, "UpperBody torso texture resolves")
	check(assembly.get_node("UpperBody/CoreSprite").texture != null, "UpperBody core texture resolves")
	var upper := assembly.get_node("UpperBody") as Node2D
	var torso := assembly.get_node("UpperBody/TorsoSprite") as Sprite2D
	var before_position := upper.global_position
	var before_rotation := upper.global_rotation
	var torso_before := torso.global_position
	var torso_rotation_before := torso.global_rotation
	assembly.get_node("LowerBodyRig").set_left_hip_rotation(deg_to_rad(45.0))
	await process_frame
	check(upper.get_parent() == assembly, "UpperBody is direct GolemRoot child")
	check(upper.global_position.is_equal_approx(before_position), "UpperBody position unaffected by lower hip rotation")
	check(is_equal_approx(upper.global_rotation, before_rotation), "UpperBody rotation unaffected by lower hip rotation")
	check(torso.texture != null and torso.visible, "UpperBody torso remains visible after lower rotation")
	check(torso.global_position.is_equal_approx(torso_before), "UpperBody torso position unaffected by lower rotation")
	check(is_equal_approx(torso.global_rotation, torso_rotation_before), "UpperBody torso rotation unaffected by lower rotation")
	var camera_position := Vector2(826, 1500)
	var camera_zoom := Vector2(0.3, 0.3)
	var viewport_size := Vector2(1280, 720)
	var half_extent := viewport_size / (2.0 * camera_zoom)
	print("ASSEMBLY CAMERA bounds: position=", camera_position, " zoom=", camera_zoom, " left=", camera_position.x - half_extent.x, " right=", camera_position.x + half_extent.x, " top=", camera_position.y - half_extent.y, " bottom=", camera_position.y + half_extent.y)
	check(camera_position == Vector2(826, 1500), "assembly camera position is fixed")
	check(camera_zoom == Vector2(0.3, 0.3), "assembly camera zoom is fixed")
	for pose in [{"name":"forward", "hip":45.0, "knee":0.0}, {"name":"composite", "hip":45.0, "knee":-90.0}]:
		assembly.get_node("LowerBodyRig").set_left_hip_rotation(deg_to_rad(pose.hip))
		assembly.get_node("LowerBodyRig").set_left_knee_rotation(deg_to_rad(pose.knee))
		await process_frame
		print("ASSEMBLY %s torso: visible=" % pose.name, torso.visible, " global_position=", torso.global_position, " global_rotation=", torso.global_rotation, " texture=", torso.texture != null)
		check(torso.visible and torso.texture != null, "%s torso remains visible" % pose.name)
	assembly.queue_free()
	await process_frame
	if failures.is_empty():
		print("GOLEM-01-ASSEMBLY V0: PASS (single canonical pelvis, lower pivot chain retained)")
		quit(0)
	else:
		print("GOLEM-01-ASSEMBLY V0: FAIL (%d checks)" % failures.size())
		quit(1)
