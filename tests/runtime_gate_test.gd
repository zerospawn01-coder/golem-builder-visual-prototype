extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("run_gate")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GATE FAIL: %s" % message)


func run_gate() -> void:
	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	check(packed != null, "expedition_scene.tscn loads")
	if packed == null:
		quit(1)
		return

	var scene := packed.instantiate()
	var source := scene.get_node("MockTelemetrySource") as MockTelemetrySource
	source.interval_seconds = 0.05
	root.add_child(scene)

	var saw_hazard := false
	var saw_decision := false
	for index in range(50):
		await create_timer(0.02).timeout
		saw_hazard = saw_hazard or scene.get_node("%HazardPanel").visible
		saw_decision = saw_decision or scene.get_node("%DecisionUI").visible

	check(scene.get_node("%StatusValue").text == "DECISION", "status reaches DECISION without stale rewind")
	check(scene.get_node("%DepthValue").text == "2", "DEPTH updates")
	check(scene.get_node("%DurabilityValue").text == "73%", "DURABILITY updates")
	check(scene.get_node("%CargoValue").text == "4 / 8", "CARGO updates")
	var log_text: String = scene.get_node("%DiagnosticLog").get_parsed_text()
	check(log_text.contains("CARGO_SECURED"), "transient cargo event is logged independently")
	check(log_text.contains("sequence=3 (stale sequence)"), "stale sequence rejection is visible")
	check(not log_text.contains("Delayed cargo event"), "rejected payload does not append its events")
	check(saw_hazard, "HAZARD warning becomes visible")
	check(saw_decision, "CONTINUE / RETURN becomes visible")

	var status_before_resize: String = scene.get_node("%StatusValue").text
	var log_before_resize: String = scene.get_node("%DiagnosticLog").get_parsed_text()
	scene.apply_responsive_layout_for_width(600.0)
	await process_frame
	check(scene.get_node("%Title").text == "GBE / EXPEDITION", "mobile layout activates")
	check(scene.get_node("%StatusValue").text == status_before_resize, "responsive switch preserves presentation state")
	check(scene.get_node("%DiagnosticLog").get_parsed_text() == log_before_resize, "responsive switch does not replay transient events")
	scene.apply_responsive_layout_for_width(1280.0)
	await process_frame
	check(scene.get_node("%Title").text.begins_with("GOLEM BUILDER"), "PC layout reactivates")
	check(scene.get_node("%StatusValue").text == status_before_resize, "PC switch preserves presentation state")
	check(scene.get_node("%DiagnosticLog").get_parsed_text() == log_before_resize, "PC switch does not replay transient events")
	scene.queue_free()
	await process_frame

	if failures.is_empty():
		print("V0-RUNTIME: PASS")
		quit(0)
	else:
		print("V0-RUNTIME: FAIL (%d checks)" % failures.size())
		quit(1)
