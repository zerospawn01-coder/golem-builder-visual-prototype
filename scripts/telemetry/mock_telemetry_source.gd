class_name MockTelemetrySource
extends TelemetrySource

@export_range(0.1, 10.0, 0.1) var interval_seconds := 1.5

var _cursor := 0
var _frames: Array[Dictionary] = [
	{"sequence": 1, "status": "IDLE", "depth": 0, "durability": 100, "cargo": 0, "cargo_capacity": 8, "hazards": [], "log_events": [{"type": "SYSTEM", "message": "Expedition link established."}], "decision_state": "NONE"},
	{"sequence": 2, "status": "WALKING", "depth": 1, "durability": 96, "cargo": 0, "cargo_capacity": 8, "hazards": [], "log_events": [{"type": "INFO", "message": "Descent in progress."}], "decision_state": "NONE"},
	{"sequence": 3, "status": "HARVESTING", "depth": 2, "durability": 91, "cargo": 4, "cargo_capacity": 8, "hazards": [], "log_events": [{"type": "CARGO_SECURED", "message": "Mineral sample secured."}], "decision_state": "NONE"},
	{"sequence": 4, "status": "HAZARD", "depth": 2, "durability": 73, "cargo": 4, "cargo_capacity": 8, "hazards": [{"type": "MASS_LOAD", "severity": 2}], "log_events": [{"type": "WARNING", "message": "Excessive mass load detected."}], "decision_state": "NONE"},
	{"sequence": 3, "status": "WALKING", "depth": 1, "durability": 91, "cargo": 4, "cargo_capacity": 8, "hazards": [], "log_events": [{"type": "CARGO_SECURED", "message": "Delayed cargo event must not rewind presentation."}], "decision_state": "NONE"},
	{"sequence": 5, "status": "DECISION", "depth": 2, "durability": 73, "cargo": 4, "cargo_capacity": 8, "hazards": [], "log_events": [{"type": "SYSTEM", "message": "Operator decision required."}], "decision_state": "CONTINUE_RETURN"},
]


func start() -> void:
	_cursor = 0
	_emit_next()


func _emit_next() -> void:
	if _cursor >= _frames.size():
		playback_finished.emit()
		return
	telemetry_received.emit(_frames[_cursor].duplicate(true))
	_cursor += 1
	if _cursor < _frames.size():
		get_tree().create_timer(interval_seconds).timeout.connect(_emit_next)
	else:
		playback_finished.emit()
