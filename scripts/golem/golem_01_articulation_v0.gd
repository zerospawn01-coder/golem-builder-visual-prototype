class_name Golem01ArticulationV0
extends Node2D

const PELVIS_SOCKET_LEFT := Vector2(1010.0, 650.0)
const PELVIS_PIVOT_SOURCE := Vector2(626.0, 327.0)
const ASSEMBLY_TARGET := Vector2(826.0, 1110.0)
const ASSEMBLY_SCALE := 0.70
const LEFT_THIGH_PIVOT := Vector2(612.0, 151.0)

@onready var left_hip_pivot: Node2D = $Pelvis/LeftHipPivot
@onready var left_thigh_sprite: Sprite2D = $Pelvis/LeftHipPivot/LeftThighSprite


func _ready() -> void:
	$Pelvis/PelvisSprite.texture = _load_texture("res://assets/source/golem/golem_01/parts/pelvis/pelvis_source_v1.png")
	left_thigh_sprite.texture = _load_texture("res://assets/source/golem/golem_01/parts/left_thigh/left_thigh_source_v1.png")
	left_hip_pivot.rotation = 0.0
	left_thigh_sprite.rotation = 0.0


func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func set_left_hip_rotation(angle: float) -> void:
	left_hip_pivot.rotation = angle
	left_thigh_sprite.rotation = 0.0


func left_hip_position() -> Vector2:
	return ASSEMBLY_TARGET + (PELVIS_SOCKET_LEFT - PELVIS_PIVOT_SOURCE) * ASSEMBLY_SCALE


func left_thigh_sprite_offset() -> Vector2:
	return -LEFT_THIGH_PIVOT
