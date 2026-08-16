class_name GolemView
extends Control

const MEASUREMENT_POSES := [&"NEUTRAL", &"WALKING_EXTENT", &"HAZARD_REACTION_EXTENT"]
const MEASUREMENT_SIGNALS := [&"NO_LIGHT", &"NORMAL_CYAN", &"WARNING_AMBER", &"CRITICAL_RED"]
const SIGNAL_COLORS := {
	&"NO_LIGHT": Color(0.18, 0.21, 0.22, 1.0),
	&"NORMAL_CYAN": Color("55d9d0"),
	&"WARNING_AMBER": Color("f1a33b"),
	&"CRITICAL_RED": Color("f04438"),
}

var measurement_enabled := false:
	set(value):
		measurement_enabled = value
		queue_redraw()
var measurement_pose: StringName = &"NEUTRAL"
var measurement_signal: StringName = &"NO_LIGHT"
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
	if measurement_enabled:
		_draw_measurement_placeholder()
		return
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


func set_measurement_state(pose: StringName, signal_state: StringName) -> void:
	assert(pose in MEASUREMENT_POSES, "Unknown measurement pose: %s" % pose)
	assert(signal_state in MEASUREMENT_SIGNALS, "Unknown measurement signal: %s" % signal_state)
	measurement_enabled = true
	measurement_pose = pose
	measurement_signal = signal_state
	queue_redraw()


func clear_measurement_state() -> void:
	measurement_enabled = false


func _draw_measurement_placeholder() -> void:
	var center := size * 0.5
	var pose_offset := Vector2.ZERO
	var pose_rotation := 0.0
	var leg_extent := 0.0
	var reaction_extent := 0.0
	match measurement_pose:
		&"WALKING_EXTENT":
			leg_extent = 12.0
		&"HAZARD_REACTION_EXTENT":
			pose_offset = Vector2(-20.0, -3.0)
			pose_rotation = -0.12
			reaction_extent = 1.0

	var body_color := Color(0.26, 0.29, 0.30, 1.0)
	var outline_color := Color(0.72, 0.75, 0.73, 1.0)
	var signal_color: Color = SIGNAL_COLORS[measurement_signal]
	draw_set_transform(pose_offset, pose_rotation, Vector2.ONE)
	draw_rect(Rect2(center + Vector2(-48, -62), Vector2(96, 112)), body_color, true)
	draw_rect(Rect2(center + Vector2(-48, -62), Vector2(96, 112)), outline_color, false, 3.0)
	draw_rect(Rect2(center + Vector2(-32, -96), Vector2(64, 38)), body_color.lightened(0.08), true)
	draw_rect(Rect2(center + Vector2(-32, -96), Vector2(64, 38)), outline_color, false, 3.0)
	draw_line(center + Vector2(-30, 48), center + Vector2(-44 + leg_extent, 88), outline_color, 18.0)
	draw_line(center + Vector2(30, 48), center + Vector2(44 - leg_extent, 88), outline_color, 18.0)
	draw_circle(center + Vector2(0, -12), 15.0, signal_color)
	if measurement_signal != &"NO_LIGHT":
		draw_arc(center + Vector2(0, -12), 22.0, 0.0, TAU, 32, Color(signal_color, 0.65), 4.0)
	if reaction_extent > 0.0:
		draw_arc(center, 104.0, 0.0, TAU, 40, Color(1.0, 0.24, 0.18, 0.9), 4.0)
