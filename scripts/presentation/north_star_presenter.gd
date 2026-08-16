class_name NorthStarPresenter
extends Node

const NorthStarState = preload("res://scripts/presentation/north_star_presentation_state.gd")

signal presentation_state_changed(state)
signal snapshot_rejected(sequence: int, reason: String)

var _last_sequence := -1
var _current_state: RefCounted


func accept_host_snapshot(payload: Dictionary) -> bool:
	var state: RefCounted = NorthStarState.from_host_snapshot(payload)
	if state == null:
		snapshot_rejected.emit(payload.get("sequence", -1), "invalid host snapshot")
		return false
	if state.sequence <= _last_sequence:
		snapshot_rejected.emit(state.sequence, "stale sequence")
		return false
	_last_sequence = state.sequence
	_current_state = state
	presentation_state_changed.emit(_current_state)
	return true


func current_state() -> RefCounted:
	return _current_state


func replay_current_state() -> bool:
	if _current_state == null:
		return false
	presentation_state_changed.emit(_current_state)
	return true
