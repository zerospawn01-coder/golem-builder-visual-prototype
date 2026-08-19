extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("run_test")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GOLEM-01 HIP FAIL: %s" % message)


func run_test() -> void:
	var packed := load("res://scenes/golem/golem_01_articulation_v0.tscn") as PackedScene
	check(packed != null, "articulation scene loads")
	if packed == null:
		quit(1)
		return
	var rig := packed.instantiate() as Golem01ArticulationV0
	root.add_child(rig)
	await process_frame
	check(rig.left_hip_pivot.rotation == 0.0, "neutral HipPivot rotation is zero")
	check(rig.left_thigh_sprite.rotation == 0.0, "Sprite rotation remains zero")
	check(rig.get_node("Pelvis/PelvisSprite").texture != null, "pelvis texture resolves at runtime")
	check(rig.left_thigh_sprite.texture != null, "thigh texture resolves at runtime")
	check(rig.left_hip_pivot.position.is_equal_approx(rig.left_hip_position()), "LeftHipPivot uses pelvis socket position")
	check(rig.left_thigh_sprite.offset.is_equal_approx(rig.left_thigh_sprite_offset()), "thigh attachment uses Sprite offset")
	check(rig.left_thigh_sprite.scale.is_equal_approx(Vector2.ONE * 0.7), "thigh scale matches pelvis assembly")
	rig.queue_free()
	await process_frame
	if failures.is_empty():
		print("GOLEM-01-DYN-01 HIP NEUTRAL: PASS")
		quit(0)
	else:
		print("GOLEM-01-DYN-01 HIP NEUTRAL: FAIL (%d checks)" % failures.size())
		quit(1)
