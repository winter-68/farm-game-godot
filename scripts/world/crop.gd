extends Node2D

const ArtDefaults := preload("res://scripts/art/art_defaults.gd")

@onready var sprite: Sprite2D = $Sprite2D


## Displays a crop stage, falling back to a scaled green placeholder.
func show_stage(crop_data: CropData, stage: int) -> void:
	sprite.texture = ArtDefaults.crop_stage_texture(crop_data, stage)
	sprite.modulate = Color.WHITE
	var stage_scale := maxf(0.4 + 0.3 * stage, 0.1)
	sprite.scale = Vector2.ONE * stage_scale
