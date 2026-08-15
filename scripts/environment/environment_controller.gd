class_name EnvironmentController
extends Node

signal environment_state_changed(activity: StringName, depth: int, hazard_active: bool)

const STATUS_TO_ACTIVITY := {
	"IDLE": &"QUIET",
	"WALKING": &"TRAVERSAL",
	"HARVESTING": &"HARVEST",
	"HAZARD": &"HAZARD",
	"DECISION": &"DECISION",
}
const ACTIVITY_SCROLL_SPEED := {
	&"QUIET": 0.0,
	&"TRAVERSAL": 80.0,
	&"HARVEST": 0.0,
	&"HAZARD": 0.0,
	&"DECISION": 0.0,
}
const LAYER_SPEED_RATIO := {
	"background": 0.25,
	"midground": 0.55,
	"foreground": 1.0,
}

@export var environment_view_path := NodePath("../EnvironmentView")

@onready var environment_view: EnvironmentView = get_node(environment_view_path)

var activity: StringName = &"QUIET"
var depth := 0
var hazard_active := false
var state_revision := 0


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	var speed: float = ACTIVITY_SCROLL_SPEED.get(activity, 0.0)
	if is_zero_approx(speed):
		return
	environment_view.advance_scroll(
		speed * LAYER_SPEED_RATIO["background"] * delta,
		speed * LAYER_SPEED_RATIO["midground"] * delta,
		speed * LAYER_SPEED_RATIO["foreground"] * delta
	)


func apply_state(state: PresentationState) -> void:
	var next_activity: StringName = STATUS_TO_ACTIVITY.get(state.golem_state["status"], &"QUIET")
	var next_depth: int = state.telemetry_state["depth"]
	var next_hazard_active: bool = not state.environment_state["hazards"].is_empty()
	if next_activity == activity and next_depth == depth and next_hazard_active == hazard_active:
		return
	activity = next_activity
	depth = next_depth
	hazard_active = next_hazard_active
	state_revision += 1
	environment_view.apply_environment_state(activity, depth, hazard_active)
	environment_state_changed.emit(activity, depth, hazard_active)
