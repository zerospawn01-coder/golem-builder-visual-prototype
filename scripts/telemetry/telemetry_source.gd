class_name TelemetrySource
extends Node

signal telemetry_received(payload: Dictionary)
signal playback_finished


func start() -> void:
	push_error("TelemetrySource.start() must be implemented")

