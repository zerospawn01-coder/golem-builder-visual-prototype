class_name TransientEventBatch
extends RefCounted

var sequence: int
var events: Array[Dictionary]


static func from_telemetry(telemetry: ExpeditionTelemetry) -> TransientEventBatch:
	var batch := TransientEventBatch.new()
	batch.sequence = telemetry.sequence
	batch.events = telemetry.log_events.duplicate(true)
	return batch

