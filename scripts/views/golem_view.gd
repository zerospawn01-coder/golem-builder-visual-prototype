class_name GolemView
extends Control

var _status := "IDLE"


func set_status(value: String) -> void:
	_status = value
	queue_redraw()


func _draw() -> void:
	var body_color := Color("61a6a0")
	if _status == "HARVESTING":
		body_color = Color("d4a84f")
	elif _status == "HAZARD":
		body_color = Color("df5b4f")
	elif _status == "DECISION":
		body_color = Color("8e7cc3")
	var center := size * 0.5
	draw_rect(Rect2(center + Vector2(-48, -62), Vector2(96, 112)), body_color, true)
	draw_rect(Rect2(center + Vector2(-32, -96), Vector2(64, 38)), body_color.lightened(0.12), true)
	draw_line(center + Vector2(-30, 48), center + Vector2(-44, 88), body_color.darkened(0.18), 18.0)
	draw_line(center + Vector2(30, 48), center + Vector2(44, 88), body_color.darkened(0.18), 18.0)
	if _status == "WALKING":
		draw_arc(center + Vector2(0, 92), 62, PI, TAU, 24, Color("70d6ff"), 3.0)

