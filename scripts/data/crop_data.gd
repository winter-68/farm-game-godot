class_name CropData extends Resource

@export var crop_id: StringName
@export var display_name: String
@export var produce_item_id: StringName
@export var days_per_stage: int = 1
@export var stage_textures: Array[Texture2D]
@export var regrows: bool = false
@export var regrow_to_stage: int = 0
@export var produce_amount: int = 1


## Returns the index of the final growth stage.
func mature_stage() -> int:
	return stage_textures.size() - 1
