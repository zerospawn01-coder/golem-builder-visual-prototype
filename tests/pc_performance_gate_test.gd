extends SceneTree

const RESOLUTION := Vector2i(1280, 720)
const WARMUP_SECONDS := 1.0
const SAMPLE_SECONDS := 5.0
const TARGET_FPS := 60.0
const OUTPUT_PATH := "tests/visual_log/v5_performance/pc_performance.json"

var failures: PackedStringArray = []
var sequence := 100


func _init() -> void:
	call_deferred("run_gate")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("V5 PC PERFORMANCE FAIL: %s" % message)


func run_gate() -> void:
	DisplayServer.window_set_size(RESOLUTION)
	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	var scene := packed.instantiate()
	(scene.get_node("MockTelemetrySource") as MockTelemetrySource).interval_seconds = 10.0
	root.add_child(scene)
	await process_frame
	var presenter := scene.get_node("ExpeditionPresenter") as ExpeditionPresenter

	var traversal := await _measure_state(presenter, "TRAVERSAL", false)
	var hazard := await _measure_state(presenter, "HAZARD_REACTION", true)
	check(traversal["average_fps"] >= TARGET_FPS, "TRAVERSAL average FPS >= 60")
	check(hazard["average_fps"] >= TARGET_FPS, "HAZARD_REACTION average FPS >= 60")

	var evidence := {
		"phase": "V5 PC PERFORMANCE",
		"renderer": RenderingServer.get_video_adapter_name(),
		"rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"resolution": {"width": RESOLUTION.x, "height": RESOLUTION.y},
		"vsync_forced_off": true,
		"warmup_seconds": WARMUP_SECONDS,
		"sample_seconds_per_state": SAMPLE_SECONDS,
		"target_fps": TARGET_FPS,
		"states": [traversal, hazard],
		"verdict": "PASS" if failures.is_empty() else "FAIL",
	}
	var absolute_output := ProjectSettings.globalize_path("res://%s" % OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	var file := FileAccess.open(absolute_output, FileAccess.WRITE)
	check(file != null, "performance evidence file opened")
	if file != null:
		file.store_string(JSON.stringify(evidence, "  "))

	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("V5-PC-PERFORMANCE: PASS traversal=%.1f FPS hazard=%.1f FPS" % [traversal["average_fps"], hazard["average_fps"]])
		quit(0)
	else:
		print("V5-PC-PERFORMANCE: FAIL (%d checks)" % failures.size())
		quit(1)


func _measure_state(presenter: ExpeditionPresenter, label: String, repeat_hazard: bool) -> Dictionary:
	_emit_state(presenter, repeat_hazard)
	await _wait_seconds(WARMUP_SECONDS, presenter, repeat_hazard)
	var frame_times: Array[float] = []
	var start_usec := Time.get_ticks_usec()
	var last_usec := start_usec
	var last_reaction_usec := start_usec
	while (Time.get_ticks_usec() - start_usec) / 1_000_000.0 < SAMPLE_SECONDS:
		await process_frame
		var now_usec := Time.get_ticks_usec()
		frame_times.append((now_usec - last_usec) / 1_000_000.0)
		last_usec = now_usec
		if repeat_hazard and (now_usec - last_reaction_usec) >= 250_000:
			_emit_state(presenter, true)
			last_reaction_usec = now_usec
	var elapsed := (Time.get_ticks_usec() - start_usec) / 1_000_000.0
	var sorted_times := frame_times.duplicate()
	sorted_times.sort()
	var p99_index := mini(sorted_times.size() - 1, int(floor(sorted_times.size() * 0.99)))
	var p99_frame_seconds: float = sorted_times[p99_index]
	return {
		"activity": label,
		"frames": frame_times.size(),
		"elapsed_seconds": elapsed,
		"average_fps": frame_times.size() / elapsed,
		"one_percent_low_fps": 1.0 / p99_frame_seconds if p99_frame_seconds > 0.0 else 0.0,
	}


func _wait_seconds(seconds: float, presenter: ExpeditionPresenter, repeat_hazard: bool) -> void:
	var start_usec := Time.get_ticks_usec()
	var last_reaction_usec := start_usec
	while (Time.get_ticks_usec() - start_usec) / 1_000_000.0 < seconds:
		await process_frame
		var now_usec := Time.get_ticks_usec()
		if repeat_hazard and (now_usec - last_reaction_usec) >= 250_000:
			_emit_state(presenter, true)
			last_reaction_usec = now_usec


func _emit_state(presenter: ExpeditionPresenter, hazard: bool) -> void:
	sequence += 1
	var hazards: Array = [{"type": "MASS_LOAD", "severity": 2}] if hazard else []
	var events: Array = [{"type": "WARNING", "message": "Performance reaction pulse."}] if hazard else []
	presenter.accept({
		"sequence": sequence,
		"status": "WALKING",
		"depth": 2,
		"durability": 73,
		"cargo": 4,
		"cargo_capacity": 8,
		"hazards": hazards,
		"log_events": events,
		"decision_state": "NONE",
	})
