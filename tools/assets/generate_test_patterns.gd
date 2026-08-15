extends SceneTree

# Deterministic build tool; source assets remain hidden behind assets/source/.gdignore.

const WIDTH := 256
const HEIGHT := 128
const RUNTIME_ROOT := "res://assets/runtime/environment"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUNTIME_ROOT + "/background"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUNTIME_ROOT + "/midground"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUNTIME_ROOT + "/foreground"))
	_generate_background().save_png(RUNTIME_ROOT + "/background/background_test.png")
	_generate_midground().save_png(RUNTIME_ROOT + "/midground/midground_test.png")
	_generate_foreground().save_png(RUNTIME_ROOT + "/foreground/foreground_test.png")
	print("V4 test patterns generated: %dx%d" % [WIDTH, HEIGHT])
	quit(0)


func _generate_background() -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGB8)
	image.fill(Color("172a35"))
	_fill_rect(image, Rect2i(28, 18, 42, 76), Color("294b5a"))
	_fill_rect(image, Rect2i(102, 36, 54, 58), Color("315d68"))
	_fill_rect(image, Rect2i(188, 12, 34, 82), Color("243f4d"))
	return image


func _generate_midground() -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_fill_triangle(image, Vector2i(34, 104), Vector2i(74, 34), Vector2i(112, 104), Color("4d7980"))
	_fill_triangle(image, Vector2i(142, 104), Vector2i(182, 48), Vector2i(220, 104), Color("3f6871"))
	return image


func _generate_foreground() -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_fill_rect(image, Rect2i(0, 96, WIDTH, 32), Color("0b161c"))
	_fill_circle(image, Vector2i(48, 94), 22, Color("182a30"))
	_fill_circle(image, Vector2i(132, 98), 28, Color("12242a"))
	_fill_circle(image, Vector2i(210, 94), 20, Color("1b3036"))
	return image


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			image.set_pixel(x, y, color)


func _fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(maxi(center.y - radius, 0), mini(center.y + radius + 1, HEIGHT)):
		for x in range(maxi(center.x - radius, 0), mini(center.x + radius + 1, WIDTH)):
			if Vector2i(x, y).distance_squared_to(center) <= radius * radius:
				image.set_pixel(x, y, color)


func _fill_triangle(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, color: Color) -> void:
	var min_x := mini(a.x, mini(b.x, c.x))
	var max_x := maxi(a.x, maxi(b.x, c.x))
	var min_y := mini(a.y, mini(b.y, c.y))
	var max_y := maxi(a.y, maxi(b.y, c.y))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _inside_triangle(Vector2(x, y), Vector2(a), Vector2(b), Vector2(c)):
				image.set_pixel(x, y, color)


func _inside_triangle(point: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := _edge(point, a, b)
	var d2 := _edge(point, b, c)
	var d3 := _edge(point, c, a)
	var has_negative := d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var has_positive := d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (has_negative and has_positive)


func _edge(point: Vector2, a: Vector2, b: Vector2) -> float:
	return (point.x - b.x) * (a.y - b.y) - (a.x - b.x) * (point.y - b.y)
