extends SceneTree

const OUTPUT_PATH := "res://tests/visual_log/golem_01_dyn_01/pelvis_lower_attachment_canvas.png"

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var source := Image.load_from_file("res://assets/source/golem/golem_01/parts/pelvis/pelvis_source_v1.png")
	var resized := Image.new()
	resized.copy_from(source)
	resized.resize(int(source.get_width() * 0.70), int(source.get_height() * 0.70), Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(1600, 1800, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.035, 0.045, 0.055, 1.0))
	var target := Vector2i(826 - int(626 * 0.70), 1110 - int(327 * 0.70))
	canvas.blit_rect(resized, Rect2i(Vector2i.ZERO, resized.get_size()), target)
	canvas.fill_rect(Rect2i(Vector2i(816, 1543), Vector2i(20, 20)), Color(1.0, 0.1, 0.1, 1.0))
	canvas.fill_rect(Rect2i(Vector2i(816, 1100), Vector2i(20, 20)), Color(0.1, 1.0, 0.2, 1.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_log/golem_01_dyn_01"))
	canvas.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	print("GOLEM-01 SOCKET PLOT: SAVED %s" % OUTPUT_PATH)
	quit(0)
