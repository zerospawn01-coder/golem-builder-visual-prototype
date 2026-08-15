extends SceneTree


func _init() -> void:
	var valid := {"sequence": 4, "status": "HAZARD", "depth": 2, "durability": 73, "cargo": 4, "cargo_capacity": 8, "hazards": [], "log_events": [], "decision_state": "NONE"}
	assert(ExpeditionTelemetry.validate(valid).is_empty())
	var invalid := valid.duplicate(true)
	invalid["cargo"] = 9
	assert(not ExpeditionTelemetry.validate(invalid).is_empty())
	var presenter := ExpeditionPresenter.new()
	assert(presenter.accept(valid))
	assert(not presenter.accept(valid), "duplicate sequence must be rejected")
	presenter.free()
	print("telemetry_contract_test: PASS")
	quit()
