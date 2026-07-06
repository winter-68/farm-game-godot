class_name ItemData extends Resource

enum Type { SEED, PRODUCE, TOOL, MISC }

@export var item_id: StringName
@export var display_name: String
@export var type: Type
@export var icon: Texture2D
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var stackable: bool = true
@export var max_stack: int = 99
@export var linked_crop_id: StringName
