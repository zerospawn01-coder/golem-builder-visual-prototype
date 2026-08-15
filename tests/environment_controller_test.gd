extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("run_gate")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("V3 GATE FAIL: %s" % message)


func run_gate() -> void:
	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	check(packed != null, "expedition scene loads")
	if packed == null:
		quit(1)
		return
	var scene := packed.instantiate()
	var source := scene.get_node("MockTelemetrySource") as MockTelemetrySource
	source.interval_seconds = 10.0
	root.add_child(scene)
	await process_frame

	var presenter := scene.get_node("ExpeditionPresenter") as ExpeditionPresenter
	var environment := scene.get_node("%EnvironmentController") as EnvironmentController
	var view := scene.get_node("%EnvironmentView") as EnvironmentView
	var motion := scene.get_node("%MotionController") as MotionController

	var controller_source := FileAccess.get_file_as_string("res://scripts/environment/environment_controller.gd")
	var view_source := FileAccess.get_file_as_string("res://scripts/views/environment_view.gd")
	check(not controller_source.contains("ExpeditionTelemetry"), "EnvironmentController does not reference telemetry")
	check(not controller_source.contains("GolemView"), "EnvironmentController does not reference GolemView")
	check(not view_source.contains("ExpeditionTelemetry"), "EnvironmentView does not reference telemetry")
	check(not view_source.contains("GolemView"), "EnvironmentView does not reference GolemView")

	var sequence := 20
	for status in ["IDLE", "WALKING", "HARVESTING", "HAZARD", "DECISION"]:
		check(presenter.accept(_payload(sequence, status, 1)), "%s accepted" % status)
		check(environment.activity == EnvironmentController.STATUS_TO_ACTIVITY[status], "%s activity mapping is deterministic" % status)
		sequence += 1

	check(presenter.accept(_payload(30, "WALKING", 2)), "traversal accepted")
	var background_before := view.background_offset
	var midground_before := view.midground_offset
	var foreground_before := view.foreground_offset
	await create_timer(0.2).timeout
	var background_delta := view.background_offset - background_before
	var midground_delta := view.midground_offset - midground_before
	var foreground_delta := view.foreground_offset - foreground_before
	check(background_delta > 0.0, "background scrolls during traversal")
	check(is_equal_approx(midground_delta / background_delta, 2.2), "midground ratio is independent")
	check(is_equal_approx(foreground_delta / background_delta, 4.0), "foreground ratio is independent")

	check(presenter.accept(_payload(31, "HARVESTING", 3)), "non-traversal accepted")
	var stopped_offset := view.foreground_offset
	await create_timer(0.15).timeout
	check(is_equal_approx(view.foreground_offset, stopped_offset), "non-traversal stops scrolling")
	check(is_equal_approx(view.visual_intensity, 0.24), "depth affects visual intensity only")

	var one_shots_before := motion.one_shot_play_count
	check(presenter.accept(_payload(32, "WALKING", 3, [{"type": "MASS_LOAD", "severity": 2}])), "hazard presentation accepted")
	check(environment.hazard_active and view.hazard_strength == 1.0, "hazards activate environment overlay")
	check(motion.one_shot_play_count == one_shots_before, "environment hazard does not trigger Golem one-shot")
	var revision_before_stale := environment.state_revision
	check(not presenter.accept(_payload(29, "IDLE", 1)), "stale telemetry rejected")
	check(environment.depth == 3 and environment.hazard_active, "stale telemetry does not rewind environment")
	check(environment.state_revision == revision_before_stale, "stale telemetry does not regenerate environment state")

	var revision_before_layout := environment.state_revision
	scene.apply_responsive_layout_for_width(600.0)
	scene.apply_responsive_layout_for_width(1280.0)
	await process_frame
	check(environment.state_revision == revision_before_layout, "responsive switch does not regenerate environment state")
	check(presenter.replay_current_state(), "persistent state replay succeeds")
	await process_frame
	check(environment.state_revision == revision_before_layout, "identical rebind does not regenerate environment state")

	check(presenter.accept(_payload(33, "WALKING", 3, [], [{"type": "WARNING", "message": "Impact."}])), "Golem one-shot accepted")
	check(motion.active_one_shot == &"hazard_reaction", "Golem reaction starts")
	check(environment.activity == &"TRAVERSAL" and not environment.hazard_active, "environment remains independently state-driven")

	environment.set_process(false)
	_reset_offsets(view)
	for step in range(30):
		environment.advance(1.0 / 30.0)
	var offsets_at_30_steps := Vector3(view.background_offset, view.midground_offset, view.foreground_offset)
	_reset_offsets(view)
	for step in range(60):
		environment.advance(1.0 / 60.0)
	var offsets_at_60_steps := Vector3(view.background_offset, view.midground_offset, view.foreground_offset)
	check(_cyclic_offsets_equal(offsets_at_30_steps, offsets_at_60_steps), "one-second scroll is frame-rate independent")

	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("V3-ENVIRONMENT: PASS")
		quit(0)
	else:
		print("V3-ENVIRONMENT: FAIL (%d checks)" % failures.size())
		quit(1)


func _payload(sequence: int, status: String, depth: int, hazards: Array = [], events: Array = []) -> Dictionary:
	return {
		"sequence": sequence,
		"status": status,
		"depth": depth,
		"durability": 73,
		"cargo": 4,
		"cargo_capacity": 8,
		"hazards": hazards,
		"log_events": events,
		"decision_state": "CONTINUE_RETURN" if status == "DECISION" else "NONE",
	}


func _reset_offsets(view: EnvironmentView) -> void:
	view.background_offset = 0.0
	view.midground_offset = 0.0
	view.foreground_offset = 0.0


func _cyclic_offsets_equal(left: Vector3, right: Vector3) -> bool:
	return (
		_cyclic_distance(left.x, right.x, 160.0) < 0.001
		and _cyclic_distance(left.y, right.y, 120.0) < 0.001
		and _cyclic_distance(left.z, right.z, 80.0) < 0.001
	)


func _cyclic_distance(left: float, right: float, period: float) -> float:
	var direct := absf(left - right)
	return minf(direct, period - direct)
