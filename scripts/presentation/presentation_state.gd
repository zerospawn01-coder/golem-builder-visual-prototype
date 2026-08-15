class_name PresentationState
extends RefCounted

var _sealed := false
var _sequence: int
var _golem_state: Dictionary
var _environment_state: Dictionary
var _warning_state: Dictionary
var _telemetry_state: Dictionary
var _decision_state: String

var sequence: int:
	get: return _sequence
	set(value):
		if not _sealed: _sequence = value
var golem_state: Dictionary:
	get: return _golem_state
	set(value):
		if not _sealed: _golem_state = value
var environment_state: Dictionary:
	get: return _environment_state
	set(value):
		if not _sealed: _environment_state = value
var warning_state: Dictionary:
	get: return _warning_state
	set(value):
		if not _sealed: _warning_state = value
var telemetry_state: Dictionary:
	get: return _telemetry_state
	set(value):
		if not _sealed: _telemetry_state = value
var decision_state: String:
	get: return _decision_state
	set(value):
		if not _sealed: _decision_state = value


static func from_telemetry(telemetry: ExpeditionTelemetry) -> PresentationState:
	var state := PresentationState.new()
	state.sequence = telemetry.sequence
	state.golem_state = ImmutableSnapshot.freeze({"status": telemetry.status})
	state.environment_state = ImmutableSnapshot.freeze({"hazards": telemetry.hazards})
	state.warning_state = ImmutableSnapshot.freeze({
		"active": not telemetry.hazards.is_empty(),
		"hazards": telemetry.hazards,
	})
	state.telemetry_state = ImmutableSnapshot.freeze({
		"depth": telemetry.depth,
		"durability": telemetry.durability,
		"cargo": telemetry.cargo,
		"cargo_capacity": telemetry.cargo_capacity,
	})
	state.decision_state = telemetry.decision_state
	state._sealed = true
	return state
