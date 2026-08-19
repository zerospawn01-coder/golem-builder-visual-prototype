extends SceneTree

var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GOLEM-01 KNEE FAIL: %s" % message)

func run_test() -> void:
	var rig := (load("res://scenes/golem/golem_01_articulation_v0.tscn") as PackedScene).instantiate() as Golem01ArticulationV0
	root.add_child(rig)
	await process_frame
	check(rig.left_knee_pivot.position.is_equal_approx(rig.left_knee_position()), "neutral knee attaches at thigh endpoint")
	check(rig.right_knee_pivot.position.is_equal_approx(rig.right_knee_position()), "right knee uses its production attachment")
	check(rig.left_knee_pivot.get_parent() == rig.left_hip_pivot, "knee pivot is parallel to thigh sprite")
	for angle in [0.0, deg_to_rad(-30.0), deg_to_rad(-90.0)]:
		rig.set_left_knee_rotation(angle)
		check(is_equal_approx(rig.left_knee_pivot.rotation, angle), "left knee accepts exploration bend")
		check(is_equal_approx(rig.right_knee_pivot.rotation, -angle), "right knee mirrors bend sign")
		check(rig.left_knee_pivot.get_node("LeftLowerLegPlaceholder") != null, "left lower leg placeholder exists")
	rig.set_left_hip_rotation(deg_to_rad(45.0))
	rig.set_left_knee_rotation(deg_to_rad(-90.0))
	check(is_equal_approx(rig.left_hip_pivot.rotation, deg_to_rad(45.0)), "composite hip angle retained")
	check(is_equal_approx(rig.left_knee_pivot.rotation, deg_to_rad(-90.0)), "composite knee angle retained")
	check(rig.left_knee_pivot.get_parent() == rig.left_hip_pivot, "composite chain remains node-to-node")
	rig.queue_free()
	await process_frame
	if failures.is_empty():
		print("GOLEM-01-DYN-01 KNEE: PASS (placeholder, partial -30 / deep -90)")
		quit(0)
	else:
		print("GOLEM-01-DYN-01 KNEE: FAIL (%d checks)" % failures.size())
		quit(1)
