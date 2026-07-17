class_name RecipeData
extends Resource

@export var recipe_id: StringName
@export var recipe_name: String
@export var icon: Texture2D
@export var ingredient_ids: Array[StringName] = []
@export var ingredient_amounts: Array[int] = []
@export var result_item_id: StringName
@export var result_amount: int = 1
@export var cooking_time: float = 1.5
