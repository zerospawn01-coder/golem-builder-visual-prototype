class_name ExpeditionPresenter
extends Node

signal telemetry_presented(telemetry: ExpeditionTelemetry)
signal telemetry_rejected(sequence: int, reason: String)

var _last_sequence := -1


func accept(payload: Dictionary) -> bool:
	var telemetry := ExpeditionTelemetry.from_dictionary(payload)
	if telemetry == null:
		telemetry_rejected.emit(payload.get("sequence", -1), "invalid payload")
		return false
	if telemetry.sequence <= _last_sequence:
		telemetry_rejected.emit(telemetry.sequence, "stale sequence")
		return false
	_last_sequence = telemetry.sequence
	telemetry_presented.emit(telemetry)
	return true

