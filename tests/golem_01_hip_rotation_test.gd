extends SceneTree

var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GOLEM-01 HIP ROTATION FAIL: %s" % message)

func run_test() -> void:
	var packed := load("res://scenes/golem/golem_01_articulation_v0.tscn") as PackedScene
	check(packed != null, "articulation scene loads")
	if packed == null:
		quit(1)
		return
	var rig := packed.instantiate() as Golem01ArticulationV0
	root.add_child(rig)
	await process_frame
	check(rig.left_hip_pivot.position.is_equal_approx(rig.left_hip_position()), "left pelvis socket position stable")
	check(rig.right_hip_pivot.position.is_equal_approx(rig.right_hip_position()), "right pelvis socket mirrors left")
	check(rig.left_thigh_sprite.z_index == rig.right_thigh_sprite.z_index, "thigh draw order is symmetric")
	for angle in [deg_to_rad(45.0), deg_to_rad(-20.0)]:
		rig.set_left_hip_rotation(angle)
		check(is_equal_approx(rig.left_hip_pivot.rotation, angle), "left pivot accepts exploration angle")
		check(is_equal_approx(rig.right_hip_pivot.rotation, -angle), "right pivot mirrors rotation sign")
		check(is_zero_approx(rig.left_thigh_sprite.rotation) and is_zero_approx(rig.right_thigh_sprite.rotation), "sprites remain unrotated")
		check(rig.left_thigh_sprite.texture != null and rig.right_thigh_sprite.texture != null, "thigh textures remain resolved")
	rig.queue_free()
	await process_frame
	if failures.is_empty():
		print("GOLEM-01-DYN-01 HIP FORWARD/BACK: PASS (exploration bounds 45/-20 degrees)")
		quit(0)
	else:
		print("GOLEM-01-DYN-01 HIP FORWARD/BACK: FAIL (%d checks)" % failures.size())
		quit(1)
