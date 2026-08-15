class_name TransientEventBatch
extends RefCounted

var _sealed := false
var _sequence: int
var _events: Array

var sequence: int:
	get: return _sequence
	set(value):
		if not _sealed: _sequence = value
var events: Array:
	get: return _events
	set(value):
		if not _sealed: _events = value


static func from_telemetry(telemetry: ExpeditionTelemetry) -> TransientEventBatch:
	var batch := TransientEventBatch.new()
	batch.sequence = telemetry.sequence
	batch.events = ImmutableSnapshot.freeze(telemetry.log_events)
	batch._sealed = true
	return batch
