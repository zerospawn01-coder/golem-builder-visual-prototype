class_name MockNorthStarHost
extends Node

signal snapshot_received(payload: Dictionary)

var _sequence := 0
var _saved_blueprints: Array[Dictionary] = []


func show_workshop() -> void:
	_emit(&"WORKSHOP", {"station": "FOUNDRY-01", "available_designs": 3}, {"saved_blueprints": _saved_blueprints.duplicate(true)})


func show_blueprint() -> void:
	_emit(&"BLUEPRINT", {}, {"selected_design": "QUARRY SCOUT", "saved_blueprints": _saved_blueprints.duplicate(true)})


func confirm_fabrication() -> void:
	if _saved_blueprints.is_empty():
		_saved_blueprints.append({"id": "BP-QS-01", "label": "QUARRY SCOUT"})
	_emit(&"FABRICATION_CONFIRMED", {}, {"selected_design": "QUARRY SCOUT", "saved_blueprints": _saved_blueprints.duplicate(true)}, {"unit_label": "GOLEM QS-01", "source": "BLUEPRINT_DIRECT"})


func show_expedition() -> void:
	_emit(&"EXPEDITION")


func show_result() -> void:
	_emit(&"RESULT", {}, {"selected_design": "QUARRY SCOUT", "saved_blueprints": _saved_blueprints.duplicate(true)}, {}, {"outcome": "RETURNED", "cargo": "4 / 8", "durability": "73%"})


func _emit(screen: StringName, workshop := {}, blueprint := {}, fabrication := {}, result := {}) -> void:
	_sequence += 1
	snapshot_received.emit({
		"sequence": _sequence,
		"screen": String(screen),
		"workshop": workshop,
		"blueprint": blueprint,
		"fabrication": fabrication,
		"result": result,
	})
