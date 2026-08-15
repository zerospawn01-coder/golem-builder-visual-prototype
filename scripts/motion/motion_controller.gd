class_name MotionController
extends Node

signal persistent_motion_changed(motion_name: StringName)
signal one_shot_started(motion_name: StringName)
signal one_shot_finished(motion_name: StringName)

const STATUS_TO_MOTION := {
	"IDLE": &"idle",
	"WALKING": &"walking",
	"HARVESTING": &"harvesting",
	"HAZARD": &"idle",
	"DECISION": &"decision",
}
const EVENT_TO_ONE_SHOT := {
	"WARNING": &"hazard_reaction",
	"IMPACT": &"hazard_reaction",
}

@export var golem_view_path := NodePath("../GolemView")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var golem_view: GolemView = get_node(golem_view_path)

var persistent_motion: StringName = &"idle"
var active_one_shot: StringName = &""
var persistent_play_count := 0
var one_shot_play_count := 0


func _ready() -> void:
	_install_motion_library()
	animation_player.animation_finished.connect(_on_animation_finished)
	_play_persistent(&"idle", true)


func apply_state(state: PresentationState) -> void:
	var next_motion: StringName = STATUS_TO_MOTION.get(state.golem_state["status"], &"idle")
	if next_motion == persistent_motion:
		return
	persistent_motion = next_motion
	if active_one_shot.is_empty():
		_play_persistent(persistent_motion)


func apply_transient_events(batch: TransientEventBatch) -> void:
	for event in batch.events:
		var event_type: String = event.get("type", "")
		if EVENT_TO_ONE_SHOT.has(event_type):
			_play_one_shot(EVENT_TO_ONE_SHOT[event_type])
			return


func _play_persistent(motion_name: StringName, force := false) -> void:
	if not force and animation_player.current_animation == motion_name and animation_player.is_playing():
		return
	persistent_motion = motion_name
	persistent_play_count += 1
	animation_player.play(motion_name)
	persistent_motion_changed.emit(motion_name)


func _play_one_shot(motion_name: StringName) -> void:
	active_one_shot = motion_name
	one_shot_play_count += 1
	animation_player.play(motion_name)
	one_shot_started.emit(motion_name)


func _on_animation_finished(motion_name: StringName) -> void:
	if motion_name != active_one_shot:
		return
	active_one_shot = &""
	one_shot_finished.emit(motion_name)
	_play_persistent(persistent_motion, true)


func _install_motion_library() -> void:
	var library := AnimationLibrary.new()
	library.add_animation(&"RESET", _reset_animation())
	library.add_animation(&"idle", _idle_animation())
	library.add_animation(&"walking", _walking_animation())
	library.add_animation(&"harvesting", _harvesting_animation())
	library.add_animation(&"decision", _decision_animation())
	library.add_animation(&"hazard_reaction", _hazard_reaction_animation())
	animation_player.add_animation_library(&"", library)


func _animation(length: float, looped := false) -> Animation:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR if looped else Animation.LOOP_NONE
	return animation


func _value_track(animation: Animation, property_name: String, keys: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath("../GolemView:%s" % property_name))
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	for key in keys:
		animation.track_insert_key(track, key[0], key[1])


func _reset_animation() -> Animation:
	var animation := _animation(0.1)
	_value_track(animation, "motion_offset", [[0.0, Vector2.ZERO]])
	_value_track(animation, "motion_rotation", [[0.0, 0.0]])
	_value_track(animation, "leg_phase", [[0.0, 0.0]])
	_value_track(animation, "reaction_strength", [[0.0, 0.0]])
	return animation


func _idle_animation() -> Animation:
	var animation := _animation(1.2, true)
	_value_track(animation, "motion_offset", [[0.0, Vector2.ZERO], [0.6, Vector2(0, -5)], [1.2, Vector2.ZERO]])
	_value_track(animation, "motion_rotation", [[0.0, 0.0], [1.2, 0.0]])
	_value_track(animation, "leg_phase", [[0.0, 0.0], [1.2, 0.0]])
	_value_track(animation, "reaction_strength", [[0.0, 0.0], [1.2, 0.0]])
	return animation


func _walking_animation() -> Animation:
	var animation := _animation(0.8, true)
	_value_track(animation, "motion_offset", [[0.0, Vector2(-8, 0)], [0.4, Vector2(8, -4)], [0.8, Vector2(-8, 0)]])
	_value_track(animation, "motion_rotation", [[0.0, -0.03], [0.4, 0.03], [0.8, -0.03]])
	_value_track(animation, "leg_phase", [[0.0, 0.0], [0.8, 1.0]])
	_value_track(animation, "reaction_strength", [[0.0, 0.0], [0.8, 0.0]])
	return animation


func _harvesting_animation() -> Animation:
	var animation := _animation(0.9, true)
	_value_track(animation, "motion_offset", [[0.0, Vector2.ZERO], [0.45, Vector2(0, 4)], [0.9, Vector2.ZERO]])
	_value_track(animation, "motion_rotation", [[0.0, 0.0], [0.3, 0.14], [0.7, 0.14], [0.9, 0.0]])
	_value_track(animation, "leg_phase", [[0.0, 0.0], [0.9, 0.0]])
	_value_track(animation, "reaction_strength", [[0.0, 0.0], [0.9, 0.0]])
	return animation


func _decision_animation() -> Animation:
	var animation := _animation(1.0, true)
	_value_track(animation, "motion_offset", [[0.0, Vector2.ZERO], [1.0, Vector2.ZERO]])
	_value_track(animation, "motion_rotation", [[0.0, 0.0], [1.0, 0.0]])
	_value_track(animation, "leg_phase", [[0.0, 0.0], [1.0, 0.0]])
	_value_track(animation, "reaction_strength", [[0.0, 0.0], [1.0, 0.0]])
	return animation


func _hazard_reaction_animation() -> Animation:
	var animation := _animation(0.3)
	_value_track(animation, "motion_offset", [[0.0, Vector2.ZERO], [0.06, Vector2(-20, -3)], [0.14, Vector2(9, 2)], [0.22, Vector2(-5, 0)], [0.3, Vector2.ZERO]])
	_value_track(animation, "motion_rotation", [[0.0, 0.0], [0.06, -0.12], [0.14, 0.08], [0.3, 0.0]])
	_value_track(animation, "reaction_strength", [[0.0, 0.0], [0.04, 1.0], [0.3, 0.0]])
	return animation

