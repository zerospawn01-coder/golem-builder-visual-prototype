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
	assembly.queue_free()
	await process_frame
	if failures.is_empty():
		print("GOLEM-01-ASSEMBLY V0: PASS (single canonical pelvis, lower pivot chain retained)")
		quit(0)
	else:
		print("GOLEM-01-ASSEMBLY V0: FAIL (%d checks)" % failures.size())
		quit(1)
