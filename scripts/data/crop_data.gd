class_name CropData extends Resource

@export var crop_id: StringName
@export var display_name: String
@export var produce_item_id: StringName
@export var days_per_stage: int = 1
@export var stage_textures: Array[Texture2D]
@export var placeholder_color: Color = Color(0.25, 0.85, 0.3, 1.0)
@export var regrows: bool = false
@export var regrow_to_stage: int = 0
@export var produce_amount: int = 1
## Empty means all seasons; otherwise crop can only be planted in listed seasons.
@export var allowed_seasons: Array[String] = []


## Returns the index of the final growth stage.
func mature_stage() -> int:
	return stage_textures.size() - 1
