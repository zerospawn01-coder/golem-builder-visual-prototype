extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("run_test")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("NORTH STAR FAIL: %s" % message)


func run_test() -> void:
	var packed := load("res://scenes/integration/north_star_integration_v0.tscn") as PackedScene
	check(packed != null, "integration scene loads")
	if packed == null:
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	check(_screen(scene) == &"WORKSHOP", "cycle starts in workshop")
	await create_timer(0.35).timeout
	check(scene.get_node("ExpeditionScene/Margin/RootColumn/TelemetryRow/StatusValue").text == "LINKING", "hidden expedition waits for deploy")
	_press(scene, "ShellPanel/Content/Actions/PrimaryAction")
	await process_frame
	check(_screen(scene) == &"BLUEPRINT", "workshop opens blueprint presentation")
	_press(scene, "ShellPanel/Content/Actions/PrimaryAction")
	await process_frame
	check(_screen(scene) == &"FABRICATION_CONFIRMED", "host fabrication result is presented")
	_press(scene, "ShellPanel/Content/Actions/PrimaryAction")
	await process_frame
	check(_screen(scene) == &"EXPEDITION", "confirmed unit enters existing expedition view")
	var saw_hazard := false
	var saw_decision := false
	for index in range(80):
		await create_timer(0.02).timeout
		saw_hazard = saw_hazard or scene.get_node("ExpeditionScene/Margin/RootColumn/HazardPanel").visible
		saw_decision = saw_decision or scene.get_node("ExpeditionScene/Margin/RootColumn/DecisionUI").visible
	check(saw_hazard, "integrated expedition presents hazard")
	check(saw_decision, "integrated expedition reaches return decision")
	(scene.get_node("ExpeditionScene/Margin/RootColumn/DecisionUI/Return") as Button).pressed.emit()
	await process_frame
	check(_screen(scene) == &"RESULT", "return presents host result")
	check((scene.presenter.current_state().blueprint["saved_blueprints"] as Array).size() == 1, "blueprint presentation survives expedition")
	_press(scene, "ShellPanel/Content/Actions/PrimaryAction")
	await process_frame
	check(_screen(scene) == &"WORKSHOP", "result returns to workshop")
	check(scene.get_node("ShellPanel/Content/StateSummary").text.contains("retained: 1"), "workshop displays retained blueprint state")
	_press(scene, "ShellPanel/Content/Actions/PrimaryAction")
	await process_frame
	check(_screen(scene) == &"BLUEPRINT", "returned player can reopen blueprint library")
	check((scene.presenter.current_state().blueprint["saved_blueprints"] as Array).size() == 1, "saved blueprint is available for reuse")
	var shell_source := FileAccess.get_file_as_string("res://scripts/integration/north_star_integration_shell.gd")
	check(not shell_source.contains("ExpeditionTelemetry"), "integration shell does not read telemetry")
	check(not shell_source.contains("fabricateGolem"), "integration shell does not own canonical fabrication")
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("NORTH_STAR_INTEGRATION_V0: PASS")
		quit(0)
	else:
		print("NORTH_STAR_INTEGRATION_V0: FAIL (%d checks)" % failures.size())
		quit(1)


func _screen(scene: Node) -> StringName:
	return scene.presenter.current_state().screen


func _press(scene: Node, path: String) -> void:
	(scene.get_node(path) as Button).pressed.emit()
