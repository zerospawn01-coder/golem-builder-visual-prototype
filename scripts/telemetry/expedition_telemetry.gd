class_name ExpeditionTelemetry
extends RefCounted

const VALID_STATUSES := {
	"IDLE": true,
	"WALKING": true,
	"HARVESTING": true,
	"HAZARD": true,
	"DECISION": true,
}

var sequence: int
var status: String
var depth: int
var durability: int
var cargo: int
var cargo_capacity: int
var hazards: Array[Dictionary]
var log_events: Array[Dictionary]
var decision_state: String


static func from_dictionary(payload: Dictionary) -> ExpeditionTelemetry:
	var errors := validate(payload)
	if not errors.is_empty():
		push_error("Invalid expedition telemetry: %s" % "; ".join(errors))
		return null

	var telemetry := ExpeditionTelemetry.new()
	telemetry.sequence = payload["sequence"]
	telemetry.status = payload["status"]
	telemetry.depth = payload["depth"]
	telemetry.durability = payload["durability"]
	telemetry.cargo = payload["cargo"]
	telemetry.cargo_capacity = payload["cargo_capacity"]
	telemetry.hazards = _dictionary_array(payload.get("hazards", []))
	telemetry.log_events = _dictionary_array(payload.get("log_events", []))
	telemetry.decision_state = payload.get("decision_state", "NONE")
	return telemetry


static func validate(payload: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for field in ["sequence", "status", "depth", "durability", "cargo", "cargo_capacity"]:
		if not payload.has(field):
			errors.append("missing %s" % field)
	if not errors.is_empty():
		return errors

	for field in ["sequence", "depth", "durability", "cargo", "cargo_capacity"]:
		if not payload[field] is int:
			errors.append("%s must be int" % field)
	if not payload["status"] is String or not VALID_STATUSES.has(payload["status"]):
		errors.append("unsupported status")
	if payload["sequence"] < 0:
		errors.append("sequence must be non-negative")
	if payload["durability"] < 0 or payload["durability"] > 100:
		errors.append("durability must be 0..100")
	if payload["cargo_capacity"] < 0 or payload["cargo"] < 0 or payload["cargo"] > payload["cargo_capacity"]:
		errors.append("cargo must be within capacity")
	if not payload.get("hazards", []) is Array:
		errors.append("hazards must be Array")
	if not payload.get("log_events", []) is Array:
		errors.append("log_events must be Array")
	return errors


static func _dictionary_array(value: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in value:
		if item is Dictionary:
			result.append(item)
	return result

