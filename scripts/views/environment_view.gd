class_name EnvironmentView
extends Control

var background_offset := 0.0
var midground_offset := 0.0
var foreground_offset := 0.0
var visual_intensity := 0.0
var hazard_strength := 0.0


func apply_environment_state(_activity: StringName, depth: int, hazard_active: bool) -> void:
	visual_intensity = clampf(float(maxi(depth - 1, 0)) * 0.12, 0.0, 0.5)
	hazard_strength = 1.0 if hazard_active else 0.0
	queue_redraw()


func advance_scroll(background_delta: float, midground_delta: float, foreground_delta: float) -> void:
	background_offset = fposmod(background_offset + background_delta, 160.0)
	midground_offset = fposmod(midground_offset + midground_delta, 120.0)
	foreground_offset = fposmod(foreground_offset + foreground_delta, 80.0)
	queue_redraw()


func _draw() -> void:
	var darkness := visual_intensity
	draw_rect(Rect2(Vector2.ZERO, size), Color("16242b").darkened(darkness), true)
	_draw_background_layer()
	_draw_midground_layer()
	_draw_foreground_layer()
	if hazard_strength > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.04, 0.03, 0.16 * hazard_strength), true)
		draw_arc(size * 0.5, minf(size.x, size.y) * 0.32, 0.0, TAU, 48, Color(1.0, 0.2, 0.14, 0.65), 3.0)


func _draw_background_layer() -> void:
	var color := Color("243b45").darkened(visual_intensity)
	var spacing := 160.0
	var x := -background_offset - spacing
	while x < size.x + spacing:
		draw_rect(Rect2(Vector2(x, size.y * 0.12), Vector2(44, size.y * 0.58)), color, true)
		x += spacing


func _draw_midground_layer() -> void:
	var color := Color("31515a").darkened(visual_intensity)
	var spacing := 120.0
	var x := -midground_offset - spacing
	while x < size.x + spacing:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, size.y * 0.72),
			Vector2(x + 34, size.y * 0.42),
			Vector2(x + 70, size.y * 0.72),
		]), color)
		x += spacing


func _draw_foreground_layer() -> void:
	var color := Color("0c1519").darkened(visual_intensity)
	draw_rect(Rect2(Vector2(0, size.y * 0.78), Vector2(size.x, size.y * 0.22)), color, true)
	var spacing := 80.0
	var x := -foreground_offset - spacing
	while x < size.x + spacing:
		draw_circle(Vector2(x, size.y * 0.8), 22.0, color.lightened(0.08))
		x += spacing

