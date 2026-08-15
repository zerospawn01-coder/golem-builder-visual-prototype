extends SceneTree

var state_updates := 0
var event_batches := 0
var latest_state: PresentationState
var latest_batch: TransientEventBatch


func _init() -> void:
	var presenter := ExpeditionPresenter.new()
	presenter.presentation_state_changed.connect(_capture_state)
	presenter.transient_events_emitted.connect(_capture_events)

	var payload := {
		"sequence": 10,
		"status": "WALKING",
		"depth": 3,
		"durability": 73,
		"cargo": 4,
		"cargo_capacity": 8,
		"hazards": [],
		"log_events": [{"type": "CARGO_SECURED", "message": "Cargo secured while walking."}],
		"decision_state": "NONE",
	}
	assert(presenter.accept(payload))
	assert(state_updates == 1)
	assert(event_batches == 1)
	assert(latest_state.golem_state["status"] == "WALKING")
	assert(latest_state.telemetry_state["durability"] == 73)
	assert(latest_state.telemetry_state["cargo"] == 4)
	assert(latest_batch.events[0]["type"] == "CARGO_SECURED")
	assert(not _has_property(latest_state, "transient_events"), "persistent state must not own transient events")
	assert(ImmutableSnapshot.is_deeply_read_only(latest_state.golem_state))
	assert(ImmutableSnapshot.is_deeply_read_only(latest_state.environment_state))
	assert(ImmutableSnapshot.is_deeply_read_only(latest_state.warning_state))
	assert(ImmutableSnapshot.is_deeply_read_only(latest_state.telemetry_state))
	assert(ImmutableSnapshot.is_deeply_read_only(latest_batch.events))

	var presenter_state := presenter.current_state()
	presenter_state.telemetry_state = {"durability": 0}
	presenter_state.warning_state = {"active": true, "hazards": [{"type": "INJECTED"}]}
	presenter_state.sequence = -1
	assert(presenter.current_state().telemetry_state["durability"] == 73, "consumer cannot replace telemetry state")
	assert(presenter.current_state().warning_state["active"] == false, "expected original warning state")
	assert(presenter.current_state().sequence == 10, "consumer cannot replace sequence")

	var parsed := ExpeditionTelemetry.from_dictionary(payload)
	var same_input_a := PresentationState.from_telemetry(parsed)
	var same_input_b := PresentationState.from_telemetry(parsed)
	assert(_state_values(same_input_a) == _state_values(same_input_b), "mapping must be deterministic")

	var stale := payload.duplicate(true)
	stale["sequence"] = 9
	stale["status"] = "HAZARD"
	assert(not presenter.accept(stale))
	assert(state_updates == 1, "stale telemetry must not mutate persistent state")
	assert(event_batches == 1, "stale telemetry must not emit transient events")

	var retained_state := presenter.current_state()
	assert(presenter.replay_current_state(), "retained persistent state must be replayable")
	assert(state_updates == 2, "view rebinding receives persistent state")
	assert(event_batches == 1, "view rebinding must not replay transient events")
	assert(latest_state == retained_state, "view rebinding must reuse state without recalculation")

	var scene_source := FileAccess.get_file_as_string("res://scripts/expedition/expedition_scene.gd")
	var view_source := FileAccess.get_file_as_string("res://scripts/views/golem_view.gd")
	assert(not scene_source.contains("ExpeditionTelemetry"), "scene must not reference telemetry contract")
	assert(not view_source.contains("ExpeditionTelemetry"), "views must not reference telemetry contract")

	presenter.free()
	print("V1-PRESENTATION-STATE: PASS")
	quit(0)


func _capture_state(state: PresentationState) -> void:
	state_updates += 1
	latest_state = state


func _capture_events(batch: TransientEventBatch) -> void:
	event_batches += 1
	latest_batch = batch


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property["name"] == property_name:
			return true
	return false


func _state_values(state: PresentationState) -> Dictionary:
	return {
		"sequence": state.sequence,
		"golem_state": state.golem_state,
		"environment_state": state.environment_state,
		"warning_state": state.warning_state,
		"telemetry_state": state.telemetry_state,
		"decision_state": state.decision_state,
	}
