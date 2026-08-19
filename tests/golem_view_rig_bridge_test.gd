extends SceneTree

var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GOLEM VIEW BRIDGE FAIL: %s" % message)

func run_test() -> void:
	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	check(packed != null, "expedition scene loads with rig bridge")
	if packed == null:
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	var container := scene.get_node("Margin/RootColumn/MainSplit/GolemPanel/GolemView/GolemRigViewport") as SubViewportContainer
	var viewport := container.get_node("SubViewport") as SubViewport
	var rig_camera := viewport.get_node("RigCamera") as Camera2D
	check(container.stretch, "rig viewport container stretches to GolemView")
	check(viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "rig viewport updates every frame")
	check(viewport.size.x > 0 and viewport.size.y > 0, "rig viewport has nonzero render size after container fit")
	check(rig_camera.position.is_equal_approx(Vector2(826, 1841)), "camera centers existing rig world coordinates")
	check(rig_camera.zoom.is_equal_approx(Vector2(0.5, 0.5)), "camera uses display-only zoom")
	check(viewport.get_node("Golem01ArticulationV0") is Golem01ArticulationV0, "rig is viewport child without coordinate edits")
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("GOLEM VIEW RIG BRIDGE: PASS (SubViewport UPDATE_ALWAYS)")
		quit(0)
	else:
		print("GOLEM VIEW RIG BRIDGE: FAIL (%d checks)" % failures.size())
		quit(1)
