class_name GolemView
extends Control

var motion_offset := Vector2.ZERO:
	set(value):
		motion_offset = value
		queue_redraw()
var motion_rotation := 0.0:
	set(value):
		motion_rotation = value
		queue_redraw()
var leg_phase := 0.0:
	set(value):
		leg_phase = value
		queue_redraw()
var reaction_strength := 0.0:
	set(value):
		reaction_strength = value
		queue_redraw()


func _draw() -> void:
	var body_color := Color("61a6a0")
	body_color = body_color.lerp(Color("df5b4f"), reaction_strength)
	var center := size * 0.5
	draw_set_transform(motion_offset, motion_rotation, Vector2.ONE)
	draw_rect(Rect2(center + Vector2(-48, -62), Vector2(96, 112)), body_color, true)
	draw_rect(Rect2(center + Vector2(-32, -96), Vector2(64, 38)), body_color.lightened(0.12), true)
	var leg_swing := sin(leg_phase * TAU) * 12.0
	draw_line(center + Vector2(-30, 48), center + Vector2(-44 + leg_swing, 88), body_color.darkened(0.18), 18.0)
	draw_line(center + Vector2(30, 48), center + Vector2(44 - leg_swing, 88), body_color.darkened(0.18), 18.0)
	if reaction_strength > 0.0:
		draw_arc(center, 92.0 + reaction_strength * 12.0, 0.0, TAU, 40, Color(1.0, 0.24, 0.18, reaction_strength), 4.0)
