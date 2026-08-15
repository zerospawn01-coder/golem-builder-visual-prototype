class_name ExpeditionPresenter
extends Node

signal presentation_state_changed(state: PresentationState)
signal transient_events_emitted(batch: TransientEventBatch)
signal telemetry_rejected(sequence: int, reason: String)

var _last_sequence := -1
var _current_state: PresentationState


func accept(payload: Dictionary) -> bool:
	var telemetry := ExpeditionTelemetry.from_dictionary(payload)
	if telemetry == null:
		telemetry_rejected.emit(payload.get("sequence", -1), "invalid payload")
		return false
	if telemetry.sequence <= _last_sequence:
		telemetry_rejected.emit(telemetry.sequence, "stale sequence")
		return false
	_last_sequence = telemetry.sequence
	_current_state = PresentationState.from_telemetry(telemetry)
	presentation_state_changed.emit(_current_state)
	if not telemetry.log_events.is_empty():
		transient_events_emitted.emit(TransientEventBatch.from_telemetry(telemetry))
	return true


func current_state() -> PresentationState:
	return _current_state


func replay_current_state() -> bool:
	if _current_state == null:
		return false
	presentation_state_changed.emit(_current_state)
	return true
