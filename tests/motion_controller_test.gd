extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("run_gate")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("V2 GATE FAIL: %s" % message)


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
	var motion := scene.get_node("%MotionController") as MotionController
	check(motion.animation_player.has_animation(&"idle"), "IDLE animation exists")
	check(motion.animation_player.has_animation(&"walking"), "WALKING animation exists")
	check(motion.animation_player.has_animation(&"harvesting"), "HARVESTING animation exists")
	check(motion.animation_player.has_animation(&"decision"), "DECISION animation exists")
	check(motion.animation_player.has_animation(&"hazard_reaction"), "HAZARD one-shot exists")

	check(presenter.accept(_payload(20, "WALKING")), "walking state accepted")
	check(motion.persistent_motion == &"walking", "WALKING maps to walking motion")
	check(motion.animation_player.current_animation == &"walking", "walking loop plays")
	var persistent_count := motion.persistent_play_count
	var one_shot_count := motion.one_shot_play_count

	check(presenter.accept(_payload(21, "WALKING", [{"type": "WARNING", "message": "Impact."}])), "warning event accepted")
	check(motion.active_one_shot == &"hazard_reaction", "warning starts one-shot")
	check(motion.one_shot_play_count == one_shot_count + 1, "one-shot fires exactly once")
	await create_timer(0.4).timeout
	check(motion.active_one_shot.is_empty(), "one-shot completes")
	check(motion.animation_player.current_animation == &"walking", "persistent walking resumes")

	check(not presenter.accept(_payload(19, "DECISION", [{"type": "WARNING", "message": "Stale."}])), "stale telemetry rejected")
	check(motion.persistent_motion == &"walking", "stale telemetry does not change motion")
	check(motion.one_shot_play_count == one_shot_count + 1, "stale event does not fire one-shot")

	var before_layout := motion.one_shot_play_count
	scene.apply_responsive_layout_for_width(600.0)
	scene.apply_responsive_layout_for_width(1280.0)
	await process_frame
	check(motion.one_shot_play_count == before_layout, "responsive switch does not replay animation")

	var before_rebind := motion.one_shot_play_count
	check(presenter.replay_current_state(), "persistent state rebind succeeds")
	await process_frame
	check(motion.one_shot_play_count == before_rebind, "view rebind does not replay transient animation")
	check(motion.persistent_play_count == persistent_count + 1, "rebind does not restart identical persistent loop")

	for status in ["IDLE", "HARVESTING", "DECISION"]:
		var sequence := 30 + ["IDLE", "HARVESTING", "DECISION"].find(status)
		check(presenter.accept(_payload(sequence, status)), "%s state accepted" % status)
		check(motion.persistent_motion == MotionController.STATUS_TO_MOTION[status], "%s maps to persistent motion" % status)

	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("V2-MOTION: PASS")
		quit(0)
	else:
		print("V2-MOTION: FAIL (%d checks)" % failures.size())
		quit(1)


func _payload(sequence: int, status: String, events: Array = []) -> Dictionary:
	return {
		"sequence": sequence,
		"status": status,
		"depth": 2,
		"durability": 73,
		"cargo": 4,
		"cargo_capacity": 8,
		"hazards": [],
		"log_events": events,
		"decision_state": "CONTINUE_RETURN" if status == "DECISION" else "NONE",
	}

