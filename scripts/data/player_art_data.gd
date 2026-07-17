class_name PlayerArtData
extends Resource

@export_group("Stand")
@export var stand_down: Texture2D
@export var stand_up: Texture2D
@export var stand_left: Texture2D
@export var stand_right: Texture2D

@export_group("Walk")
@export var walk_down: Array[Texture2D] = []
@export var walk_up: Array[Texture2D] = []
@export var walk_left: Array[Texture2D] = []
@export var walk_right: Array[Texture2D] = []

@export_group("Preview")
@export var placeholder_color: Color = Color(0.337, 0.769, 0.451, 1.0)
@export var frame_time: float = 0.18


func get_stand_texture(facing: Vector2i) -> Texture2D:
	if facing == Vector2i.UP:
		return stand_up
	if facing == Vector2i.LEFT:
		return stand_left
	if facing == Vector2i.RIGHT:
		return stand_right
	return stand_down


func get_walk_frames(facing: Vector2i) -> Array[Texture2D]:
	if facing == Vector2i.UP:
		return walk_up
	if facing == Vector2i.LEFT:
		return walk_left
	if facing == Vector2i.RIGHT:
		return walk_right
	return walk_down
