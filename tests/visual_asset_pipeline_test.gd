extends SceneTree

const ASSETS := {
	"background": "res://assets/runtime/environment/background/background_test.png",
	"midground": "res://assets/runtime/environment/midground/midground_test.png",
	"foreground": "res://assets/runtime/environment/foreground/foreground_test.png",
}
const MAX_DIMENSIONS := Vector2i(2048, 1024)
const MAX_TEST_MEMORY_BYTES := 1024 * 1024

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("run_gate")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("V4 GATE FAIL: %s" % message)


func run_gate() -> void:
	check(FileAccess.file_exists("res://assets/source/.gdignore"), "source assets are isolated with .gdignore")
	var gitignore := FileAccess.get_file_as_string("res://.gitignore")
	check(gitignore.contains(".godot/"), ".godot cache is excluded from version control")
	var estimated_memory := 0
	for asset_name in ASSETS:
		var path: String = ASSETS[asset_name]
		check(ResourceLoader.exists(path), "%s is available through ResourceLoader" % asset_name)
		var texture := load(path)
		check(texture is Texture2D, "%s imports as Texture2D" % asset_name)
		if not texture is Texture2D:
			continue
		check(texture.get_width() == 256 and texture.get_height() == 128, "%s dimensions are recorded" % asset_name)
		check(texture.get_width() <= MAX_DIMENSIONS.x and texture.get_height() <= MAX_DIMENSIONS.y, "%s stays within environment budget" % asset_name)
		var image: Image = texture.get_image()
		check(not image.is_empty(), "%s imported texture image is readable" % asset_name)
		check(_edges_are_seamless(image), "%s has matching horizontal seam pixels" % asset_name)
		var has_alpha := image.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_LA8]
		if asset_name == "background":
			check(not has_alpha, "opaque background uses RGB")
			estimated_memory += image.get_width() * image.get_height() * 3
		else:
			check(has_alpha and _contains_transparency(image), "%s preserves alpha" % asset_name)
			estimated_memory += image.get_width() * image.get_height() * 4
		var import_text := FileAccess.get_file_as_string(path + ".import")
		check(FileAccess.file_exists(path + ".import"), "%s import metadata exists for VCS" % asset_name)
		check(import_text.contains("type=\"CompressedTexture2D\""), "%s import type is Texture2D" % asset_name)
		check(import_text.contains("compress/mode=0"), "%s compression is Lossless" % asset_name)
		check(import_text.contains("mipmaps/generate=false"), "%s mipmaps are disabled" % asset_name)
	check(estimated_memory <= MAX_TEST_MEMORY_BYTES, "test textures stay within memory budget")
	var view_source := FileAccess.get_file_as_string("res://scripts/views/environment_view.gd")
	var controller_source := FileAccess.get_file_as_string("res://scripts/environment/environment_controller.gd")
	check(not view_source.contains("FileAccess") and not view_source.contains("Image.load"), "EnvironmentView does not bypass ResourceLoader")
	check(not controller_source.contains("Texture2D") and not controller_source.contains("assets/runtime"), "EnvironmentController remains asset-agnostic")

	var packed := load("res://scenes/expedition/expedition_scene.tscn") as PackedScene
	var scene := packed.instantiate()
	var source := scene.get_node("MockTelemetrySource") as MockTelemetrySource
	source.interval_seconds = 10.0
	root.add_child(scene)
	await process_frame
	var view := scene.get_node("%EnvironmentView") as EnvironmentView
	var environment := scene.get_node("%EnvironmentController") as EnvironmentController
	check(view.background_texture is Texture2D, "background texture binds without controller changes")
	check(view.midground_texture is Texture2D, "midground texture binds without controller changes")
	check(view.foreground_texture is Texture2D, "foreground texture binds without controller changes")
	check(view.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "2D filter is linear on CanvasItem")
	check(view.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED, "scrolling texture repeat is enabled on CanvasItem")
	var revision_before := environment.state_revision
	var textures_before := [view.background_texture, view.midground_texture, view.foreground_texture]
	scene.apply_responsive_layout_for_width(600.0)
	scene.apply_responsive_layout_for_width(1280.0)
	await process_frame
	check(environment.state_revision == revision_before, "aspect change does not regenerate environment state")
	check(textures_before == [view.background_texture, view.midground_texture, view.foreground_texture], "PC and Mobile reuse the same textures")

	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("V4-ASSET-PIPELINE: PASS (%d estimated bytes)" % estimated_memory)
		quit(0)
	else:
		print("V4-ASSET-PIPELINE: FAIL (%d checks)" % failures.size())
		quit(1)


func _edges_are_seamless(image: Image) -> bool:
	for y in range(image.get_height()):
		if image.get_pixel(0, y) != image.get_pixel(image.get_width() - 1, y):
			return false
	return true


func _contains_transparency(image: Image) -> bool:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a < 1.0:
				return true
	return false
