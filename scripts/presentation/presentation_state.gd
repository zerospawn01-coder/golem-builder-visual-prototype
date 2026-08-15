class_name PresentationState
extends RefCounted

var sequence: int
var golem_state: Dictionary
var environment_state: Dictionary
var warning_state: Dictionary
var telemetry_state: Dictionary
var decision_state: String


static func from_telemetry(telemetry: ExpeditionTelemetry) -> PresentationState:
	var state := PresentationState.new()
	state.sequence = telemetry.sequence
	state.golem_state = {"status": telemetry.status}
	state.environment_state = {"hazards": telemetry.hazards.duplicate(true)}
	state.warning_state = {
		"active": not telemetry.hazards.is_empty(),
		"hazards": telemetry.hazards.duplicate(true),
	}
	state.telemetry_state = {
		"depth": telemetry.depth,
		"durability": telemetry.durability,
		"cargo": telemetry.cargo,
		"cargo_capacity": telemetry.cargo_capacity,
	}
	state.decision_state = telemetry.decision_state
	return state

