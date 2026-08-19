extends SceneTree

var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GOLEM-01 GROUND FAIL: %s" % message)

func run_test() -> void:
	var rig := (load("res://scenes/golem/golem_01_articulation_v0.tscn") as PackedScene).instantiate() as Golem01ArticulationV0
	root.add_child(rig)
	await process_frame
	rig.set_left_hip_rotation(0.0)
	rig.set_left_knee_rotation(0.0)
	var left_contact := rig.left_ground_contact_world()
	var right_contact := rig.right_ground_contact_world()
	check(is_equal_approx(left_contact.y, rig.ground_contact_y()), "left foot reaches ground baseline")
	check(is_equal_approx(right_contact.y, rig.ground_contact_y()), "right foot reaches ground baseline")
	check(is_equal_approx(left_contact.y, right_contact.y), "left/right contact y is identical")
	check(is_equal_approx(left_contact.x, 1094.8), "left contact remains centered under left chain")
	check(is_equal_approx(right_contact.x, 557.2), "right contact remains centered under right chain")
	check(is_equal_approx(rig.left_hip_pivot.rotation, 0.0) and is_equal_approx(rig.left_knee_pivot.rotation, 0.0), "ground pose is neutral standing pose")
	rig.queue_free()
	await process_frame
	if failures.is_empty():
		print("GOLEM-01-DYN-01 GROUND CONTACT: PASS (fixed pelvis, symmetric baseline y=2346.1)")
		quit(0)
	else:
		print("GOLEM-01-DYN-01 GROUND CONTACT: FAIL (%d checks)" % failures.size())
		quit(1)
