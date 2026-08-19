class_name Golem01AssemblyV0
extends Node2D

@onready var lower_body_rig: Golem01ArticulationV0 = $LowerBodyRig

func _ready() -> void:
	$UpperBody/PelvisSprite.texture = _load_texture("res://assets/source/golem/golem_01/parts/pelvis/pelvis_source_v1.png")
	$UpperBody/TorsoSprite.texture = _load_texture("res://assets/source/golem/golem_01/parts/torso/torso_source_v1.png")
	$UpperBody/CoreSprite.texture = _load_texture("res://assets/source/golem/golem_01/parts/core/core_source_v1.png")
	lower_body_rig.get_node("Pelvis/PelvisSprite").visible = false

func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
