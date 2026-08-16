extends SceneTree

const ASSETS := {
	"background": "res://assets/runtime/environment/quarry/background/quarry_background_v1.png",
	"midground": "res://assets/runtime/environment/quarry/midground/quarry_midground_v1.png",
	"foreground": "res://assets/runtime/environment/quarry/foreground/quarry_foreground_v1.png",
}
const EXPECTED_SIZE := Vector2i(1024, 512)
const EXPECTED_MEMORY := 1024 * 512 * (3 + 4 + 4)

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("run_gate")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("V5 GATE FAIL: %s" % message)


func run_gate() -> void:
	check(EXPECTED_MEMORY <= 6 * 1024 * 1024, "preferred 6 MiB texture-memory ceiling")
	for layer in ASSETS:
		var path: String = ASSETS[layer]
		check(ResourceLoader.exists(path), "%s is importable" % layer)
		var texture := load(path) as Texture2D
		check(texture != null, "%s imports as Texture2D" % layer)
		if texture == null:
			continue
		check(Vector2i(texture.get_width(), texture.get_height()) == EXPECTED_SIZE, "%s is 1024x512" % layer)
		var image := texture.get_image()
		check(_edges_match(image), "%s horizontal edge pixels match" % layer)
		var rgba := image.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_LA8]
		if layer == "background":
			check(not rgba, "background imports without alpha")
		else:
			check(rgba and _contains_transparency(image), "%s preserves transparency" % layer)
		var import_text := FileAccess.get_file_as_string(path + ".import")
		check(import_text.contains("compress/mode=0"), "%s uses lossless import" % layer)
		check(import_text.contains("mipmaps/generate=false"), "%s disables mipmaps" % layer)
		check(import_text.contains("process/fix_alpha_border=true"), "%s fixes alpha border" % layer)
		check(import_text.contains("process/premult_alpha=false"), "%s uses straight alpha" % layer)

	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	var scene := packed.instantiate()
	var source := scene.get_node("MockTelemetrySource") as MockTelemetrySource
	source.interval_seconds = 10.0
	root.add_child(scene)
	await process_frame
	var view := scene.get_node("%EnvironmentView") as EnvironmentView
	var environment := scene.get_node("%EnvironmentController") as EnvironmentController
	var textures := [view.background_texture, view.midground_texture, view.foreground_texture]
	view.background_offset = 31.0
	view.midground_offset = 47.0
	view.foreground_offset = 59.0
	var offsets := Vector3(view.background_offset, view.midground_offset, view.foreground_offset)
	var revision := environment.state_revision
	scene.apply_responsive_layout_for_width(600.0)
	scene.apply_responsive_layout_for_width(1280.0)
	await process_frame
	check(textures == [view.background_texture, view.midground_texture, view.foreground_texture], "PC and Mobile share Texture2D resources")
	check(offsets == Vector3(view.background_offset, view.midground_offset, view.foreground_offset), "resize preserves scroll phase")
	check(revision == environment.state_revision, "resize preserves environment state")
	var view_source := FileAccess.get_file_as_string("res://scripts/views/environment_view.gd")
	check(view_source.contains("maxf(size.x / texture_size.x, size.y / texture_size.y)"), "CENTER-COVER uses uniform maximum scale")

	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("V5-QUARRY-ASSET: PASS (%d estimated bytes)" % EXPECTED_MEMORY)
		quit(0)
	else:
		print("V5-QUARRY-ASSET: FAIL (%d checks)" % failures.size())
		quit(1)


func _edges_match(image: Image) -> bool:
	for y in range(image.get_height()):
		var left := image.get_pixel(0, y)
		var right := image.get_pixel(image.get_width() - 1, y)
		if not is_equal_approx(left.a, right.a):
			return false
		# fix_alpha_border may rewrite RGB beneath transparent and nearly
		# transparent pixels. Compare their visible, alpha-weighted contribution
		# with two 8-bit display steps of tolerance. This covers import-time
		# fringe-color repair without accepting an opaque seam discontinuity.
		var visible_delta := Vector3(
			absf(left.r * left.a - right.r * right.a),
			absf(left.g * left.a - right.g * right.a),
			absf(left.b * left.a - right.b * right.a)
		)
		if maxf(visible_delta.x, maxf(visible_delta.y, visible_delta.z)) > 2.0 / 255.0:
			return false
	return true


func _contains_transparency(image: Image) -> bool:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a < 1.0:
				return true
	return false
