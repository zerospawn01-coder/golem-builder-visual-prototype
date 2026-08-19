class_name EnvironmentView
extends Control

@export var background_texture: Texture2D
@export var midground_texture: Texture2D
@export var foreground_texture: Texture2D

var background_offset := 0.0
var midground_offset := 0.0
var foreground_offset := 0.0
var visual_intensity := 0.0
var hazard_strength := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


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
	if background_texture != null:
		_draw_texture_layer(background_texture, background_offset)
		return
	var color := Color("243b45").darkened(visual_intensity)
	var spacing := 160.0
	var x := -background_offset - spacing
	while x < size.x + spacing:
		draw_rect(Rect2(Vector2(x, size.y * 0.12), Vector2(44, size.y * 0.58)), color, true)
		x += spacing


func _draw_midground_layer() -> void:
	if midground_texture != null:
		_draw_texture_layer(midground_texture, midground_offset)
		return
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
	if foreground_texture != null:
		_draw_texture_layer(foreground_texture, foreground_offset)
		return
	var color := Color("0c1519").darkened(visual_intensity)
	draw_rect(Rect2(Vector2(0, size.y * 0.78), Vector2(size.x, size.y * 0.22)), color, true)
	var spacing := 80.0
	var x := -foreground_offset - spacing
	while x < size.x + spacing:
		draw_circle(Vector2(x, size.y * 0.8), 22.0, color.lightened(0.08))
		x += spacing


func _draw_texture_layer(texture: Texture2D, offset: float) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return
	var cover_scale := maxf(size.x / texture_size.x, size.y / texture_size.y)
	var tile_size := texture_size * cover_scale
	var phase := fposmod(offset, texture_size.x) * cover_scale
	var origin := Vector2((size.x - tile_size.x) * 0.5 - phase, (size.y - tile_size.y) * 0.5)
	while origin.x > 0.0:
		origin.x -= tile_size.x
	var modulate := Color.WHITE.darkened(visual_intensity)
	var x := origin.x
	while x < size.x:
		draw_texture_rect(texture, Rect2(Vector2(x, origin.y), tile_size), false, modulate)
		x += tile_size.x

