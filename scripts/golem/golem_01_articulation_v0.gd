class_name Golem01ArticulationV0
extends Node2D

const PELVIS_SOCKET_LEFT := Vector2(1010.0, 650.0)
const PELVIS_SOCKET_RIGHT := Vector2(241.0, 650.0)
const PELVIS_PIVOT_SOURCE := Vector2(626.0, 327.0)
const ASSEMBLY_TARGET := Vector2(826.0, 1110.0)
const ASSEMBLY_SCALE := 0.70
const LEFT_THIGH_PIVOT := Vector2(612.0, 151.0)
const RIGHT_THIGH_PIVOT := Vector2(622.0, 184.0)
const LEFT_KNEE_SOURCE := Vector2(579.0, 1056.0)
const RIGHT_KNEE_SOURCE := Vector2(758.0, 966.0)
const LEFT_LOWER_LEG_LENGTH := 360.0
const RIGHT_LOWER_LEG_LENGTH := 446.1

@onready var left_hip_pivot: Node2D = $Pelvis/LeftHipPivot
@onready var left_thigh_sprite: Sprite2D = $Pelvis/LeftHipPivot/LeftThighSprite
@onready var right_hip_pivot: Node2D = $Pelvis/RightHipPivot
@onready var right_thigh_sprite: Sprite2D = $Pelvis/RightHipPivot/RightThighSprite
@onready var left_knee_pivot: Node2D = $Pelvis/LeftHipPivot/LeftKneePivot
@onready var right_knee_pivot: Node2D = $Pelvis/RightHipPivot/RightKneePivot


func _ready() -> void:
	$Pelvis/PelvisSprite.texture = _load_texture("res://assets/source/golem/golem_01/parts/pelvis/pelvis_source_v1.png")
	left_thigh_sprite.texture = _load_texture("res://assets/source/golem/golem_01/parts/left_thigh/left_thigh_source_v1.png")
	right_thigh_sprite.texture = _load_texture("res://assets/source/golem/golem_01/parts/right_thigh/right_thigh_source_v1.png")
	left_hip_pivot.rotation = 0.0
	left_thigh_sprite.rotation = 0.0
	right_hip_pivot.rotation = 0.0
	right_thigh_sprite.rotation = 0.0
	left_knee_pivot.rotation = 0.0
	right_knee_pivot.rotation = 0.0


func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func set_left_hip_rotation(angle: float) -> void:
	left_hip_pivot.rotation = angle
	left_thigh_sprite.rotation = 0.0
	right_hip_pivot.rotation = -angle
	right_thigh_sprite.rotation = 0.0
	right_knee_pivot.rotation = -left_knee_pivot.rotation


func set_left_knee_rotation(angle: float) -> void:
	left_knee_pivot.rotation = angle
	right_knee_pivot.rotation = -angle


func left_hip_position() -> Vector2:
	return ASSEMBLY_TARGET + (PELVIS_SOCKET_LEFT - PELVIS_PIVOT_SOURCE) * ASSEMBLY_SCALE


func left_thigh_sprite_offset() -> Vector2:
	return -LEFT_THIGH_PIVOT


func right_hip_position() -> Vector2:
	return ASSEMBLY_TARGET + (PELVIS_SOCKET_RIGHT - PELVIS_PIVOT_SOURCE) * ASSEMBLY_SCALE


func right_thigh_sprite_offset() -> Vector2:
	return -RIGHT_THIGH_PIVOT


func left_knee_position() -> Vector2:
	return (LEFT_KNEE_SOURCE - LEFT_THIGH_PIVOT) * ASSEMBLY_SCALE


func right_knee_position() -> Vector2:
	return (RIGHT_KNEE_SOURCE - RIGHT_THIGH_PIVOT) * ASSEMBLY_SCALE


func ground_contact_y() -> float:
	return left_hip_position().y + left_knee_position().y + LEFT_LOWER_LEG_LENGTH


func left_ground_contact_world() -> Vector2:
	return left_hip_position() + left_knee_position() + Vector2(0.0, LEFT_LOWER_LEG_LENGTH)


func right_ground_contact_world() -> Vector2:
	return right_hip_position() + right_knee_position() + Vector2(0.0, RIGHT_LOWER_LEG_LENGTH)
