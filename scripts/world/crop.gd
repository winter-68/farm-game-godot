extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var _placeholder_texture: Texture2D


func _ready() -> void:
	_placeholder_texture = sprite.texture


## Displays a crop stage, falling back to a scaled green placeholder.
func show_stage(crop_data: CropData, stage: int) -> void:
	var stage_texture: Texture2D
	if stage >= 0 and stage < crop_data.stage_textures.size():
		stage_texture = crop_data.stage_textures[stage]
	if stage_texture != null:
		sprite.texture = stage_texture
		sprite.modulate = Color.WHITE
	else:
		sprite.texture = _placeholder_texture
		sprite.modulate = Color(0.25, 0.85, 0.3, 1.0)
	var stage_scale := maxf(0.4 + 0.3 * stage, 0.1)
	sprite.scale = Vector2.ONE * stage_scale
