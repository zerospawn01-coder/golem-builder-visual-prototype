extends SceneTree

var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GOLEM-01 ASSEMBLY SOCKET FAIL: %s" % message)

func run_test() -> void:
	var text := FileAccess.get_file_as_string("res://assets/source/golem/golem_01/golem_01_base_chassis_assembly_v1.json")
	var data = JSON.parse_string(text)
	check(data != null, "assembly manifest parses")
	if data == null:
		quit(1)
		return
	var socket: Dictionary = data.get("pelvis_lower_attachment", {})
	var position: Array = socket.get("position", [])
	var relative: Array = socket.get("relative_to_pelvis_pivot", [])
	check(position.size() == 2 and is_equal_approx(float(position[0]), 826.0) and is_equal_approx(float(position[1]), 1553.1), "socket uses assembly absolute position")
	check(relative.size() == 2 and is_equal_approx(float(relative[0]), 0.0) and is_equal_approx(float(relative[1]), 443.1), "socket relative offset is explicit")
	check(is_equal_approx(float(socket.get("scale_ref", 0.0)), 0.70), "socket scale reference matches pelvis/thigh")
	check(socket.get("coordinate_space", "") == "assembly_canvas", "socket coordinate space is explicit")
	if failures.is_empty():
		print("GOLEM-01-ASSEMBLY SOCKET: PASS (assembly canvas [826,1553.1], scale 0.70)")
		quit(0)
	else:
		print("GOLEM-01-ASSEMBLY SOCKET: FAIL (%d checks)" % failures.size())
		quit(1)
