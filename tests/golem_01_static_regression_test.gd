extends SceneTree

const PARTS := ["torso", "pelvis", "core", "left_thigh", "right_thigh"]
const EXPECTED_ALPHA := {
	"torso": {"transparent": 957411, "partial": 11800, "opaque": 603305},
	"pelvis": {"transparent": 1099895, "partial": 11521, "opaque": 461100},
	"core": {"transparent": 1200472, "partial": 8470, "opaque": 363574},
	"left_thigh": {"transparent": 1239005, "partial": 9891, "opaque": 323620},
	"right_thigh": {"transparent": 1252804, "partial": 9453, "opaque": 310259},
}

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("run_regression")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GOLEM-01 STATIC FAIL: %s" % message)


func run_regression() -> void:
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Compatibility renderer is active")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile") == "gl_compatibility", "Mobile Compatibility renderer is active")
	var manifest := _read_json("res://assets/source/golem/golem_01/golem_01_chassis_manifest_v1.json")
	for part in PARTS:
		check(manifest.get("current_state", {}).get(part, "") == "STATIC_PART_MASTER_PASS", "%s manifest static pass" % part)
		var metadata := _read_json("res://assets/source/golem/golem_01/parts/%s/%s_source_v1.json" % [part, part])
		check(metadata.get("verdict", "").ends_with("STATIC_PASS"), "%s metadata static verdict" % part)
		var image := Image.new()
		var load_error := image.load("res://assets/source/golem/golem_01/parts/%s/%s_source_v1.png" % [part, part])
		check(load_error == OK and not image.is_empty(), "%s PNG loads under Compatibility project" % part)
		if load_error != OK or image.is_empty():
			continue
		var alpha := _alpha_counts(image)
		check(alpha == EXPECTED_ALPHA[part], "%s alpha counts remain unchanged" % part)
		check(metadata.get("alpha_inspection", {}).get("background_connected_checkerboard_visible", true) == false, "%s has no connected checkerboard" % part)
		check(metadata.get("alpha_inspection", {}).get("structural_hole_count", 0) == 0 or not metadata.get("alpha_inspection", {}).has("structural_hole_count"), "%s audit has no structural holes" % part)
	var assembly := _read_json("res://assets/source/golem/golem_01/golem_01_base_chassis_assembly_v1.json")
	var torso := _read_json("res://assets/source/golem/golem_01/parts/torso/torso_source_v1.json")
	var assembly_nodes: Array = assembly.get("nodes", [])
	var pelvis_node := _find_node(assembly_nodes, "pelvis")
	var torso_node := _find_node(assembly_nodes, "torso")
	check(pelvis_node.get("target_canvas_xy") == torso_node.get("target_canvas_xy"), "TORSO/PELVIS assembly target agrees")
	check(torso.get("occlusion_policy", {}).get("core") == "in_front_of_torso_socket", "CORE/TORSO layer contract remains explicit")
	if failures.is_empty():
		print("GOLEM-01-DYN-01 STATIC REGRESSION: PASS (Compatibility asset recheck)")
		quit(0)
	else:
		print("GOLEM-01-DYN-01 STATIC REGRESSION: FAIL (%d checks)" % failures.size())
		quit(1)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _find_node(nodes: Array, part_id: String) -> Dictionary:
	for node in nodes:
		if node is Dictionary and node.get("part_id") == part_id:
			return node
	return {}


func _alpha_counts(image: Image) -> Dictionary:
	var counts := {"transparent": 0, "partial": 0, "opaque": 0}
	for y in image.get_height():
		for x in image.get_width():
			var alpha := int(round(image.get_pixel(x, y).a * 255.0))
			if alpha == 0:
				counts["transparent"] += 1
			elif alpha == 255:
				counts["opaque"] += 1
			else:
				counts["partial"] += 1
	return counts
