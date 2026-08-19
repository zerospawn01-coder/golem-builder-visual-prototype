class_name NorthStarPresentationState
extends RefCounted

const SCREENS := [&"WORKSHOP", &"BLUEPRINT", &"FABRICATION_CONFIRMED", &"EXPEDITION", &"RESULT"]

var _sealed := false
var _sequence := 0
var _screen := &"WORKSHOP"
var _workshop: Dictionary = {}
var _blueprint: Dictionary = {}
var _fabrication: Dictionary = {}
var _result: Dictionary = {}

var sequence: int:
	get: return _sequence
	set(value):
		if not _sealed: _sequence = value
var screen: StringName:
	get: return _screen
	set(value):
		if not _sealed: _screen = value
var workshop: Dictionary:
	get: return _workshop
	set(value):
		if not _sealed: _workshop = value
var blueprint: Dictionary:
	get: return _blueprint
	set(value):
		if not _sealed: _blueprint = value
var fabrication: Dictionary:
	get: return _fabrication
	set(value):
		if not _sealed: _fabrication = value
var result: Dictionary:
	get: return _result
	set(value):
		if not _sealed: _result = value


static func from_host_snapshot(payload: Dictionary) -> RefCounted:
	if not _is_valid(payload):
		return null
	var state := new()
	state.sequence = payload["sequence"]
	state.screen = StringName(payload["screen"])
	state.workshop = ImmutableSnapshot.freeze(payload.get("workshop", {}))
	state.blueprint = ImmutableSnapshot.freeze(payload.get("blueprint", {}))
	state.fabrication = ImmutableSnapshot.freeze(payload.get("fabrication", {}))
	state.result = ImmutableSnapshot.freeze(payload.get("result", {}))
	state._sealed = true
	return state


static func _is_valid(payload: Dictionary) -> bool:
	if typeof(payload.get("sequence")) != TYPE_INT or payload["sequence"] < 0:
		return false
	if typeof(payload.get("screen")) != TYPE_STRING or StringName(payload["screen"]) not in SCREENS:
		return false
	for key in ["workshop", "blueprint", "fabrication", "result"]:
		if payload.has(key) and typeof(payload[key]) != TYPE_DICTIONARY:
			return false
	return true
