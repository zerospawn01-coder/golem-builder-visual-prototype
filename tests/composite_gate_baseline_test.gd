extends SceneTree

const POSES := [&"NEUTRAL", &"WALKING_EXTENT", &"HAZARD_REACTION_EXTENT"]
const SIGNALS := [&"NO_LIGHT", &"NORMAL_CYAN", &"WARNING_AMBER", &"CRITICAL_RED"]
const PC_SIZE := Vector2i(1280, 720)
const MOBILE_SIZE := Vector2i(720, 1280)
const PC_THUMBNAIL := Vector2i(320, 180)
const MOBILE_THUMBNAIL := Vector2i(180, 320)
const OUTPUT_DIR := "tests/visual_log/v5_composite_baseline"
const CANDIDATE_PATHS := {
	"background": "res://tests/fixtures/v5_quarry_candidate/v2/quarry_background_candidate.png",
	"midground": "res://tests/fixtures/v5_quarry_candidate/v2/quarry_midground_candidate.png",
	"foreground": "res://tests/fixtures/v5_quarry_candidate/v2/quarry_foreground_candidate.png",
}

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("run_gate")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("V5 COMPOSITE BASELINE FAIL: %s" % message)


func run_gate() -> void:
	var use_v2_candidate := "--v2-candidate" in OS.get_cmdline_user_args()
	var use_runtime_current := "--runtime-current" in OS.get_cmdline_user_args()
	check(not (use_v2_candidate and use_runtime_current), "candidate and runtime capture modes are mutually exclusive")
	var output_dir := OUTPUT_DIR
	var pc_filename := "quarry_pc_measurement_baseline.png"
	var mobile_filename := "quarry_mobile_measurement_baseline.png"
	var capture_label := "BASELINE"
	if use_v2_candidate:
		output_dir = "tests/visual_log/v5_composite_v2_candidate"
		pc_filename = "quarry_pc_measurement_candidate.png"
		mobile_filename = "quarry_mobile_measurement_candidate.png"
		capture_label = "V2-CANDIDATE"
	elif use_runtime_current:
		output_dir = "tests/visual_log/v5_composite_runtime"
		pc_filename = "quarry_pc_measurement_runtime.png"
		mobile_filename = "quarry_mobile_measurement_runtime.png"
		capture_label = "RUNTIME"
	check(GolemView.MEASUREMENT_POSES == POSES, "measurement poses are frozen")
	check(GolemView.MEASUREMENT_SIGNALS == SIGNALS, "measurement signals are frozen")
	if use_v2_candidate:
		for path in CANDIDATE_PATHS.values():
			check(ResourceLoader.exists(path), "V2 candidate imports: %s" % path)
	var output_path := ProjectSettings.globalize_path("res://%s" % output_dir)
	DirAccess.make_dir_recursive_absolute(output_path)

	var pc_sheet := await _capture_contact_sheet(PC_SIZE, PC_THUMBNAIL, false, use_v2_candidate)
	var mobile_sheet := await _capture_contact_sheet(MOBILE_SIZE, MOBILE_THUMBNAIL, true, use_v2_candidate)
	check(not pc_sheet.is_empty(), "PC composite contact sheet rendered")
	check(not mobile_sheet.is_empty(), "Mobile composite contact sheet rendered")
	if not pc_sheet.is_empty():
		check(pc_sheet.save_png(output_path.path_join(pc_filename)) == OK, "PC composite saved")
	if not mobile_sheet.is_empty():
		check(mobile_sheet.save_png(output_path.path_join(mobile_filename)) == OK, "Mobile composite saved")

	if failures.is_empty():
		print("V5-COMPOSITE-%s: PASS (capture only; alignment not evaluated)" % capture_label)
		quit(0)
	else:
		print("V5-COMPOSITE-BASELINE: FAIL (%d checks)" % failures.size())
		quit(1)


func _capture_contact_sheet(viewport_size: Vector2i, thumbnail_size: Vector2i, expect_mobile: bool, use_v2_candidate: bool) -> Image:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)

	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	var scene := packed.instantiate()
	(scene.get_node("MockTelemetrySource") as MockTelemetrySource).interval_seconds = 10.0
	viewport.add_child(scene)
	await process_frame
	if use_v2_candidate:
		var environment_view := scene.get_node("%EnvironmentView") as EnvironmentView
		environment_view.background_texture = load(CANDIDATE_PATHS["background"])
		environment_view.midground_texture = load(CANDIDATE_PATHS["midground"])
		environment_view.foreground_texture = load(CANDIDATE_PATHS["foreground"])
		environment_view.queue_redraw()
	scene.apply_responsive_layout_for_width(float(viewport_size.x))
	check((scene.get_node("%MainSplit") as SplitContainer).vertical == expect_mobile, "%s responsive UI selected" % ("Mobile" if expect_mobile else "PC"))

	var golem := scene.get_node("%GolemView") as GolemView
	var motion := scene.get_node("%MotionController") as MotionController
	motion.animation_player.pause()
	var hazard_panel := scene.get_node("%HazardPanel") as PanelContainer
	var hazard_label := scene.get_node("%HazardLabel") as Label
	var decision_ui := scene.get_node("%DecisionUI") as HBoxContainer
	var sheet := Image.create(thumbnail_size.x * SIGNALS.size(), thumbnail_size.y * POSES.size(), false, Image.FORMAT_RGB8)

	for row in range(POSES.size()):
		for column in range(SIGNALS.size()):
			var signal_state: StringName = SIGNALS[column]
			golem.set_measurement_state(POSES[row], signal_state)
			_apply_measurement_ui(signal_state, hazard_panel, hazard_label, decision_ui)
			await process_frame
			RenderingServer.force_draw()
			await process_frame
			var frame := viewport.get_texture().get_image()
			check(frame != null and not frame.is_empty(), "%s/%s framebuffer rendered" % [POSES[row], signal_state])
			if frame == null or frame.is_empty():
				continue
			frame.convert(Image.FORMAT_RGB8)
			frame.resize(thumbnail_size.x, thumbnail_size.y, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, thumbnail_size), Vector2i(column * thumbnail_size.x, row * thumbnail_size.y))

	viewport.queue_free()
	await process_frame
	return sheet


func _apply_measurement_ui(signal_state: StringName, hazard_panel: PanelContainer, hazard_label: Label, decision_ui: HBoxContainer) -> void:
	hazard_panel.visible = signal_state in [&"WARNING_AMBER", &"CRITICAL_RED"]
	decision_ui.visible = signal_state == &"CRITICAL_RED"
	match signal_state:
		&"WARNING_AMBER":
			hazard_label.text = "WARNING / MEASUREMENT AMBER"
			hazard_label.add_theme_color_override("font_color", Color("f1a33b"))
		&"CRITICAL_RED":
			hazard_label.text = "CRITICAL / MEASUREMENT RED"
			hazard_label.add_theme_color_override("font_color", Color("f04438"))
		_:
			hazard_label.text = ""
